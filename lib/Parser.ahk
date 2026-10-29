; =============================================================================
; Parser.ahk - turns the copied report text into structured data.
;
; Works on the plain text Word/most editors put on the clipboard: table cells are
; separated by tabs and table rows by line breaks. Tables are found by their header
; row, and columns are located by header NAME (not position), so differently
; configured machines / report templates still parse.
; =============================================================================

Parse_Report(text) {
    rep := {patient: {}, sensory: [], motor: [], fwave: [], hreflex: [], emg: [], warnings: [], notes: [], layout: {}}
    text := StrReplace(text, Chr(160), " ")
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    text := StrReplace(text, Chr(11), "`n")      ; Word manual line break
    lines := StrSplit(text, "`n")
    rep.lines := lines
    rep.text := text
    Parse_Patient(rep, text, lines)
    Parse_Layout(rep, lines)

    n := lines.Length()
    i := 1
    title := ""
    while (i <= n) {
        line := lines[i]
        t := Util_Trim(line)
        if (t = "") {
            i++
            continue
        }
        cells := Parse_Cells(line)
        kind := Parse_HeaderKind(cells, title)
        if (kind = "emg") {
            i := Parse_EMGTable(rep, lines, i)
            title := ""
            continue
        }
        if (kind != "") {
            i := Parse_NCSTable(rep, lines, i, kind)
            title := ""
            continue
        }
        if Parse_IsTitle(t)
            title := t
        i++
    }
    if (rep.sensory.Length() + rep.motor.Length() + rep.emg.Length() + rep.fwave.Length() + rep.hreflex.Length() = 0)
        rep.warnings.Push("No nerve conduction or EMG tables were recognised in the report text.")
    return rep
}

Parse_Cells(line) {
    out := []
    for i, c in StrSplit(line, "`t")
        out.Push(Util_Trim(c))
    ; drop trailing empty cells
    while (out.Length() > 0 && out[out.Length()] = "")
        out.Pop()
    return out
}

Parse_NonEmpty(cells) {
    n := 0
    for i, c in cells
        if (c != "")
            n++
    return n
}

Parse_FirstNonEmpty(cells) {
    for i, c in cells
        if (c != "")
            return c
    return ""
}

Parse_IsTitle(t) {
    return RegExMatch(t, "i)(nerve conduction|motor|sensory|f[\s\-]*wave|h[\s\-]*reflex|late response|emg|needle|mixed nerve|comparison|blink|repetitive)") && StrLen(t) < 80 && !InStr(t, "`t")
}

; Returns "", "sensory", "motor", "fwave", "hreflex" or "emg"
Parse_HeaderKind(cells, title) {
    if (cells.Length() < 3)
        return ""
    joined := " " . Util_Lower(Util_Join(cells, " | ")) . " "
    first := Util_Lower(cells[1])
    hasMuscle := false, hasEMGCol := false, hasLat := false, hasAmp := false, hasNerve := false
    hasF := false, hasH := false, hasRec := false
    for i, c in cells {
        lc := Util_Lower(c)
        if RegExMatch(lc, "^(muscle|muscles|muscle name)$")
            hasMuscle := true
        if RegExMatch(lc, "^(fib|fibs|fibrillation\w*|psw|pos\.? ?waves?|\+ ?waves?|fasc\w*)$")
            hasEMGCol := true
        if RegExMatch(lc, "(lat|latency)")
            hasLat := true
        if RegExMatch(lc, "amp")
            hasAmp := true
        if RegExMatch(lc, "^(nerve|nerve ?/ ?sites?|nerve ?/ ?site|nerves?|site|sites|stim site)$")
            hasNerve := true
        if RegExMatch(lc, "^(f[\s\-]*(lat|latency|min|mean|wave)\w*|min ?f|fmin|f[\s\-]?m)")
            hasF := true
        if RegExMatch(lc, "^h[\s\-]*(lat|latency|reflex|amp)")
            hasH := true
        if RegExMatch(lc, "^(rec\.? ?site|recording|rec)$")
            hasRec := true
    }
    lt := Util_Lower(title)
    if (hasMuscle && hasEMGCol && !hasNerve)
        return "emg"
    if (hasF || RegExMatch(lt, "f[\s\-]*wave"))
        return (hasLat || hasF) ? "fwave" : ""
    if (hasH || RegExMatch(lt, "h[\s\-]*reflex"))
        return (hasLat || hasH) ? "hreflex" : ""
    if !(hasLat && (hasAmp || hasNerve))
        return ""
    if !(hasNerve || first = "" || RegExMatch(lt, "(motor|sensory|nerve conduction|mixed)"))
        return ""
    if RegExMatch(lt, "sensory|mixed|antidromic|orthodromic")
        return "sensory"
    if RegExMatch(lt, "motor")
        return "motor"
    if (hasMuscle)
        return "motor"
    if (hasRec || InStr(joined, "peak"))
        return "sensory"
    return "motor"
}

