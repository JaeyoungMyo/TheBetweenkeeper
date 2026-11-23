[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# Stop 훅: 작업 step이 끝날 때마다 실행된다.
#  - 커밋되지 않은 변경이 있으면 Claude가 커밋 메시지를 직접 작성해 커밋/push하도록 응답을 막는다(block).
#  - 커밋은 있는데 원격에 올라가지 않았다면 push하도록 막는다.
#  - 그 외에는 아무것도 하지 않고 종료한다.
# 무한 반복 방지: stop_hook_active가 true면(이미 이 훅 때문에 이어서 작업 중) 그냥 종료한다.

$ErrorActionPreference = 'Continue'

# 훅 입력(JSON)을 읽어 stop_hook_active 확인
$raw = [Console]::In.ReadToEnd()
try { $hookInput = $raw | ConvertFrom-Json } catch { $hookInput = $null }
if ($hookInput -and $hookInput.stop_hook_active) { exit 0 }

git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { exit 0 }

$hasRemote = [bool](git remote 2>$null)
$branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
$changes = git status --porcelain

$trailer = "Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>"
$pushRule = if ($hasRemote) { "커밋 후 'git push -u origin $branch' 까지 실행한다." } else { "원격(remote)이 설정되어 있지 않으므로 push는 하지 않고 커밋까지만 한다." }

function Send-Block([string]$reason) {
    $obj = @{ decision = 'block'; reason = $reason }
    Write-Output ($obj | ConvertTo-Json -Compress)
    exit 0
}

if ($changes) {
    Send-Block @"
[자동 커밋 규칙] 이번 step의 변경 사항이 아직 커밋되지 않았다. 아래 순서로 처리하라.
1. 'git status' 와 'git diff' 로 이번 step에서 바뀐 내용을 확인한다. (.gitignore 대상, 비밀 파일(.env, credentials 등)은 제외)
2. 변경 내용을 설명하는 커밋 메시지를 작성한다. 제목은 한 줄(50자 안팎, 한글 가능), 필요하면 본문에 무엇을 왜 바꿨는지 적는다.
3. 관련 파일만 'git add' 하고 'git commit' 한다. 메시지 마지막 줄은 반드시 다음과 같다: $trailer
4. $pushRule
사용자에게 커밋 해시와 push 결과를 짧게 보고한다.
"@
}

if ($hasRemote -and $branch -and $branch -ne 'HEAD') {
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    $needPush = $false
    if ($LASTEXITCODE -ne 0 -or -not $upstream) { $needPush = $true }
    else {
        $ahead = (git rev-list --count "@{u}..HEAD" 2>$null)
        if ($ahead -and [int]$ahead -gt 0) { $needPush = $true }
    }
    if ($needPush) {
        Send-Block "[자동 push 규칙] 커밋되었지만 원격에 올라가지 않은 변경이 있다. 'git push -u origin $branch' 를 실행하고 결과를 짧게 보고하라."
    }
}

exit 0
