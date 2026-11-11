param(
    [Parameter(Mandatory)][string]$Prompt,
    [string]$Cwd = (Get-Location).Path,
    [string]$Model,
    [switch]$Write,
    [int]$TimeoutSec = 900
)

$gate = & (Join-Path $PSScriptRoot 'copilot-gate.ps1')
if ($LASTEXITCODE -ne 0) { Write-Output $gate; exit 3 }
$exe = $gate -replace '^GATE_OK exe=', ''

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("copilot-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $tmp | Out-Null
$inFile, $stdout, $stderr = 'in.txt', 'stdout.txt', 'stderr.txt' | ForEach-Object { Join-Path $tmp $_ }
Set-Content $inFile $Prompt -NoNewline -Encoding utf8

$perm = if ($Write) { @('--allow-all') } else { @('--allow-all-tools', '--deny-tool=write', '--deny-tool=shell') }
$cliArgs = @('-s', '--no-color') + $perm
if ($Model) { $cliArgs += '--model', $Model }
$p = Start-Process $exe -ArgumentList $cliArgs -WorkingDirectory $Cwd -RedirectStandardInput $inFile -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru
$null = $p.Handle

try {
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        taskkill /T /F /PID $p.Id | Out-Null
        Write-Output "COPILOT_TIMEOUT after ${TimeoutSec}s"
        exit 124
    }
    $text = Get-Content $stdout -Raw
    $err = Get-Content $stderr -Raw
    if ($p.ExitCode -ne 0) {
        Write-Output "COPILOT_FAILED exit=$($p.ExitCode)"
        if (($err + $text) -match '(?i)auth|login|credential') { Write-Output 'COPILOT_AUTH: user must run copilot and use /login' }
        if (($err + $text) -match '(?i)quota|rate limit|429|resource.?exhausted') { Write-Output 'COPILOT_LIMIT: usage or quota exhausted' }
        ($err + $text) -split "`n" | Select-Object -Last 15
        exit $p.ExitCode
    }
    Write-Output "model=$(if ($Model) { $Model } else { 'default' })"
    $text
    if ($Write -and (Test-Path (Join-Path $Cwd '.git'))) {
        Write-Output "`n--- git status ---"
        git -C $Cwd status --short
    }
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
