$ErrorActionPreference = "Stop"

$cwebp = Join-Path $PSScriptRoot "cwebp.exe"

# Search the folder the script is sitting in and every subfolder below it.
# Example: place the script in downloaded_media\cps1 and it will scan only
# cps1 plus folders such as 3dboxes, backcovers, fanart, screenshots, etc.
$targetFolder = $PSScriptRoot

$entryColors = @(
    "Cyan",
    "Green",
    "Yellow",
    "Magenta",
    "Blue",
    "White",
    "DarkCyan",
    "DarkGreen",
    "DarkYellow",
    "DarkMagenta"
)

function Format-ByteSize {
    param(
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )

    if ($Bytes -ge 1TB) {
        return "{0:N2} TB" -f ($Bytes / 1TB)
    }
    elseif ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }
    else {
        return "$Bytes bytes"
    }
}

function Invoke-CWebP {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $cwebp
    $processInfo.UseShellExecute = $false
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.CreateNoWindow = $true

    $quotedArguments = foreach ($argument in $Arguments) {
        if ($argument -match '\s|[()]') {
            '"' + $argument + '"'
        }
        else {
            $argument
        }
    }

    $processInfo.Arguments = $quotedArguments -join " "

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    [void]$process.Start()

    $standardOutput = $process.StandardOutput.ReadToEnd()
    $standardError = $process.StandardError.ReadToEnd()

    $process.WaitForExit()

    $result = [PSCustomObject]@{
        ExitCode = $process.ExitCode
        Output   = (($standardOutput, $standardError) -join [Environment]::NewLine).Trim()
    }

    $process.Dispose()
    return $result
}