Parse_IsUnitsRow(line) {
    return !RegExMatch(line, "\d") && RegExMatch(line, "i)(^|\t)\s*(ms|msec|mv|m/s)\s*(\t|$)")
}

Parse_IsSectionBreak(t) {
    if RegExMatch(t, "i)^(motor|sensory|f[\s\-]*wave|h[\s\-]*reflex|emg|needle|mixed|comparison|summary|impression|repetitive|blink)\b[^\t]*(study|studies|table|conduction|summary)?\s*$") && StrLen(t) < 60
        return true
    return false
}

; ---------------------------------------------------------------------------
; Nerve conduction / late response tables
; ---------------------------------------------------------------------------
Parse_MapNCSCols(cells) {
    cols := {site: 1}
    last := ""
    for idx, c in cells {
        lc := Util_Lower(Util_Trim(c))
        if (idx = 1 && !RegExMatch(lc, "lat|amp|^cv|veloc"))
            continue
        if RegExMatch(lc, "^(muscle|rec\.? ?site|recording( site)?|rec)$")
            cols.rec := idx, last := ""
        else if RegExMatch(lc, "(lat|peak)\.? ?(diff|difference)")
            cols.latDiff := idx, last := "latDiff"
        else if RegExMatch(lc, "^(f[\s\-]*(lat|latency|min|wave)\w*|min ?f\w*|fmin|f[\s\-]?min)")
            cols.flat := idx, last := "flat"
        else if RegExMatch(lc, "^(m[\s\-]*(lat|latency))")
            cols.mlat := idx, last := "mlat"
        else if RegExMatch(lc, "^h[\s\-]*(lat|latency)")
            cols.hlat := idx, last := "hlat"
        else if RegExMatch(lc, "^h[\s\-]*amp")
            cols.hamp := idx, last := "hamp"
        else if RegExMatch(lc, "^(persist\w*|f ?%|% ?f|f ?count|f ?pers\w*)")
            cols.persist := idx, last := ""
        else if (InStr(lc, "onset") && InStr(lc, "lat"))
            cols.onset := idx, last := "onset"
        else if ((InStr(lc, "peak") && InStr(lc, "lat")) || RegExMatch(lc, "^latency \(peak\)"))
            cols.peak := idx, last := "peak"
        else if RegExMatch(lc, "^(lat|latency|lat\.|dl|distal lat\w*|onset)$") || RegExMatch(lc, "^(lat|latency) ")
            cols.lat := idx, last := "lat"
        else if RegExMatch(lc, "^(ref|ref\.|norm|normal|nl|ll|ul)")
        {
            if (last != "")
                cols[last . "Ref"] := idx
        }
        else if (InStr(lc, "rel") && InStr(lc, "amp"))
            cols.relAmp := idx, last := ""
        else if InStr(lc, "amp")
        {
            cols.amp := idx, last := "amp"
            if RegExMatch(lc, "p-p|\bpp\b|peak.?to.?peak|peak-peak")
                cols.ampMethod := "PP"
            else if RegExMatch(lc, "o-p|\bnp\b|b-p|base|onset")
                cols.ampMethod := "OP"
        }
        else if RegExMatch(lc, "^(dur|dur\.|duration|neg\.? ?dur\w*)")
            cols.dur := idx, last := "dur"
        else if RegExMatch(lc, "^segment")
            cols.seg := idx, last := ""
        else if RegExMatch(lc, "^(distance|dist|dist\.)")
            cols.dist := idx, last := ""
        else if RegExMatch(lc, "^(cv|ncv|velocity|vel|vel\.|cond\.? ?vel\w*|conduction velocity)")
            cols.cv := idx, last := "cv"
        else if RegExMatch(lc, "^temp")
            cols.temp := idx, last := ""
        else if RegExMatch(lc, "^area")
            cols.area := idx, last := ""
    }
    return cols
}

Parse_Cell(cells, idx) {
    if (idx = "" || idx < 1 || idx > cells.Length())
        return ""
    return cells[idx]
}

