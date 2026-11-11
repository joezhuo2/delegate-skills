function Block($why) { Write-Output "GATE_BLOCKED: $why"; exit 1 }

$cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$state = Get-Content (Join-Path $cfg 'delegate-skills.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
if ($state.disabled -contains 'gemini') { Block 'gemini disabled by user (delegate-skills enable gemini)' }

$exe = (Get-Command gemini.cmd, gemini.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $exe) { Block 'gemini not installed; user must run: npm install -g @google/gemini-cli' }

Write-Output "GATE_OK exe=$exe"
exit 0
