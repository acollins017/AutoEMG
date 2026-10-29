; =============================================================================
; Settings.ahk - personal preferences for AutoEMG.
; Edit the values on the right-hand side, save, then reload the script
; (right-click the tray icon > Reload, or press Ctrl+Alt+R).
; =============================================================================

Settings_Load() {
    global CFG
    CFG := {}

    ; ---- Hotkeys -------------------------------------------------------------
    CFG.HotkeyRun          := "^q"      ; analyze the open report and insert results
    CFG.HotkeyClipboard    := "^+q"     ; analyze text already on the clipboard (no Ctrl+A)
    CFG.HotkeyReload       := "^!r"     ; reload the script after editing settings

    ; ---- Output / insertion ----------------------------------------------------
    CFG.ShowPreview        := true      ; review/edit the draft before it is inserted
    ; "auto"      = Word COM if the active window is Microsoft Word, otherwise keystrokes
    ; "word"      = always use Word COM automation
    ; "keys"      = navigate with arrow keys and paste (works in most report editors)
    ; "clipboard" = only copy the text; you paste it yourself
    CFG.InsertMethod       := "auto"
    CFG.InsertImpression   := true      ; also insert the draft impression under "Impression:"
    CFG.KeepBlankLine      := true      ; keep the blank line between the inserted text and the next heading
    CFG.RestoreClipboard   := true      ; put your previous clipboard contents back afterwards
    CFG.NavBacktrack       := 4         ; keystroke mode: lines to back off before scanning
    CFG.NavMaxSteps        := 45        ; keystroke mode: max lines scanned looking for a heading
    CFG.KeyDelayMs         := 60        ; keystroke mode: pause between navigation steps

    ; ---- Reference values ------------------------------------------------------
    ; "AANEM"  = AANEM Normative Data Task Force values (Chen et al. 2016), with
    ;            Preston & Shapiro / Buschbacher values for nerves AANEM does not cover.
    ; "REPORT" = use the Ref. column printed in the report (machine normals) when present.
    CFG.NormalsSource      := "AANEM"
    CFG.UseReportRefAsFallback := true  ; for nerves without a built-in normal
    ; Sensory amplitude convention used by your machine: "OP" (baseline/onset-to-peak) or "PP"
    CFG.SensoryAmpMethod   := "OP"
    ; AANEM median/ulnar sensory amplitudes depend on BMI. Used when the report has no BMI:
    ; "high" (>=24, the more lenient cut-off), "low" (<24), or "all" (whole-sample value).
    CFG.DefaultBMIGroup    := "high"
    ; Scale sensory latency limits for recording distances that differ from the reference
    ; distance (e.g. 13 cm median, 11 cm ulnar). Strongly recommended.
    CFG.AdjustSensoryLatencyForDistance := true
    ; Values within this fraction of the cut-off are labelled "borderline" in the data view;
    ; a borderline focal slowing on its own is not reported as a mononeuropathy.
    CFG.BorderlineFraction := 0.05
    ; An otherwise unexplained nerve whose abnormal values are all within this fraction of
    ; the limit is listed as "borderline" in the impression instead of as a numbered finding.
    CFG.MinorFraction      := 0.10

    ; ---- Temperature -----------------------------------------------------------
    CFG.WarnTempUpperC     := 32        ; AANEM: >32 C upper limb
    CFG.WarnTempLowerC     := 31        ; AANEM: >31 C lower limb
    CFG.ApplyTempCorrection := false    ; correct latency/CV for cold limbs (warming is preferred)

    ; ---- Wording ---------------------------------------------------------------
    CFG.PeronealTerm       := "peroneal"   ; or "fibular"
    ; Chronicity label used when a radiculopathy shows BOTH reinnervation and active denervation:
    ; "chronic" -> "A chronic, left lumbosacral radiculopathy ..., with active denervation."
    ; "acute on chronic" -> "An acute on chronic, left lumbosacral radiculopathy ..."
    CFG.ChronicActiveTerm  := "chronic"
    CFG.NumberedListFormat := "{1}. "      ; {1} is replaced by the item number
    CFG.BlankLineBeforeEMG := false        ; blank line between the NCS and EMG paragraphs
    CFG.MarkIncidentalPolyneuropathy := true ; adds "; incidental finding" if not the referral question
    ; Report median/ulnar comparison studies in the summary: "always", "never", or
    ; "whenNeeded" (only when they are what makes the median abnormal).
    CFG.ReportComparisons  := "whenNeeded"

    ; ---- Diagnostic logic --------------------------------------------------------
    ; A completely absent median SNAP with a normal median CMAP grades CTS as "moderate".
    CFG.CTSAbsentSNAPGrade := "moderate"
    ; Score (0-8) at which distal, symmetric leg denervation is attributed to a polyneuropathy
    ; rather than to bilateral L5/S1 radiculopathies. See README for how it is computed.
    CFG.PolyneuropathyEMGThreshold := 4
    ; Minimum number of regions (bulbar/cervical/thoracic/lumbosacral) with active and chronic
    ; denervation before the motor neuron disease / polyradiculopathy statement is generated.
    CFG.MNDMinRegions      := 3
}
