$ErrorActionPreference = 'Stop'
try {
    foreach ($extension in '.apk', '.zip') {
        $key = "HKCU:\Software\Classes\SystemFileAssociations\$extension\shell\SignapkTools"
        if (Test-Path -LiteralPath $key) { Remove-Item -LiteralPath $key -Recurse -Force }
    }
    $destination = Join-Path $env:LOCALAPPDATA 'SignapkTools'
    foreach ($file in 'Sign.ps1', 'singapk.cmd', 'signapk.jar', 'testkey.x509.pem', 'testkey.pk8') {
        $path = Join-Path $destination $file
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    if ((Test-Path -LiteralPath $destination) -and -not (Get-ChildItem -LiteralPath $destination -Force)) {
        Remove-Item -LiteralPath $destination
    }
    Write-Host 'Uninstalled. Legacy System32 installations must be removed with the original uninstaller.'
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
