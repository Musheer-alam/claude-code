# UserPromptSubmit hook. The ONLY writer of user approval.
# Approval can therefore only come from text the user typed, never from the model,
# a subagent, a web page or a tool result. The engine has no approve command.
#
# Recognised replies (whole message, case-insensitive) while WAITING_FOR_APPROVAL:
#   APPROVE | APPROVED | 1 | /lp-approve          -> APPROVED (bound to the blueprint hash)
#   REVISE ... | 2 ... | /lp-revise ...           -> REVISION_REQUESTED
#   ASK QUESTIONS ... | 3 ...                     -> QUESTIONS (no state change)
#   START OVER | 4 | /lp-restart                  -> RESTART_REQUESTED
# While BLOCKED on MAX_ITERATIONS:
#   EXTEND [n] | /lp-extend [n]                   -> raises the iteration cap by n (1-3, default 1)

. (Join-Path $PSScriptRoot '..\lib\common.ps1')
$ErrorActionPreference = 'Continue'

try {
    $in = Read-HookInput
    if (-not $in -or -not $in.prompt) { exit 0 }
    $slug = Get-ActiveSlug
    if (-not $slug) { exit 0 }
    $pd = Get-ProjectDir $slug
    if (-not (Test-Path (Join-Path $pd 'state.json'))) { exit 0 }
    $st = Get-State $slug
    $p = "$($in.prompt)".Trim()
    $now = Get-NowIso

    if ($st.state -eq 'WAITING_FOR_APPROVAL') {
        if ($p -match '^(?i)(/lp-approve|approve|approved|1|1\.\s*approve)\s*[.!]?$') {
            $h = Get-BlueprintHash $pd
            if ($st.approval.blueprint_hash -and $h -ne $st.approval.blueprint_hash) {
                $st.approval.status = 'STALE'
                $st.approval.history += [pscustomobject]@{ at = $now; event = 'STALE'; detail = 'blueprint changed after it was presented; approval NOT recorded' }
                Save-State $slug $st
                Write-Output "[LP-CRO] The user replied APPROVE, but the blueprint files changed after it was presented (hash mismatch). Approval was NOT recorded. Re-run 'transition -To WAITING_FOR_APPROVAL' from ARCHITECTURE (or re-present the current blueprint) and ask again."
                exit 0
            }
            $st.approval.status = 'APPROVED'
            $st.approval.approved_at = $now
            $st.approval.approved_hash = $h
            $st.approval.source = 'user-prompt-hook'
            $st.approval.user_text = $p
            $st.approval.history += [pscustomobject]@{ at = $now; event = 'APPROVED'; detail = $h }
            Save-State $slug $st
            Write-Output "[LP-CRO] USER APPROVAL RECORDED for project '$slug' (blueprint $($h.Substring(0,12))). Production is unlocked: run 'transition -To PRODUCTION', then the copywriter."
            exit 0
        }
        if ($p -match '^(?i)(/lp-revise|revise|2)\b') {
            $st.approval.status = 'REVISION_REQUESTED'
            $st.approval.user_text = $p
            $st.approval.history += [pscustomobject]@{ at = $now; event = 'REVISION_REQUESTED'; detail = $p }
            Save-State $slug $st
            Write-Output "[LP-CRO] User requested REVISION. Route the requested change to the owning agent only (do not restart the workflow), transition back to that state, then re-present the blueprint."
            exit 0
        }
        if ($p -match '^(?i)(/lp-restart|start over|4)\s*[.!]?$') {
            $st.approval.status = 'RESTART_REQUESTED'
            $st.approval.user_text = $p
            $st.approval.history += [pscustomobject]@{ at = $now; event = 'RESTART_REQUESTED'; detail = $p }
            Save-State $slug $st
            Write-Output "[LP-CRO] User asked to START OVER. Confirm scope with the user (re-intake vs re-research), then transition back accordingly."
            exit 0
        }
        if ($p -match '^(?i)(ask questions|questions?|3)\b') {
            Write-Output "[LP-CRO] User wants to ask questions about the blueprint. Answer them; approval is still PENDING."
            exit 0
        }
        if ($p -match '(?i)\bapprov') {
            Write-Output "[LP-CRO] The message mentions approval but is not an unambiguous APPROVE. Approval was NOT recorded. If the user attached conditions, treat it as REVISE; otherwise ask them to reply exactly APPROVE."
            exit 0
        }
        Write-Output "[LP-CRO] Project '$slug' is WAITING_FOR_APPROVAL. Production stays locked until the user replies APPROVE."
        exit 0
    }

    if ($st.state -eq 'BLOCKED' -and $st.blocked.kind -eq 'MAX_ITERATIONS') {
        $mm = [regex]::Match($p, '^(?i)(/lp-extend|extend)(\s+(\d))?\s*$')
        if ($mm.Success) {
            $n = 1; if ($mm.Groups[3].Success) { $n = [int]$mm.Groups[3].Value }
            if ($n -lt 1) { $n = 1 }; if ($n -gt 3) { $n = 3 }
            $st.iteration.max = [int]$st.iteration.max + $n
            $st.history += [pscustomobject]@{ at = $now; from = 'BLOCKED'; to = 'BLOCKED'; reason = "user extended iteration cap by $n to $($st.iteration.max)" }
            Save-State $slug $st
            Write-Output "[LP-CRO] User extended the iteration cap to $($st.iteration.max). You may 'transition -To RESUME' and continue the iteration loop."
            exit 0
        }
    }
} catch {
    [Console]::Error.WriteLine("capture-decision hook error: $($_.Exception.Message)")
}
exit 0
