param(
    [Parameter(Mandatory)][string]$Prompt,
    [string]$Cwd = (Get-Location).Path,
    [switch]$Write,
    [ValidateSet('gpt-6.1-sol', 'gpt-6-astra')][string]$Model = 'gpt-6.1-sol',
    [int]$TimeoutSec = 600
)

& (Join-Path $PSScriptRoot 'codex-gate.ps1')
if ($LASTEXITCODE -ne 0) { Write-Output "CODEX_GATE_EXIT=$LASTEXITCODE"; exit 3 }

$codex = Join-Path $env:USERPROFILE '.codex\.sandbox-bin\codex.exe'
if (-not (Test-Path $codex)) { Write-Error "codex.exe not found at $codex"; exit 2 }

$sandbox = if ($Write) { 'workspace-write' } else { 'read-only' }
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("codex-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $tmp | Out-Null
$inFile, $outFile, $stdout, $stderr = 'in.txt', 'last.txt', 'stdout.txt', 'stderr.txt' | ForEach-Object { Join-Path $tmp $_ }
Set-Content $inFile $Prompt -NoNewline -Encoding utf8

$cliArgs = @('exec', '-m', $Model, '-c', 'model_reasoning_effort="medium"', '-C', $Cwd, '-s', $sandbox, '--skip-git-repo-check', '--ephemeral', '--color', 'never', '-o', $outFile, '-')
$p = Start-Process $codex -ArgumentList $cliArgs -RedirectStandardInput $inFile -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru
$null = $p.Handle

try {
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        Stop-Process -Id $p.Id -Force
        Write-Output "CODEX_TIMEOUT after ${TimeoutSec}s"
        exit 124
    }
    if ($p.ExitCode -ne 0) {
        Write-Output "CODEX_FAILED exit=$($p.ExitCode)"
        Get-Content $stderr -Tail 15
        exit $p.ExitCode
    }
    if (Test-Path $outFile) { Get-Content $outFile -Raw } else { Get-Content $stdout -Raw }
    if ($Write -and (Test-Path (Join-Path $Cwd '.git'))) {
        Write-Output "`n--- git status ---"
        git -C $Cwd status --short
    }
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
