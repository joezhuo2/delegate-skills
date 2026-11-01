param(
    [Parameter(Mandatory)][string]$Prompt,
    [string]$Cwd = (Get-Location).Path,
    [ValidateSet('opus', 'sonnet', 'haiku')][string]$Tier = 'sonnet',
    [string]$Model,
    [switch]$Write,
    [int]$TimeoutSec = 900
)

$gate = & (Join-Path $PSScriptRoot 'kiro-gate.ps1')
if ($LASTEXITCODE -ne 0) { Write-Output $gate; exit 3 }
$kiro = ($gate -replace '^.*kiro=(.*?) whoami=.*$', '$1')

if (-not $Model) {
    $listing = & $kiro chat --list-models 2>&1 | Out-String
    $best = [regex]::Matches($listing, "(?im)^[\s*]*(?<id>claude-$Tier[\w.\-]*)") |
        ForEach-Object {
            $v = [regex]::Match($_.Groups['id'].Value, '(\d+(?:[.\-]\d+)*)').Groups[1].Value -replace '-', '.'
            [pscustomobject]@{ Id = $_.Groups['id'].Value; Ver = if ($v) { [version]($v + $(if ($v -notmatch '\.') { '.0' })) } else { [version]'0.0' } }
        } | Sort-Object Ver -Descending | Select-Object -First 1
    if (-not $best) { Write-Output "KIRO_NO_MODEL no '$Tier' model in --list-models:`n$listing"; exit 4 }
    $Model = $best.Id
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("kiro-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $tmp | Out-Null
$inFile, $stdout, $stderr = 'in.txt', 'stdout.txt', 'stderr.txt' | ForEach-Object { Join-Path $tmp $_ }
Set-Content $inFile $Prompt -NoNewline -Encoding utf8

$trust = if ($Write) { '--trust-all-tools' } else { '--trust-tools=fs_read' }
$cliArgs = @('chat', '--no-interactive', '--model', $Model, $trust, '--wrap', 'never')
$p = Start-Process $kiro -ArgumentList $cliArgs -WorkingDirectory $Cwd -RedirectStandardInput $inFile -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru
$null = $p.Handle

try {
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        Stop-Process -Id $p.Id -Force
        Write-Output "KIRO_TIMEOUT after ${TimeoutSec}s"
        exit 124
    }
    $text = Get-Content $stdout -Raw
    $err = Get-Content $stderr -Raw
    if ($p.ExitCode -ne 0) {
        Write-Output "KIRO_FAILED exit=$($p.ExitCode) model=$Model"
        if (($err + $text) -match '(?i)limit|quota|credit') { Write-Output 'KIRO_LIMIT: usage or credits exhausted' }
        ($err + $text) -split "`n" | Select-Object -Last 15
        exit $p.ExitCode
    }
    Write-Output "model=$Model"
    $text
    if ($Write -and (Test-Path (Join-Path $Cwd '.git'))) {
        Write-Output "`n--- git status ---"
        git -C $Cwd status --short
    }
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
