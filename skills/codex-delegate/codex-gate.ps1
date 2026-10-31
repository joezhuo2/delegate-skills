param([int]$MaxPercent = 95)

$home_ = Join-Path $env:USERPROFILE '.codex'

function Block($why) { Write-Output "GATE_BLOCKED: $why"; exit 1 }

$cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$state = Get-Content (Join-Path $cfg 'delegate-skills.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
if ($state.disabled -contains 'codex') { Block 'codex disabled by user (delegate-skills enable codex)' }

$auth = Get-Content (Join-Path $home_ 'auth.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
if (-not $auth.tokens.id_token) { Block 'not logged in to Codex' }
$seg = $auth.tokens.id_token.Split('.')[1].Replace('-', '+').Replace('_', '/')
while ($seg.Length % 4) { $seg += '=' }
$claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($seg)) | ConvertFrom-Json
$plan = $claims.'https://api.openai.com/auth'.chatgpt_plan_type
if ($plan -ne 'plus') { Block "plan is '$plan', need 'plus'" }

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$line = Get-ChildItem (Join-Path $home_ 'sessions') -Recurse -Filter *.jsonl -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 30 |
    ForEach-Object { Select-String -Path $_.FullName -Pattern '"primary":\{' | Select-Object -Last 1 } |
    Where-Object { $_ } | Select-Object -First 1

$report = @()
if ($line) {
    $rl = ($line.Line | ConvertFrom-Json).payload.rate_limits
    foreach ($w in 'primary', 'secondary') {
        $x = $rl.$w
        if (-not $x) { continue }
        $used = if ($x.resets_at -le $now) { 0 } else { [double]$x.used_percent }
        $report += "$w=$used% ($($x.window_minutes)min)"
        if ($used -ge $MaxPercent) {
            $reset = [DateTimeOffset]::FromUnixTimeSeconds($x.resets_at).ToLocalTime().ToString('g')
            Block "$w window at $used%, resets $reset"
        }
    }
    if ($rl.rate_limit_reached_type -and ($rl.primary.resets_at -gt $now)) { Block "limit reached: $($rl.rate_limit_reached_type)" }
}
else {
    $report += 'usage=unknown (no recent session data)'
}

Write-Output "GATE_OK plan=$plan $($report -join ' ')"