Parse_NCSRow(cells, cols) {
    r := {}
    r.site := Parse_Cell(cells, cols.site)
    r.rec := Parse_Cell(cells, cols.rec)
    for i, f in ["lat", "onset", "peak", "amp", "cv", "dur", "flat", "mlat", "hlat", "hamp", "latDiff", "persist", "area", "relAmp", "temp", "dist"] {
        raw := Parse_Cell(cells, cols[f])
        r[f . "Raw"] := raw
        r[f] := Util_IsNR(raw) ? "" : Util_Num(raw)
        r[f . "NR"] := Util_IsNR(raw)
        if cols.HasKey(f . "Ref")
            r[f . "Ref"] := Util_Num(Parse_Cell(cells, cols[f . "Ref"]))
    }
    r.seg := Parse_Cell(cells, cols.seg)
    r.nr := r.latNR || r.ampNR || r.onsetNR || r.peakNR || r.flatNR || r.hlatNR
    r.any := (r.lat != "" || r.onset != "" || r.peak != "" || r.amp != "" || r.cv != "" || r.flat != "" || r.hlat != "" || r.nr)
    if (r.dist != "")
        r.distCm := (r.dist > 30) ? r.dist / 10 : r.dist
    else
        r.distCm := ""
    return r
}

Parse_NewStudy(kind, heading) {
    id := Anat_IdentifyNerve(heading, kind)
    st := {kind: kind, side: id.side, nerve: id.nerve, key: id.key, rec: id.rec, label: id.label, rows: []}
    return st
}

Parse_NCSTable(rep, lines, i, kind) {
    hdr := Parse_Cells(lines[i])
    cols := Parse_MapNCSCols(hdr)
    if (kind = "fwave" && !cols.HasKey("flat")) {
        if cols.HasKey("lat")
            cols.flat := cols.lat
        else if cols.HasKey("onset")
            cols.flat := cols.onset
    }
    if (kind = "hreflex" && !cols.HasKey("hlat")) {
        if cols.HasKey("lat")
            cols.hlat := cols.lat
        else if cols.HasKey("onset")
            cols.hlat := cols.onset
    }
    list := rep[kind]
    st := ""
    n := lines.Length()
    i++
    while (i <= n) {
        raw := lines[i]
        t := Util_Trim(raw)
        if !RegExMatch(t, "[A-Za-z0-9]")
            break
        if Parse_IsUnitsRow(raw) {
            i++
            continue
        }
        cells := Parse_Cells(raw)
        if Parse_IsSectionBreak(t) || (Parse_HeaderKind(cells, "") != "")
            break
        ne := Parse_NonEmpty(cells)
        if (ne <= 1) {
            only := Parse_FirstNonEmpty(cells)
            ; An indented or site-named row with no data (site not tested) is not a heading.
            if (IsObject(st) && (RegExMatch(raw, "^\s") || Anat_IdentifyNerve(only, kind).nerve = "")) {
                i++
                continue
            }
            ; Nerve heading row, e.g. "R Median - APB"
            st := Parse_NewStudy(kind, only)
            list.Push(st)
        } else {
            row := Parse_NCSRow(cells, cols)
            if (kind = "sensory" && cols.ampMethod != "")
                row.ampMethod := cols.ampMethod
            ; Formats that put the nerve and the data on one row (common for F-waves)
            first := Parse_Cell(cells, 1)
            id := Anat_IdentifyNerve(first, kind)
            leading := RegExMatch(raw, "^\s")
            if (!IsObject(st) || (!leading && id.nerve != "" && (id.side != "" || kind = "fwave" || kind = "hreflex"))) {
                st := Parse_NewStudy(kind, first)
                list.Push(st)
            }
            if (row.any)
                st.rows.Push(row)
        }
        i++
    }
    ; discard headings that never received data
    k := list.Length()
    while (k >= 1) {
        if (list[k].rows.Length() = 0)
            list.RemoveAt(k)
        k--
    }
    return i
}

