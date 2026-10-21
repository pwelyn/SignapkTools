$ErrorActionPreference = 'Stop'
try {
    $null = Get-Command java -CommandType Application -ErrorAction Stop
    $destination = Join-Path $env:LOCALAPPDATA 'SignapkTools'
    $files = @('Sign.ps1', 'singapk.cmd', 'signapk.jar', 'testkey.x509.pem', 'testkey.pk8')
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $file) -PathType Leaf)) { throw "Missing dependency: $file" }
    }
    $null = New-Item -ItemType Directory -Path $destination -Force
    if ([IO.Path]::GetFullPath($PSScriptRoot) -ne [IO.Path]::GetFullPath($destination)) {
        foreach ($file in $files) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination $destination -Force }
    }
    foreach ($extension in '.apk', '.zip') {
        $key = "HKCU:\Software\Classes\SystemFileAssociations\$extension\shell\SignapkTools"
        $null = New-Item -Path "$key\command" -Force
        Set-Item -LiteralPath $key -Value 'Sign with SignapkTools (test key)'
        Set-Item -LiteralPath "$key\command" -Value ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}\Sign.ps1" -Pause "%1"' -f $destination)
    }
    Write-Host "Installed for current user: $destination"
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
