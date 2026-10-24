# SessionStart hook: re-inject the active project's board so a new session resumes from files, not memory.
. (Join-Path $PSScriptRoot '..\lib\common.ps1')
$ErrorActionPreference = 'Continue'
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $slug = Get-ActiveSlug
    if (-not $slug) { exit 0 }
    $st = Get-State $slug
    Write-Output "[LP-CRO] Active project '$slug' (projects/$slug). Resume per workflows/landing-page-optimization.md section 3."
    Write-Output (Get-StatusBoard $st)
    if ($st.state -eq 'WAITING_FOR_APPROVAL') { Write-Output "Approval status: $($st.approval.status). Production stays locked until the user replies APPROVE." }
    if ($st.state -eq 'BLOCKED') { Write-Output "BLOCKED [$($st.blocked.kind)]: $($st.blocked.reason)" }
} catch { }
exit 0