; ---------------------------------------------------------------------------
; Needle EMG table
; ---------------------------------------------------------------------------
Parse_MapEMGCols(cells) {
    cols := {}
    for idx, c in cells {
        lc := Util_Lower(Util_Trim(c))
        if RegExMatch(lc, "^(muscle|muscles|muscle name)$")
            cols.muscle := idx
        else if RegExMatch(lc, "^side$")
            cols.side := idx
        else if RegExMatch(lc, "^(ia|ins|ins\.|ins\.? ?act\.?|insert\w*|act|act\.|ins act|insertion\w*)$")
            cols.ia := idx
        else if RegExMatch(lc, "^(fib|fibs|fibrillation\w*)$")
            cols.fib := idx
        else if RegExMatch(lc, "^(psw|psws|pos\.? ?waves?|\+ ?waves?|sharp waves?|positive sharp waves?)$")
            cols.psw := idx
        else if RegExMatch(lc, "^fasc")
            cols.fasc := idx
        else if RegExMatch(lc, "^(other|crd|myoton\w*|spont\w* other)")
            cols.other := idx
        else if RegExMatch(lc, "^(effort|eff\.?|activation)")
            cols.effort := idx
        else if RegExMatch(lc, "^(recruit\w*|recr\.?|pattern|recr\.? pattern|int\.? pattern|interference)")
            cols.recruit := idx
        else if RegExMatch(lc, "^(rate|firing\w*|fr)$")
            cols.rate := idx
        else if RegExMatch(lc, "^(amp|amp\.|amplitude|muap amp|mup amp)")
            cols.amp := idx
        else if RegExMatch(lc, "^(dur|dur\.|duration)")
            cols.dur := idx
        else if RegExMatch(lc, "^(ppp|poly|polys|polyphas\w*|phases|% ?poly)")
            cols.poly := idx
    }
    if !cols.HasKey("muscle")
        cols.muscle := 1
    return cols
}

Parse_EMGTable(rep, lines, i) {
    cols := Parse_MapEMGCols(Parse_Cells(lines[i]))
    n := lines.Length()
    i++
    while (i <= n) {
        raw := lines[i]
        t := Util_Trim(raw)
        if !RegExMatch(t, "[A-Za-z0-9]")
            break
        cells := Parse_Cells(raw)
        if (Parse_IsSectionBreak(t) || Parse_HeaderKind(cells, "") != "")
            break
        name := Parse_Cell(cells, cols.muscle)
        if (name = "" || Parse_NonEmpty(cells) < 2 && !RegExMatch(name, "i)paraspinal")) {
            i++
            continue
        }
        m := {raw: name}
        for f in {ia: 1, fib: 1, psw: 1, fasc: 1, other: 1, effort: 1, recruit: 1, rate: 1, amp: 1, dur: 1, poly: 1}
            m[f] := Parse_Cell(cells, cols[f])
        sideCell := Parse_Cell(cells, cols.side)
        sp := Anat_SplitSide(name)
        m.side := (sideCell != "") ? Anat_SideFromCell(sideCell) : sp.side
        m.name := sp.name
        rep.emg.Push(m)
        i++
    }
    return i
}

