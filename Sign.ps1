param(
    [Parameter(Mandatory = $true, Position = 0)][string]$InputFile,
    [Parameter(Position = 1)][string]$OutputFile,
    [switch]$Pause
)
$ErrorActionPreference = 'Stop'
$exitCode = 0
try {
    $inputPath = (Resolve-Path -LiteralPath $InputFile).ProviderPath
    if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) { throw 'Input must be a file.' }
    if ([IO.Path]::GetExtension($inputPath) -notin '.apk', '.zip', '.jar') { throw 'Supported inputs: .apk, .zip, .jar' }
    if (-not $OutputFile) { $OutputFile = Join-Path (Split-Path $inputPath) ('pwelyn_' + [IO.Path]::GetFileName($inputPath)) }
    $outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    if (Test-Path -LiteralPath $outputPath) { throw 'Output already exists; choose another path.' }
    $java = (Get-Command java -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    foreach ($file in 'signapk.jar', 'testkey.x509.pem', 'testkey.pk8') {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $file) -PathType Leaf)) { throw "Missing dependency: $file" }
    }
    $temporary = Join-Path (Split-Path $outputPath) ([IO.Path]::GetRandomFileName())
    try {
        & $java -jar "$PSScriptRoot/signapk.jar" -w "$PSScriptRoot/testkey.x509.pem" "$PSScriptRoot/testkey.pk8" $inputPath $temporary
        if ($LASTEXITCODE -ne 0) { throw "Signing failed (Java exit code $LASTEXITCODE)." }
        [IO.File]::Move($temporary, $outputPath)
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
    Write-Host "Signed: $outputPath"
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    $exitCode = 1
} finally {
    if ($Pause) { [void](Read-Host 'Press Enter to close') }
}
exit $exitCode
