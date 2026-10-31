function Block($why) { Write-Output "GATE_BLOCKED: $why"; exit 1 }

$cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$state = Get-Content (Join-Path $cfg 'delegate-skills.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
if ($state.disabled -contains 'kiro') { Block 'kiro disabled by user (delegate-skills enable kiro)' }

$kiro = (Get-Command kiro-cli -ErrorAction SilentlyContinue).Source
if (-not $kiro) { $kiro = Join-Path $env:LOCALAPPDATA 'Kiro-Cli\kiro-cli.exe' }
if (-not (Test-Path $kiro)) { Block 'kiro-cli not installed' }

$who = (& $kiro whoami 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $who -match 'Not logged in') { Block 'not logged in; user must run: kiro-cli login' }

Write-Output "GATE_OK kiro=$kiro whoami=$($who -replace '\s+', ' ')"