; ---------------------------------------------------------------------------
; Patient demographics, history and indication
; ---------------------------------------------------------------------------
Parse_Patient(rep, text, lines) {
    pt := {age: "", sex: "", heightCm: "", weightKg: "", bmi: "", name: "", indication: "", history: ""}
    if RegExMatch(text, "Oi)Full Name:\s*([^\t\n]+)", m)
        pt.name := Util_Trim(m.Value(1))
    else if RegExMatch(text, "Oi)(?:Patient(?: Name)?|Name):\s*([^\t\n]+)", m)
        pt.name := Util_Trim(m.Value(1))
    if RegExMatch(text, "Oi)\bAge:\s*(\d{1,3})", m)
        pt.age := m.Value(1) + 0
    if (pt.age = "") {
        dob := "", vis := ""
        if RegExMatch(text, "Oi)(?:Date of Birth|DOB):\s*(\d{1,2})/(\d{1,2})/(\d{2,4})", d)
            dob := d
        if RegExMatch(text, "Oi)(?:Visit Date|Test Date|Date of Study|Exam Date):\s*(\d{1,2})/(\d{1,2})/(\d{2,4})", v)
            vis := v
        if IsObject(dob) {
            ty := IsObject(vis) ? vis.Value(3) + 0 : A_YYYY + 0
            tm := IsObject(vis) ? vis.Value(1) + 0 : A_MM + 0
            td := IsObject(vis) ? vis.Value(2) + 0 : A_DD + 0
            by := dob.Value(3) + 0
            if (by < 100)
                by += (by > Mod(A_YYYY, 100)) ? 1900 : 2000
            age := ty - by
            if (tm < dob.Value(1) + 0 || (tm = dob.Value(1) + 0 && td < dob.Value(2) + 0))
                age--
            pt.age := age
            rep.notes.Push("Age calculated from date of birth: " . age . ".")
        }
    }
    if RegExMatch(text, "Oi)\b(?:Gender|Sex):\s*(Male|Female|M|F)\b", m)
        pt.sex := SubStr(Util_Upper(m.Value(1)), 1, 1)
    if RegExMatch(text, "Oi)\bHeight:\s*(\d)\s*'\s*(\d{1,2})", m)
        pt.heightCm := Round((m.Value(1) * 12 + m.Value(2)) * 2.54)
    else if RegExMatch(text, "Oi)\bHeight:\s*([\d\.]+)\s*(cm|in|inches|"")?", m) {
        h := m.Value(1) + 0
        pt.heightCm := (m.Value(2) = "cm" || h > 100) ? Round(h) : Round(h * 2.54)
    }
    if RegExMatch(text, "Oi)\bWeight:\s*([\d\.]+)\s*(kg|lb|lbs)?", m) {
        w := m.Value(1) + 0
        pt.weightKg := (m.Value(2) = "kg") ? w : w * 0.4536
    }
    if RegExMatch(text, "Oi)\bBMI:\s*([\d\.]+)", m)
        pt.bmi := m.Value(1) + 0
    else if (pt.heightCm != "" && pt.weightKg != "")
        pt.bmi := pt.weightKg / ((pt.heightCm / 100) ** 2)

    ; History: text between "History..." and "Summary:"
    hist := ""
    capture := false
    for i, line in lines {
        t := Util_Trim(line)
        if RegExMatch(t, "Oi)^(History(?: and (?:Exam|Physical))?|HPI|Indication|Reason for (?:Study|Referral))\s*:\s*(.*)$", m) {
            capture := true
            hist .= m.Value(2) . " "
            continue
        }
        if (capture) {
            if RegExMatch(t, "i)^(Summary|Impression|Findings|Results)\s*:")
                break
            hist .= t . " "
        }
    }
    pt.history := Util_Trim(RegExReplace(hist, "\s+", " "))
    if RegExMatch(pt.history, "Oi)(?:EDX|EMG\s*/?\s*NCS|NCS\s*/?\s*EMG|EMG|NCS|electrodiagnostic\s+\w+|study|testing)\s+(?:is|was|are|were)?\s*(?:being\s+)?performed\s+(?:for|to)\s+(?:the\s+)?(?:further\s+)?(?:evaluat\w*|assess\w*|eval\.?|rule out|r/o)\s*(?:of|for)?\s*([^\.\n]+)", m)
        pt.indication := Util_Trim(m.Value(1))
    else if RegExMatch(pt.history, "Oi)(?:to (?:evaluate|assess|rule out) (?:for )?)([^\.\n]+)", m)
        pt.indication := Util_Trim(m.Value(1))
    if RegExMatch(pt.indication, "^[_\s\?]*$")
        pt.indication := ""
    if (pt.sex = "") {
        h := " " . pt.history . " "
        if RegExMatch(h, "\bMr\.?\s") || RegExMatch(h, "i)\b(man|male|gentleman|boy)\b")
            pt.sex := "M"
        else if RegExMatch(h, "\b(Ms|Mrs|Miss)\.?\s") || RegExMatch(h, "i)\b(woman|female|lady|girl)\b")
            pt.sex := "F"
    }
    rep.patient := pt
    if (pt.age = "")
        rep.warnings.Push("Age not found - age-adjusted normal values could not be applied; whole-sample AANEM values were used.")
    if (pt.sex = "")
        rep.notes.Push("Sex not found - sex-specific median motor limits were not applied.")
}

Parse_Layout(rep, lines) {
    lay := {summary: 0, impression: 0, summaryHasText: false, impressionHasText: false}
    for i, line in lines {
        t := Util_Trim(line)
        if (!lay.summary && RegExMatch(t, "i)^Summary\s*:\s*$"))
            lay.summary := i
        else if (!lay.impression && RegExMatch(t, "i)^(Impression|Diagnostic Interpretation|Interpretation)\s*:\s*$"))
            lay.impression := i
    }
    if (lay.summary && lay.summary < lines.Length())
        lay.summaryHasText := (Util_Trim(lines[lay.summary + 1]) != "" && !RegExMatch(lines[lay.summary + 1], "i)^\s*Impression\s*:"))
    if (lay.impression && lay.impression < lines.Length())
        lay.impressionHasText := (Util_Trim(lines[lay.impression + 1]) != "" && !RegExMatch(lines[lay.impression + 1], "^\s*_{5,}"))
    rep.layout := lay
}