if (-not (Test-Path -LiteralPath $cwebp)) {
    Write-Host "ERROR: cwebp.exe was not found here:" -ForegroundColor Red
    Write-Host $cwebp -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

$pngFiles = @(
    Get-ChildItem -LiteralPath $targetFolder -Filter *.png -File -Recurse |
    Sort-Object FullName
)

$jpgFiles = @(
    @(
        Get-ChildItem -LiteralPath $targetFolder -Filter *.jpg -File -Recurse
        Get-ChildItem -LiteralPath $targetFolder -Filter *.jpeg -File -Recurse
    ) |
    Sort-Object FullName -Unique
)

$allFiles = @($pngFiles + $jpgFiles)
$total = $allFiles.Count

if ($total -eq 0) {
    Write-Host "No PNG/JPG/JPEG files found in:" -ForegroundColor Yellow
    Write-Host $targetFolder -ForegroundColor Cyan
    Read-Host "Press Enter to close"
    exit 0
}

Write-Host "Scan root:" -ForegroundColor Magenta
Write-Host $targetFolder -ForegroundColor White
Write-Host ""
Write-Host "Files found:" -ForegroundColor Magenta
Write-Host "PNG:      $($pngFiles.Count)" -ForegroundColor Cyan
Write-Host "JPG/JPEG: $($jpgFiles.Count)" -ForegroundColor Green
Write-Host "Total:    $total" -ForegroundColor Yellow
Write-Host ""

$converted = 0
$skipped = 0
$failed = 0

$pngConverted = 0
$pngSkipped = 0
$pngFailed = 0

$jpgConverted = 0
$jpgSkipped = 0
$jpgFailed = 0

for ($index = 0; $index -lt $total; $index++) {
    $source = $allFiles[$index]
    $current = $index + 1
    $color = $entryColors[$index % $entryColors.Count]
    $webpPath = [System.IO.Path]::ChangeExtension($source.FullName, ".webp")
    $percent = [math]::Round(($current / $total) * 100, 1)
    $extension = $source.Extension.ToLowerInvariant()

    if ($extension -eq ".png") {
        $modeLabel = "PNG lossless"
    }
    else {
        $modeLabel = "JPG q90"
    }

    Write-Progress `
        -Activity "Converting images to WEBP" `
        -Status "$current / $total  -  $($source.Name)  -  $modeLabel" `
        -PercentComplete $percent

    if (Test-Path -LiteralPath $webpPath) {
        Write-Host "[$current/$total] SKIPPED:   $($source.Name)  ->  $modeLabel" -ForegroundColor $color
        $skipped++

        if ($extension -eq ".png") {
            $pngSkipped++
        }
        else {
            $jpgSkipped++
        }

        continue
    }

    if ($extension -eq ".png") {
        $result = Invoke-CWebP -Arguments @(
            "-z", "9",
            "-o", $webpPath,
            $source.FullName
        )
    }
    else {
        $result = Invoke-CWebP -Arguments @(
            "-preset", "photo",
            "-q", "90",
            "-m", "6",
            "-mt",
            "-o", $webpPath,
            $source.FullName
        )
    }

    if ($result.ExitCode -eq 0 -and (Test-Path -LiteralPath $webpPath)) {
        Write-Host "[$current/$total] CONVERTED: $($source.Name)  ->  $modeLabel" -ForegroundColor $color
        $converted++

        if ($extension -eq ".png") {
            $pngConverted++
        }
        else {
            $jpgConverted++
        }
    }
    else {
        Write-Host "[$current/$total] ERROR:     $($source.FullName)" -ForegroundColor Red

        if ($result.Output) {
            $result.Output -split "`r?`n" | ForEach-Object {
                if ($_ -ne "") {
                    Write-Host "    $_" -ForegroundColor Red
                }
            }
        }

        $failed++
        Remove-Item -LiteralPath $webpPath -Force -ErrorAction SilentlyContinue

        if ($extension -eq ".png") {
            $pngFailed++
        }
        else {
            $jpgFailed++
        }
    }
}

Write-Progress -Activity "Converting images to WEBP" -Completed

[long]$totalSourceBytes = 0
[long]$totalWebpBytes = 0
[int]$pairedFiles = 0

[long]$pngSourceBytes = 0
[long]$pngWebpBytes = 0
[int]$pngPairs = 0

[long]$jpgSourceBytes = 0
[long]$jpgWebpBytes = 0
[int]$jpgPairs = 0

foreach ($source in $allFiles) {
    $webpPath = [System.IO.Path]::ChangeExtension($source.FullName, ".webp")

    if (Test-Path -LiteralPath $webpPath) {
        $webp = Get-Item -LiteralPath $webpPath

        $totalSourceBytes += $source.Length
        $totalWebpBytes += $webp.Length
        $pairedFiles++

        if ($source.Extension.ToLowerInvariant() -eq ".png") {
            $pngSourceBytes += $source.Length
            $pngWebpBytes += $webp.Length
            $pngPairs++
        }
        else {
            $jpgSourceBytes += $source.Length
            $jpgWebpBytes += $webp.Length
            $jpgPairs++
        }
    }
}

[long]$totalDifference = $totalSourceBytes - $totalWebpBytes
[long]$pngDifference = $pngSourceBytes - $pngWebpBytes
[long]$jpgDifference = $jpgSourceBytes - $jpgWebpBytes

if ($totalSourceBytes -gt 0) {
    $totalPercentDifference = [math]::Round(([math]::Abs($totalDifference) / $totalSourceBytes) * 100, 2)
}
else {
    $totalPercentDifference = 0
}

if ($pngSourceBytes -gt 0) {
    $pngPercentDifference = [math]::Round(([math]::Abs($pngDifference) / $pngSourceBytes) * 100, 2)
}
else {
    $pngPercentDifference = 0
}

if ($jpgSourceBytes -gt 0) {
    $jpgPercentDifference = [math]::Round(([math]::Abs($jpgDifference) / $jpgSourceBytes) * 100, 2)
}
else {
    $jpgPercentDifference = 0
}

Write-Host ""
Write-Host "Finished." -ForegroundColor Green
Write-Host "Converted: $converted" -ForegroundColor Cyan
Write-Host "Skipped:   $skipped" -ForegroundColor Yellow

if ($failed -gt 0) {
    Write-Host "Failed:    $failed" -ForegroundColor Red
}
else {
    Write-Host "Failed:    0" -ForegroundColor Green
}

Write-Host ""
Write-Host "By source type:" -ForegroundColor Magenta
Write-Host "PNG  -> Converted: $pngConverted   Skipped: $pngSkipped   Failed: $pngFailed" -ForegroundColor Cyan
Write-Host "JPG  -> Converted: $jpgConverted   Skipped: $jpgSkipped   Failed: $jpgFailed" -ForegroundColor Green

Write-Host ""
Write-Host "Overall storage comparison for $pairedFiles source/WEBP pairs:" -ForegroundColor Magenta
Write-Host "Original total:      $(Format-ByteSize $totalSourceBytes)" -ForegroundColor Cyan
Write-Host "WEBP total:          $(Format-ByteSize $totalWebpBytes)" -ForegroundColor Green

if ($totalDifference -gt 0) {
    Write-Host "Total space saved:   $(Format-ByteSize $totalDifference) ($totalPercentDifference%)" -ForegroundColor Yellow
}
elseif ($totalDifference -lt 0) {
    Write-Host "Total size increase: $(Format-ByteSize ([math]::Abs($totalDifference))) ($totalPercentDifference%)" -ForegroundColor Yellow
}
else {
    Write-Host "Total size change:   0 bytes (0%)" -ForegroundColor White
}

Write-Host ""
Write-Host "PNG storage comparison ($pngPairs pairs, lossless):" -ForegroundColor Magenta
Write-Host "Original PNG total:  $(Format-ByteSize $pngSourceBytes)" -ForegroundColor Cyan
Write-Host "WEBP PNG total:      $(Format-ByteSize $pngWebpBytes)" -ForegroundColor Green

if ($pngDifference -gt 0) {
    Write-Host "PNG space saved:     $(Format-ByteSize $pngDifference) ($pngPercentDifference%)" -ForegroundColor Yellow
}
elseif ($pngDifference -lt 0) {
    Write-Host "PNG size increase:   $(Format-ByteSize ([math]::Abs($pngDifference))) ($pngPercentDifference%)" -ForegroundColor Yellow
}
else {
    Write-Host "PNG size change:     0 bytes (0%)" -ForegroundColor White
}

Write-Host ""
Write-Host "JPG storage comparison ($jpgPairs pairs, q90):" -ForegroundColor Magenta
Write-Host "Original JPG total:  $(Format-ByteSize $jpgSourceBytes)" -ForegroundColor Cyan
Write-Host "WEBP JPG total:      $(Format-ByteSize $jpgWebpBytes)" -ForegroundColor Green

if ($jpgDifference -gt 0) {
    Write-Host "JPG space saved:     $(Format-ByteSize $jpgDifference) ($jpgPercentDifference%)" -ForegroundColor Yellow
}
elseif ($jpgDifference -lt 0) {
    Write-Host "JPG size increase:   $(Format-ByteSize ([math]::Abs($jpgDifference))) ($jpgPercentDifference%)" -ForegroundColor Yellow
}
else {
    Write-Host "JPG size change:     0 bytes (0%)" -ForegroundColor White
}

Write-Host ""
Write-Host "PNG originals were kept. JPG originals were kept." -ForegroundColor White
Read-Host "Press Enter to close"
