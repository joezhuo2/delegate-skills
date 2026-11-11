function Block($why) { Write-Output "GATE_BLOCKED: $why"; exit 1 }

$cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$state = Get-Content (Join-Path $cfg 'delegate-skills.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
if ($state.disabled -contains 'qwen') { Block 'qwen disabled by user (delegate-skills enable qwen)' }

$exe = (Get-Command qwen.cmd, qwen.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $exe) { Block 'qwen not installed; user must run: npm install -g @qwen-code/qwen-code' }

Write-Output "GATE_OK exe=$exe"
exit 0
