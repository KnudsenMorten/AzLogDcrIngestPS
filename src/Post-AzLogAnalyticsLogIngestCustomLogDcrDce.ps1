function Post-AzLogAnalyticsLogIngestCustomLogDcrDce {
<#
    .SYNOPSIS
    Send data to LogAnalytics using Log Ingestion API and Data Collection Rule.

    .DESCRIPTION
    Posts data to Azure LogAnalytics via the Log Ingestion API. Automatically handles
    batch sizing to stay within the 1 MB payload limit.

    Supports gzip compression and Managed Identity authentication via:
    - Global defaults: $global:EnableCompressionDefault / $global:UseManagedIdentityDefault
    - Per-call parameters: -EnableCompression / -UseManagedIdentity

    Priority: per-call parameter > global default > off.

    .PARAMETER EnableCompression
    Enables gzip compression ($true / $false / $null).
    $null = use $global:EnableCompressionDefault. If global not set, compression is off.

    .PARAMETER UseManagedIdentity
    Uses Managed Identity authentication ($true / $false / $null).
    $null = use $global:UseManagedIdentityDefault. If global not set, managed identity is off.

    .PARAMETER ManagedIdentityClientId
    Client ID of user-assigned managed identity.

    .PARAMETER BatchAmount
    Forces a specific number of records per batch. Overrides automatic 1 MB batch sizing.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DceURI,

        [Parameter(Mandatory)]
        [string]$DcrImmutableId,

        [Parameter(Mandatory)]
        [string]$DcrStream,

        [Parameter(Mandatory)]
        [array]$Data,

        [Parameter(Mandatory)]
        [string]$TableName,

        [string]$BatchAmount,
        [string]$AzAppId,
        [string]$AzAppSecret,
        [string]$TenantId,

        [Nullable[bool]]$EnableCompression = $null,
        [Nullable[bool]]$UseManagedIdentity = $null,
        [string]$ManagedIdentityClientId
    )

    if ($EnableCompression -eq $null) {
        # If the GLOBAL variable is defined, use it for all calls; otherwise OFF
        $EnableCompression = if ($null -ne $global:EnableCompressionDefault) { $global:EnableCompressionDefault } else { $false }
    }

    if ($UseManagedIdentity -eq $null) {
        $UseManagedIdentity = if ($null -ne $global:UseManagedIdentityDefault) { $global:UseManagedIdentityDefault } else { $false }
    }

    if (-not $Data -or @($Data).Count -eq 0) {
        return
    }

    $bearerToken = Get-AzTokenForResource `
        -ResourceUrl 'https://monitor.azure.com/' `
        -AzAppId $AzAppId `
        -AzAppSecret $AzAppSecret `
        -TenantId $TenantId `
        -UseManagedIdentity $UseManagedIdentity `
        -ManagedIdentityClientId $ManagedIdentityClientId

    $headers = @{
        'Authorization' = "Bearer $bearerToken"
    }

    if ($EnableCompression -eq $true) {
        $headers['Content-Encoding'] = 'gzip'
    }

    $maxPayloadBytes = 1MB
    $totalDataLines  = @($Data).Count
    $indexLoopFrom   = 0
    $resultLast      = $null

    # ── Fast path: try sending everything in one shot ───────────────────
    # Serialize the entire array at once (much faster than per-row) and
    # check if it fits. For most tables this succeeds and skips all the
    # per-row cache/cumulative-sum machinery entirely.
    if (-not $BatchAmount) {
        Write-Progress -Activity "Preparing $totalDataLines rows for upload to [ $($TableName)_CL ]" `
                       -Status "Serializing data ..." -PercentComplete 20 -Id 2

        $bulkJson  = ConvertTo-Json -Depth 100 -InputObject @($Data) -Compress
        $bulkBytes = [System.Text.Encoding]::UTF8.GetBytes($bulkJson)

        if ($EnableCompression -eq $true) {
            Write-Progress -Activity "Preparing $totalDataLines rows for upload to [ $($TableName)_CL ]" `
                           -Status "Compressing payload ..." -PercentComplete 60 -Id 2
            $bulkPayload = Compress-GzipBytes -InputBytes $bulkBytes
        } else {
            $bulkPayload = $bulkBytes
        }

        Write-Progress -Activity "Preparing $totalDataLines rows for upload to [ $($TableName)_CL ]" -Id 2 -Completed

        if ($bulkPayload.Length -le $maxPayloadBytes) {
            # Everything fits in one batch — send it directly, no cache needed
            $compressionText = if ($EnableCompression -eq $true) { "Compression=ON" } else { "Compression=OFF" }
            if ($UseManagedIdentity -eq $true) { $authText = "Auth=ManagedIdentity" }
            elseif ($AzAppId -and $AzAppSecret -and $TenantId) { $authText = "Auth=SPN" }
            else { $authText = "Auth=AzContext" }

            $payloadPct = [Math]::Round(($bulkPayload.Length / $maxPayloadBytes) * 100, 1)
            Write-Verbose ("  Batch: {0} rows, payload {1:N0} bytes ({2}% of 1 MB limit) [fast path]" -f $totalDataLines, $bulkPayload.Length, $payloadPct)
            Write-Host ""
            Write-Host "  Posting data to LogAnalytics table [ $($TableName)_CL ]"
            Write-Host "    Rows       : 1..$totalDataLines / $totalDataLines"
            Write-Host "    $compressionText | $authText"
            Write-Host ""

            $uri = "$($DceURI.TrimEnd('/'))/dataCollectionRules/$($DcrImmutableId)/streams/$($DcrStream)?api-version=2021-11-01-preview"
            Write-Verbose ("POST {0} with {1}-byte payload" -f $uri, $bulkPayload.Length)

            try {
                $result = Invoke-WebRequest `
                    -UseBasicParsing `
                    -Uri $uri `
                    -Method Post `
                    -Headers $headers `
                    -ContentType 'application/json; charset=utf-8' `
                    -Body ([byte[]]$bulkPayload) `
                    -ErrorAction Stop

                if ($result.StatusCode -in 200,202,204) {
                    Write-Host "  SUCCESS - data uploaded to LogAnalytics" -ForegroundColor Green
                    return $result
                }
                else {
                    throw "Unexpected status code returned from Log Ingestion API: $($result.StatusCode)"
                }
            }
            catch {
                $responseText = $null
                $statusCode = $null
                if ($_.Exception.Response) {
                    try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
                    try {
                        $stream = $_.Exception.Response.GetResponseStream()
                        if ($stream) {
                            $reader = New-Object System.IO.StreamReader($stream)
                            $responseText = $reader.ReadToEnd()
                            $reader.Dispose()
                        }
                    } catch {}
                }
                throw "Log Ingestion API request failed. HTTP Status: $statusCode Response: $responseText"
            }
        }

        # Bulk didn't fit — fall through to per-row batching
        Write-Verbose "  Bulk payload ($($bulkPayload.Length) bytes) exceeds 1 MB limit — switching to batched upload"
        $bulkJson = $null; $bulkBytes = $null; $bulkPayload = $null  # free memory
    }

    # ── Per-row batching (only reached when data exceeds 1 MB or BatchAmount is set) ──

    $compressionText = if ($EnableCompression -eq $true) { "Compression=ON" } else { "Compression=OFF" }
    if ($UseManagedIdentity -eq $true) { $authText = "Auth=ManagedIdentity" }
    elseif ($AzAppId -and $AzAppSecret -and $TenantId) { $authText = "Auth=SPN" }
    else { $authText = "Auth=AzContext" }

    $uri = "$($DceURI.TrimEnd('/'))/dataCollectionRules/$($DcrImmutableId)/streams/$($DcrStream)?api-version=2021-11-01-preview"

    if ($BatchAmount) {
        # ── Fixed batch size: skip cache, serialize each chunk directly ──
        $fixedBatchSize = [int]$BatchAmount
        if ($fixedBatchSize -lt 1) { throw "BatchAmount must be 1 or higher." }

        $indexLoopFrom = 0
        $resultLast    = $null
        $batchNumber   = 0

        do {
            $batchNumber++
            $indexLoopTo = [Math]::Min(($indexLoopFrom + $fixedBatchSize - 1), ($totalDataLines - 1))
            $batchRowCount = $indexLoopTo - $indexLoopFrom + 1

            $pctDone = [Math]::Round((($indexLoopTo + 1) / $totalDataLines) * 100)
            Write-Progress -Activity "Uploading to LogAnalytics table [ $($TableName)_CL ]" `
                           -Status "Sending batch $batchNumber (rows $($indexLoopFrom + 1)..$($indexLoopTo + 1) of $totalDataLines) ..." `
                           -PercentComplete $pctDone -Id 2

            # Serialize this chunk directly — one ConvertTo-Json call, no cache
            $batchData = @($Data[$indexLoopFrom..$indexLoopTo])
            $json  = ConvertTo-Json -Depth 100 -InputObject @($batchData) -Compress
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

            if ($EnableCompression -eq $true) {
                $payloadBytes = Compress-GzipBytes -InputBytes $bytes
            } else {
                $payloadBytes = $bytes
            }

            $payloadPct = [Math]::Round(($payloadBytes.Length / $maxPayloadBytes) * 100, 1)
            Write-Verbose ("  Batch: {0} rows, payload {1:N0} bytes ({2}% of 1 MB limit)" -f $batchRowCount, $payloadBytes.Length, $payloadPct)

            if ($payloadBytes.Length -gt $maxPayloadBytes) {
                throw "Payload size ($($payloadBytes.Length) bytes) exceeds the 1 MB transaction limit. Reduce BatchAmount."
            }

            if ($totalDataLines -gt 1) {
                Write-Host ""
                Write-Host "  Posting data to LogAnalytics table [ $($TableName)_CL ]"
                Write-Host "    Rows       : $($indexLoopFrom + 1)..$($indexLoopTo + 1) / $totalDataLines"
                Write-Host "    $compressionText | $authText"
                Write-Host ""
            } else {
                Write-Host ""
                Write-Host "  Posting data to LogAnalytics table [ $($TableName)_CL ]"
                Write-Host "    Rows       : 1 / 1"
                Write-Host "    $compressionText | $authText"
                Write-Host ""
            }

            Write-Verbose ("POST {0} with {1}-byte payload" -f $uri, $payloadBytes.Length)

            try {
                $result = Invoke-WebRequest `
                    -UseBasicParsing -Uri $uri -Method Post -Headers $headers `
                    -ContentType 'application/json; charset=utf-8' `
                    -Body ([byte[]]$payloadBytes) -ErrorAction Stop

                if ($result.StatusCode -in 200,202,204) {
                    Write-Host "  SUCCESS - data uploaded to LogAnalytics" -ForegroundColor Green
                    $resultLast = $result
                } else {
                    throw "Unexpected status code returned from Log Ingestion API: $($result.StatusCode)"
                }
            }
            catch {
                $responseText = $null; $statusCode = $null
                if ($_.Exception.Response) {
                    try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
                    try {
                        $stream = $_.Exception.Response.GetResponseStream()
                        if ($stream) { $reader = New-Object System.IO.StreamReader($stream); $responseText = $reader.ReadToEnd(); $reader.Dispose() }
                    } catch {}
                }
                throw "Log Ingestion API request failed. HTTP Status: $statusCode Response: $responseText"
            }

            $indexLoopFrom = $indexLoopTo + 1
        }
        until ($indexLoopFrom -ge $totalDataLines)

        Write-Progress -Activity "Uploading to LogAnalytics table [ $($TableName)_CL ]" -Id 2 -Completed
        return $resultLast
    }

    # ── Auto-sizing path: build cache + cumulative sums for binary search ──
    $cache = New-AzLogIngestRowJsonCache -Data $Data

    # Reset adaptive compression ratio for this ingestion run
    $script:_gzipRatioEstimate = $null

    $batchNumber = 0

    do {
        $batchNumber++
        $pctDone = [Math]::Round(($indexLoopFrom / $totalDataLines) * 100)
        Write-Progress -Activity "Uploading to LogAnalytics table [ $($TableName)_CL ]" `
                       -Status "Calculating batch $batchNumber size (row $($indexLoopFrom + 1) of $totalDataLines) ..." `
                       -PercentComplete $pctDone `
                       -Id 2

        $indexLoopTo = Get-AzLogIngestBatchEndIndex `
            -Cache $cache `
            -StartIndex $indexLoopFrom `
            -MaxPayloadBytes $maxPayloadBytes `
            -EnableCompression:($EnableCompression -eq $true)

        $pctDone = [Math]::Round((($indexLoopTo + 1) / $totalDataLines) * 100)
        Write-Progress -Activity "Uploading to LogAnalytics table [ $($TableName)_CL ]" `
                       -Status "Sending batch $batchNumber (rows $($indexLoopFrom + 1)..$($indexLoopTo + 1) of $totalDataLines) ..." `
                       -PercentComplete $pctDone `
                       -Id 2

        $payloadBytes = Get-AzLogIngestPayloadBytesFromCache `
            -Cache $cache `
            -StartIndex $indexLoopFrom `
            -EndIndex $indexLoopTo `
            -EnableCompression:($EnableCompression -eq $true)

        $batchRowCount = $indexLoopTo - $indexLoopFrom + 1
        $payloadPct    = [Math]::Round(($payloadBytes.Length / $maxPayloadBytes) * 100, 1)
        Write-Verbose ("  Batch: {0} rows, payload {1:N0} bytes ({2}% of 1 MB limit)" -f $batchRowCount, $payloadBytes.Length, $payloadPct)

        if ($payloadBytes.Length -gt $maxPayloadBytes) {
            throw "Payload size ($($payloadBytes.Length) bytes) exceeds the 1 MB transaction limit in the selected transfer format."
        }

        if ($totalDataLines -gt 1) {
            Write-Host ""
            Write-Host "  Posting data to LogAnalytics table [ $($TableName)_CL ]"
            Write-Host "    Rows       : $($indexLoopFrom + 1)..$($indexLoopTo + 1) / $totalDataLines"
            Write-Host "    $compressionText | $authText"
            Write-Host ""
        }
        else {
            Write-Host ""
            Write-Host "  Posting data to LogAnalytics table [ $($TableName)_CL ]"
            Write-Host "    Rows       : 1 / 1"
            Write-Host "    $compressionText | $authText"
            Write-Host ""
        }

        Write-Verbose ("POST {0} with {1}-byte payload" -f $uri, $payloadBytes.Length)

        try {
            $result = Invoke-WebRequest `
                -UseBasicParsing -Uri $uri -Method Post -Headers $headers `
                -ContentType 'application/json; charset=utf-8' `
                -Body ([byte[]]$payloadBytes) -ErrorAction Stop

            if ($result.StatusCode -in 200,202,204) {
                Write-Host "  SUCCESS - data uploaded to LogAnalytics" -ForegroundColor Green
                $resultLast = $result
            }
            else {
                throw "Unexpected status code returned from Log Ingestion API: $($result.StatusCode)"
            }
        }
        catch {
            $responseText = $null
            $statusCode = $null

            if ($_.Exception.Response) {
                try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
                try {
                    $stream = $_.Exception.Response.GetResponseStream()
                    if ($stream) {
                        $reader = New-Object System.IO.StreamReader($stream)
                        $responseText = $reader.ReadToEnd()
                        $reader.Dispose()
                    }
                }
                catch {}
            }

            throw "Log Ingestion API request failed. HTTP Status: $statusCode Response: $responseText"
        }

        $indexLoopFrom = $indexLoopTo + 1
    }
    until ($indexLoopFrom -ge $totalDataLines)

    Write-Progress -Activity "Uploading to LogAnalytics table [ $($TableName)_CL ]" -Id 2 -Completed

    return $resultLast
}

