function Block($why) { Write-Output "GATE_BLOCKED: $why"; exit 1 }

$kiro = (Get-Command kiro-cli -ErrorAction SilentlyContinue).Source
if (-not $kiro) { $kiro = Join-Path $env:LOCALAPPDATA 'Kiro-Cli\kiro-cli.exe' }
if (-not (Test-Path $kiro)) { Block 'kiro-cli not installed' }

$who = (& $kiro whoami 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $who -match 'Not logged in') { Block 'not logged in; user must run: kiro-cli login' }

Write-Output "GATE_OK kiro=$kiro whoami=$($who -replace '\s+', ' ')"
