# PreToolUse hook. Blocks (exit 2) any tool call that would:
#   1. write production artifacts (copy/design/build/QA/verification/final report) before user approval;
#   2. write into the registered client codebase before user approval;
#   3. edit state.json directly (it is engine-owned; use scripts/lpcro.ps1);
#   4. invoke the approval hook manually or forge approval via the shell.

. (Join-Path $PSScriptRoot '..\lib\common.ps1')
$ErrorActionPreference = 'Continue'

function Deny([string]$msg) {
    [Console]::Error.WriteLine("LP-CRO GUARD: $msg")
    exit 2
}

function Test-Approved([string]$slug) {
    try { $s = Get-State $slug; return ($s.approval.status -eq 'APPROVED') } catch { return $true }
}

try {
    $in = Read-HookInput
    if (-not $in) { exit 0 }
    $tool = "$($in.tool_name)"
    $ti = $in.tool_input
    $projectsDir = (Get-ProjectsDir).TrimEnd('\')
    $m = Get-Machine
    $gated = @($m.gated_paths_before_approval | ForEach-Object { $_.Replace('/', '\') })

    if ($tool -in 'Write', 'Edit', 'MultiEdit', 'NotebookEdit') {
        $fp = $ti.file_path; if (-not $fp) { $fp = $ti.notebook_path }
        if (-not $fp) { exit 0 }
        $full = [System.IO.Path]::GetFullPath($fp)

        if ($full.StartsWith($projectsDir + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            $rel = $full.Substring($projectsDir.Length + 1)
            $slug = $rel.Split('\')[0]
            $inner = ''
            if ($rel.Length -gt $slug.Length + 1) { $inner = $rel.Substring($slug.Length + 1) }
            if ($inner -ieq 'state.json') { Deny "state.json is owned by the workflow engine. Use: powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lpcro.ps1 <command>" }
            if ($inner -ieq 'PROJECT_STATE.md') { Deny 'PROJECT_STATE.md is rendered from state.json. Use the engine (lpcro.ps1) to change state.' }
            foreach ($g in $gated) {
                if ($inner.StartsWith($g, [System.StringComparison]::OrdinalIgnoreCase) -or $inner -ieq $g.TrimEnd('\')) {
                    if (-not (Test-Approved $slug)) {
                        Deny "APPROVAL GATE: '$inner' is a production artifact. Project '$slug' has no user approval yet. Present approval/BLUEPRINT.md and wait for the user to reply APPROVE."
                    }
                }
            }
            exit 0
        }

        $slug = Get-ActiveSlug
        if ($slug) {
            try { $s = Get-State $slug } catch { exit 0 }
            $cb = $s.project.codebase_path
            if ($cb -and $s.approval.status -ne 'APPROVED') {
                $cbFull = [System.IO.Path]::GetFullPath($cb).TrimEnd('\')
                if ($full.StartsWith($cbFull + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
                    Deny "APPROVAL GATE: '$full' is inside the client codebase ($cbFull). No changes to the live project before the user approves the blueprint."
                }
            }
        }
        exit 0
    }

    if ($tool -in 'PowerShell', 'Bash') {
        $cmd = "$($ti.command)"
        if (-not $cmd) { exit 0 }
        if ($cmd -match '(?i)capture-decision') { Deny 'The approval hook may only be triggered by the user typing a reply. Do not invoke it.' }
        $writeVerb = '(?i)(Set-Content|Add-Content|Out-File|WriteAllText|WriteAllBytes|Copy-Item|Move-Item|Remove-Item|New-Item|\bcp\b|\bmv\b|\brm\b|\btee\b|\bsed\b|>>?)'
        if ($cmd -match '(?i)state\.json' -and $cmd -match $writeVerb -and $cmd -notmatch '(?i)lpcro\.ps1') {
            Deny 'state.json may only be changed through scripts/lpcro.ps1.'
        }
        if ($cmd -match '(?i)"?approval"?\s*[\.:]\s*"?status' -and $cmd -match '(?i)APPROVED') {
            Deny 'Approval cannot be set from the shell. Only the user can approve, by replying APPROVE.'
        }
        $slug = Get-ActiveSlug
        if ($slug -and -not (Test-Approved $slug) -and $cmd -match $writeVerb) {
            foreach ($g in $gated) {
                $pat = [regex]::Escape($g.TrimEnd('\')) -replace '\\\\', '[\\/]'
                if ($cmd -match "(?i)[\\/]$pat([\\/]|\b)") {
                    Deny "APPROVAL GATE: shell command writes to a production path ($g) before user approval."
                }
            }
        }
        exit 0
    }
} catch {
    [Console]::Error.WriteLine("guard hook error (allowing): $($_.Exception.Message)")
}
exit 0
