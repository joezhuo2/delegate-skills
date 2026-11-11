function Block($why) { Write-Output "GATE_BLOCKED: $why"; exit 1 }

$cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$state = Get-Content (Join-Path $cfg 'delegate-skills.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
if ($state.disabled -contains 'copilot') { Block 'copilot disabled by user (delegate-skills enable copilot)' }

$exe = (Get-Command copilot.cmd, copilot.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $exe) { Block 'copilot not installed; user must run: npm install -g @github/copilot' }

Write-Output "GATE_OK exe=$exe"
exit 0
