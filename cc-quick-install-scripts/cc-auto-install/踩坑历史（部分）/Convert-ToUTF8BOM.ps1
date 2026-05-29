Get-ChildItem -Recurse -Include *.bat, *.cmd, *.ps1 | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host "跳过 (已有 BOM): $($_.Name)" -ForegroundColor Green
    } else {
        $utf8BOM = New-Object System.Text.UTF8Encoding $true
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($_.FullName, $content, $utf8BOM)
        Write-Host "已转换: $($_.Name)" -ForegroundColor Yellow
    }
}