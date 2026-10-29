; =============================================================================
; Engine.ahk - one entry point: report text in, draft summary/impression out.
; Pure (no GUI, no keystrokes) so it can be tested headlessly.
; =============================================================================

AutoEMG_Analyze(text) {
    Anat_Init()
    rep := Parse_Report(text)
    Assess_All(rep)
    res := {rep: rep}
    res.summary := Assess_Summary(rep)
    res.impression := Imp_Build(rep)
    res.checks := AutoEMG_CollectChecks(rep)
    return res
}

AutoEMG_CollectChecks(rep) {
    out := []
    for k, kind in ["sensory", "motor", "fwave", "hreflex"]
        for i, st in rep[kind]
            for j, c in st.checks
                out.Push(c)
    for i, c in rep.comparisonChecks
        out.Push(c)
    return out
}

AutoEMG_CheckLine(c) {
    if (c.value = "NR")
        res := c.abnormal ? "ABNORMAL" : "not graded"
    else if (c.limit = "")
        res := "no reference"
    else if (c.abnormal)
        res := c.borderline ? "BORDERLINE" : "ABNORMAL"
    else
        res := "normal"
    lim := (c.limit = "") ? "" : ((c.dir = "max") ? "<= " : ">= ") . Util_Fmt(c.limit) . " " . c.unit
    val := (c.value = "NR") ? "NR" : (c.value = "") ? "-" : Util_Fmt(c.value) . " " . c.unit
    return {study: c.study, label: c.label, value: val, limit: lim, src: c.src, result: res, note: c.note}
}

AutoEMG_PatientLine(rep) {
    global CFG
    pt := rep.patient
    s := "Age: " . (pt.age != "" ? pt.age : "?") . "   Sex: " . (pt.sex != "" ? pt.sex : "?")
    if (pt.heightCm != "")
        s .= "   Height: " . pt.heightCm . " cm"
    s .= "   BMI group: " . (pt.bmi != "" ? Util_Round(pt.bmi, 1) : "unknown (using " . CFG.DefaultBMIGroup . ")")
    s .= "   Normals: " . CFG.NormalsSource
    if (pt.indication != "")
        s .= "   Indication: " . pt.indication
    return s
}

AutoEMG_NotesText(res) {
    rep := res.rep
    t := AutoEMG_PatientLine(rep) . "`r`n"
    t .= "Studies parsed: " . rep.sensory.Length() . " sensory, " . rep.motor.Length() . " motor, " . rep.fwave.Length() . " F-wave, " . rep.hreflex.Length() . " H-reflex, " . rep.emg.Length() . " muscles.`r`n"
    if (rep.warnings.Length() > 0) {
        t .= "`r`nWARNINGS`r`n"
        for i, w in rep.warnings
            t .= "  * " . w . "`r`n"
    }
    if (rep.notes.Length() > 0) {
        t .= "`r`nNOTES`r`n"
        for i, w in rep.notes
            t .= "  - " . w . "`r`n"
    }
    expl := ""
    for k, kind in ["sensory", "motor", "fwave", "hreflex"]
        for i, st in rep[kind]
            if (st.abnormal || (IsObject(st.flags) && st.flags.any))
                expl .= "  " . st.name . (kind = "fwave" ? " F-wave" : kind = "hreflex" ? " H-reflex" : "") . " -> " . (st.explained != "" ? st.explained : "unexplained") . "`r`n"
    for i, m in rep.emg
        if (m.abnormal)
            expl .= "  " . m.display . " -> " . (m.explained != "" ? m.explained : "unexplained") . "`r`n"
    if (expl != "")
        t .= "`r`nABNORMALITIES ATTRIBUTED TO`r`n" . expl
    return t
}

; Plain-text dump used by the test harness and the "Copy data" button.
AutoEMG_FormatResult(res) {
    t := "=== SUMMARY ===`r`n" . res.summary . "`r`n`r`n=== IMPRESSION ===`r`n" . res.impression . "`r`n`r`n=== NOTES ===`r`n" . AutoEMG_NotesText(res)
    t .= "`r`n=== MEASUREMENTS ===`r`n"
    for i, c in res.checks {
        L := AutoEMG_CheckLine(c)
        t .= Util_PadRight(L.result, 12) . Util_PadRight(L.study, 44) . Util_PadRight(L.label, 50) . Util_PadRight(L.value, 12) . Util_PadRight(L.limit, 14) . L.src . (L.note != "" ? "  [" . L.note . "]" : "") . "`r`n"
    }
    return t
}
