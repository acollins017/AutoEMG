; =============================================================================
; Assess.ahk - compares every parsed value with its reference limit, interprets
; the needle EMG grades, and writes the Summary paragraph(s).
; =============================================================================

Assess_All(rep) {
    pt := rep.patient
    for i, st in rep.sensory
        Assess_Sensory(rep, st, pt)
    for i, st in rep.motor
        Assess_Motor(rep, st, pt)
    for i, st in rep.fwave
        Assess_Late(rep, st, "fwave")
    for i, st in rep.hreflex
        Assess_Late(rep, st, "hreflex")
    Assess_LateSideDiff(rep, rep.fwave, "fwave")
    Assess_LateSideDiff(rep, rep.hreflex, "hreflex")
    Assess_Comparisons(rep, pt)
    for i, m in rep.emg
        Assess_Muscle(rep, m)
    Assess_Temperature(rep)
    if (pt.age != "" && (pt.age < 19 || pt.age > 79))
        rep.warnings.Push("Age " . pt.age . " is outside the AANEM reference population (19-79 years); the nearest age group was used.")
}

Assess_Limb(nerve) {
    static upper := {median: 1, ulnar: 1, radial: 1, labc: 1, mabc: 1, duc: 1, musculocutaneous: 1, axillary: 1, suprascapular: 1, accessory: 1, phrenic: 1}
    static lower := {sural: 1, superficialPeroneal: 1, saphenous: 1, peroneal: 1, tibial: 1, femoral: 1, medialPlantar: 1, lateralPlantar: 1}
    if upper.HasKey(nerve)
        return "upper"
    if lower.HasKey(nerve)
        return "lower"
    return ""
}

Assess_Check(st, label, value, limit, dir, unit, src, note := "") {
    global CFG
    c := {study: st.name, label: label, value: value, limit: limit, dir: dir, unit: unit, src: src, note: note, abnormal: false, borderline: false}
    if (value != "" && limit != "") {
        c.abnormal := (dir = "max") ? (value > limit) : (value < limit)
        if (c.abnormal && limit != 0)
            c.borderline := (Abs(value - limit) / limit) <= CFG.BorderlineFraction
    }
    st.checks.Push(c)
    return c
}

Assess_CheckNR(st, label) {
    c := {study: st.name, label: label, value: "NR", limit: "", dir: "", unit: "", src: "", note: "no response", abnormal: true, borderline: false}
    st.checks.Push(c)
    return c
}

; Optional cold-limb correction (Preston & Shapiro: ~0.2 ms and ~2 m/s per degree C).
Assess_TempDelta(row, limb) {
    global CFG
    if (!CFG.ApplyTempCorrection || row.temp = "")
        return 0
    thr := (limb = "lower") ? CFG.WarnTempLowerC : CFG.WarnTempUpperC
    return (row.temp < thr) ? (thr - row.temp) : 0
}

; ---------------------------------------------------------------------------
; Sensory
; ---------------------------------------------------------------------------
Assess_Sensory(rep, st, pt) {
    global CFG
    st.name := Anat_NerveDisplay(st)
    st.limb := Assess_Limb(st.nerve)
    st.checks := []
    st.extra := []
    norm := Norm_Sensory(st.key, pt)
    st.norm := norm
    if (!norm.HasKey("src") && !(CFG.UseReportRefAsFallback || CFG.NormalsSource = "REPORT"))
        rep.notes.Push("No reference values for " . st.name . "; it was not graded.")
    for idx, row in st.rows {
        rnorm := norm
        site := Anat_CanonSite(row.site)
        if (idx > 1 && site = "palm" && st.nerve = "median")
            rnorm := Norm_Sensory("medianPalm", pt)
        f := Assess_SensoryRow(rep, st, row, rnorm, pt, idx = 1 ? "" : row.site)
        if (idx = 1)
            st.flags := f
        else if (f.any)
            st.extra.Push({site: row.site, flags: f})
    }
    if !IsObject(st.flags)
        st.flags := {any: false}
    st.abnormal := st.flags.any || st.extra.Length() > 0
}

Assess_SensoryRow(rep, st, row, norm, pt, siteLabel) {
    global CFG
    f := {nr: false, lat: false, amp: false, cv: false, any: false, latRatio: "", ampRatio: "", cvRatio: "", borderline: true, latVal: "", ampVal: "", cvVal: ""}
    useReport := (CFG.NormalsSource = "REPORT")
    allowRef := useReport || CFG.UseReportRefAsFallback
    pre := (siteLabel != "") ? siteLabel . " " : ""
    src := norm.src
    if (row.peak != "" || row.peakNR)
        latType := "peak", latVal := row.peak, latRef := row.peakRef
    else if (row.onset != "" || row.onsetNR)
        latType := "onset", latVal := row.onset, latRef := row.onsetRef
    else
        latType := "peak", latVal := row.lat, latRef := row.latRef
    if (row.nr || (latVal = "" && row.amp = "" && (row.latNR || row.peakNR || row.onsetNR || row.ampNR))) {
        f.nr := true, f.any := true, f.borderline := false
        Assess_CheckNR(st, pre . "Response")
        return f
    }
    dT := Assess_TempDelta(row, st.limb)
    ; ---- latency
    latULN := useReport ? "" : norm[latType]
    latSrc := src, latNote := ""
    if (latULN = "" && latRef != "" && allowRef)
        latULN := latRef, latSrc := "report Ref."
    else if (latULN != "" && CFG.AdjustSensoryLatencyForDistance && row.distCm != "" && norm.dist != "" && Abs(row.distCm - norm.dist) >= 0.5) {
        latNote := Util_Fmt(latULN) . " ms at " . norm.dist . " cm, scaled to " . Util_Fmt(row.distCm) . " cm"
        latULN := Round(latULN * row.distCm / norm.dist, 2)
    }
    if (latVal != "" && dT > 0)
        latVal := Round(latVal - 0.2 * dT, 2), latNote .= (latNote != "" ? "; " : "") . "temp-corrected"
    c := Assess_Check(st, pre . (latType = "peak" ? "Peak latency" : "Onset latency"), latVal, latULN, "max", "ms", latSrc, latNote)
    f.lat := c.abnormal, f.latVal := latVal
    if (latVal != "" && latULN != "")
        f.latRatio := latVal / latULN
    if (c.abnormal && !c.borderline)
        f.borderline := false
    ; ---- amplitude
    ampLLN := useReport ? "" : norm.amp
    ampSrc := src, ampNote := norm.note
    if (ampLLN = "" && row.ampRef != "" && allowRef)
        ampLLN := row.ampRef, ampSrc := "report Ref.", ampNote := ""
    c := Assess_Check(st, pre . "Amplitude", row.amp, ampLLN, "min", "uV", ampSrc, ampNote)
    f.amp := c.abnormal, f.ampVal := row.amp
    if (row.amp != "" && ampLLN != "")
        f.ampRatio := row.amp / ampLLN
    if (c.abnormal && !c.borderline)
        f.borderline := false
    ; ---- conduction velocity
    cv := row.cv
    if (cv != "" && dT > 0)
        cv := Round(cv + 2.0 * dT, 1)
    cvLLN := useReport ? "" : norm.cv
    cvSrc := src
    if (cvLLN = "" && row.cvRef != "" && allowRef)
        cvLLN := row.cvRef, cvSrc := "report Ref."
    c := Assess_Check(st, pre . "Conduction velocity", cv, cvLLN, "min", "m/s", cvSrc)
    f.cv := c.abnormal, f.cvVal := cv
    if (cv != "" && cvLLN != "")
        f.cvRatio := cv / cvLLN
    if (c.abnormal && !c.borderline)
        f.borderline := false
    f.any := f.lat || f.amp || f.cv
    if (!f.any)
        f.borderline := false
    ; slowing pattern used later (demyelinating range: <75% LLN CV or >130% ULN latency)
    f.demy := (f.cvRatio != "" && f.cvRatio < 0.75) || (f.latRatio != "" && f.latRatio > 1.3)
    f.slow := f.lat || f.cv
    return f
}

Assess_SensoryPhrase(st) {
    f := st.flags
    out := ""
    if (f.nr)
        out := "The " . st.name . " showed no response."
    else if (f.any) {
        items := []
        if (f.lat)
            items.Push("prolonged latency")
        if (f.amp)
            items.Push("low amplitude")
        if (f.cv)
            items.Push("slow conduction velocity")
        items[1] := "a " . items[1]
        out := "The " . st.name . " showed " . Util_JoinList(items) . "."
    }
    for i, e in st.extra {
        if (e.flags.nr)
            out .= (out != "" ? " " : "") . Util_CapFirst(Util_Lower(e.site)) . " stimulation of the " . st.name . " showed no response."
        else {
            items := []
            if (e.flags.lat)
                items.Push("prolonged latency")
            if (e.flags.amp)
                items.Push("low amplitude")
            if (e.flags.cv)
                items.Push("slow conduction velocity")
            items[1] := "a " . items[1]
            out .= (out != "" ? " " : "") . Util_CapFirst(Util_Lower(e.site)) . " stimulation of the " . st.name . " showed " . Util_JoinList(items) . "."
        }
    }
    return out
}

; ---------------------------------------------------------------------------
; Motor
; ---------------------------------------------------------------------------
Assess_Motor(rep, st, pt) {
    global CFG
    st.name := Anat_NerveDisplay(st)
    st.limb := Assess_Limb(st.nerve)
    st.checks := []
    norm := Norm_Motor(st.key, pt)
    st.norm := norm
    useReport := (CFG.NormalsSource = "REPORT")
    allowRef := useReport || CFG.UseReportRefAsFallback
    f := {nr: false, lat: false, amp: false, any: false, latRatio: "", ampRatio: "", segs: [], borderline: true, latVal: "", ampVal: ""}
    st.flags := f
    if (st.rows.Length() = 0)
        return
    d := st.rows[1]
    if (d.latNR || d.ampNR || (d.lat = "" && d.amp = "" && d.nr)) {
        f.nr := true, f.any := true, f.borderline := false
        Assess_CheckNR(st, "Distal response (" . d.site . ")")
        st.abnormal := true
        return
    }
    dT := Assess_TempDelta(d, st.limb)
    ; ---- distal latency
    latULN := useReport ? "" : norm.lat
    latSrc := norm.src, latNote := ""
    if (latULN = "" && d.latRef != "" && allowRef)
        latULN := d.latRef, latSrc := "report Ref."
    else if (latULN != "" && d.distCm != "" && norm.dist != "" && Abs(d.distCm - norm.dist) >= 1)
        latNote := "reference distance " . norm.dist . " cm; study " . Util_Fmt(d.distCm) . " cm"
    lat := d.lat
    if (lat != "" && dT > 0)
        lat := Round(lat - 0.2 * dT, 2), latNote .= (latNote != "" ? "; " : "") . "temp-corrected"
    c := Assess_Check(st, "Distal latency (" . d.site . ")", lat, latULN, "max", "ms", latSrc, latNote)
    f.lat := c.abnormal, f.latVal := lat
    if (lat != "" && latULN != "")
        f.latRatio := lat / latULN
    if (c.abnormal && !c.borderline)
        f.borderline := false
    ; ---- distal amplitude
    ampLLN := useReport ? "" : norm.amp
    ampSrc := norm.src
    if (ampLLN = "" && d.ampRef != "" && allowRef)
        ampLLN := d.ampRef, ampSrc := "report Ref."
    c := Assess_Check(st, "Amplitude (" . d.site . ")", d.amp, ampLLN, "min", "mV", ampSrc)
    f.amp := c.abnormal, f.ampVal := d.amp
    if (d.amp != "" && ampLLN != "")
        f.ampRatio := d.amp / ampLLN
    if (c.abnormal && !c.borderline)
        f.borderline := false
    ; ---- proximal segments
    prev := d
    segByType := {}
    Loop, % st.rows.Length() - 1 {
        row := st.rows[A_Index + 1]
        prox := row.site, dist := prev.site
        if RegExMatch(row.seg, "O)^(.*?)\s+-\s+(.*)$", sm)
            prox := sm.Value(1), dist := sm.Value(2)
        info := Anat_SegmentInfo(st.key, dist, prox)
        seg := {type: info.type, region: info.region, site: row.site, cv: "", slow: false, cb: false, td: false, nrProx: false, relSlow: false, borderline: false, drop: ""}
        if (row.latNR || row.ampNR) {
            seg.nrProx := true
            Assess_CheckNR(st, "Response at " . row.site)
            f.segs.Push(seg)
            prev := row
            continue
        }
        cv := row.cv
        dTs := Assess_TempDelta(row, st.limb)
        if (cv != "" && dTs > 0)
            cv := Round(cv + 2.0 * dTs, 1)
        cvLLN := (useReport || !norm.HasKey("src")) ? "" : Norm_SegCV(norm, info.type)
        cvSrc := norm.src
        if (cvLLN = "" && row.cvRef != "" && allowRef)
            cvLLN := row.cvRef, cvSrc := "report Ref."
        c := Assess_Check(st, "CV " . info.region, cv, cvLLN, "min", "m/s", cvSrc)
        seg.cv := cv, seg.cvLLN := cvLLN, seg.slow := c.abnormal, seg.borderline := c.borderline
        if (cv != "" && cvLLN != "")
            seg.cvRatio := cv / cvLLN
        ; ---- conduction block / temporal dispersion
        if (prev.amp != "" && prev.amp > 0 && row.amp != "") {
            drop := (prev.amp - row.amp) / prev.amp * 100
            seg.drop := drop
            thr := Norm_SegCB(norm, info.type)
            note := ""
            if (prev.dur != "" && row.dur != "" && prev.dur > 0)
                seg.durInc := (row.dur - prev.dur) / prev.dur * 100, note := "duration change " . Util_Round(seg.durInc, 0) . "%"
            c := Assess_Check(st, "Amplitude drop " . info.region, Round(drop, 1), thr, "max", "%", (norm.HasKey("src") ? norm.src : "default"), note)
            if (c.abnormal) {
                if (seg.durInc != "" && seg.durInc > 30)
                    seg.td := true
                else
                    seg.cb := true
            }
        }
        segByType[info.type] := seg
        f.segs.Push(seg)
        prev := row
    }
    ; ---- relative focal slowing (ulnar across elbow, peroneal across fibular head)
    if (norm.HasKey("focalSeg") && segByType.HasKey(norm.focalSeg) && segByType.HasKey(norm.focalRef)) {
        fs := segByType[norm.focalSeg], rs := segByType[norm.focalRef]
        fs.refSlow := rs.slow
        if (fs.cv != "" && rs.cv != "" && rs.cv > 0) {
            dropAbs := rs.cv - fs.cv
            dropPct := dropAbs / rs.cv * 100
            c := Assess_Check(st, "CV drop " . fs.region, Round(dropAbs, 1), norm.cvDropAbs, "max", "m/s", norm.src, Util_Round(dropPct, 0) . "% (limit " . norm.cvDropPct . "%)")
            if (dropAbs > norm.cvDropAbs && dropPct > norm.cvDropPct) {
                fs.relSlow := true
                if (!fs.slow)
                    fs.borderline := false
            } else
                c.abnormal := false
        }
    }
    anySeg := false
    for i, s in f.segs {
        if (s.slow || s.cb || s.td || s.nrProx || s.relSlow)
            anySeg := true
        if ((s.slow && !s.borderline) || s.cb || s.td || s.nrProx || (s.relSlow && !s.slow))
            f.borderline := false
    }
    f.anySeg := anySeg
    f.any := f.lat || f.amp || anySeg
    if (!f.any)
        f.borderline := false
    f.demy := (f.latRatio != "" && f.latRatio > 1.3)
    for i, s in f.segs
        if ((s.cvRatio != "" && s.cvRatio < 0.75) || s.cb || s.td)
            f.demy := true
    st.abnormal := f.any
}

Assess_SitePhrase(site) {
    c := Anat_CanonSite(site)
    m := {belbow: "below the elbow", aelbow: "above the elbow", bfh: "below the fibular head", afh: "above the fibular head"
        , knee: "at the popliteal fossa", axilla: "at the axilla", erb: "at Erb's point", elbow: "at the elbow", wrist: "at the wrist"
        , ankle: "at the ankle", palm: "at the palm", forearm: "at the forearm", sg: "at the spiral groove", asg: "above the spiral groove", bsg: "below the spiral groove"}
    return m.HasKey(c) ? m[c] : "at the " . Util_Lower(site)
}

Assess_MotorPhrase(st) {
    f := st.flags
    if (f.nr)
        return "The " . st.name . " showed no response."
    if (!f.any)
        return ""
    items := []
    if (f.lat)
        items.Push("prolonged latency")
    if (f.amp)
        items.Push("low amplitude")
    slowRegions := [], relRegions := [], nCV := 0
    for i, s in f.segs {
        if (s.cv != "")
            nCV++
        if (s.slow)
            slowRegions.Push(s.region)
        else if (s.relSlow)
            relRegions.Push(s.region)
    }
    if (slowRegions.Length() > 0) {
        if (slowRegions.Length() = nCV && nCV > 1)
            items.Push("slowed conduction velocity")
        else
            items.Push("slowed conduction velocity " . Util_JoinList(slowRegions))
    }
    if (relRegions.Length() > 0)
        items.Push("relative slowing of conduction velocity " . Util_JoinList(relRegions))
    for i, s in f.segs {
        if (s.cb)
            items.Push("a conduction block " . s.region)
        if (s.td)
            items.Push("temporal dispersion " . s.region)
        if (s.nrProx)
            items.Push("no response with stimulation " . Assess_SitePhrase(s.site))
    }
    return "The " . st.name . " showed " . Util_JoinList(items) . "."
}

; ---------------------------------------------------------------------------
; Late responses
; ---------------------------------------------------------------------------
Assess_Late(rep, st, kind) {
    global CFG
    st.name := Anat_NerveDisplay(st)
    st.limb := Assess_Limb(st.nerve)
    st.checks := []
    st.flags := {absent: false, prolonged: false, relProlonged: false, any: false, lat: ""}
    row := st.rows[1]
    if (kind = "fwave") {
        val := row.flat, isNR := row.flatNR || (row.persist != "" && row.persist = 0)
        norm := Norm_FWave(st.nerve), ref := row.flatRef
        label := "F-wave minimal latency"
    } else {
        val := row.hlat, isNR := row.hlatNR
        norm := Norm_HReflex(), ref := row.hlatRef
        label := "H-reflex latency"
    }
    if (isNR || (val = "" && row.nr)) {
        if (kind = "fwave" && st.nerve = "peroneal") {
            rep.notes.Push("Absent " . st.name . " F-waves were not graded (peroneal F-waves are frequently absent in normal subjects).")
            st.checks.Push({study: st.name, label: label, value: "NR", limit: "", dir: "", unit: "", src: "", note: "not graded", abnormal: false, borderline: false})
            return
        }
        st.flags.absent := true, st.flags.any := true
        Assess_CheckNR(st, label)
        return
    }
    lim := (CFG.NormalsSource = "REPORT") ? "" : norm.lat
    src := norm.src
    if (lim = "" && ref != "")
        lim := ref, src := "report Ref."
    c := Assess_Check(st, label, val, lim, "max", "ms", src)
    st.flags.prolonged := c.abnormal
    st.flags.lat := val
    st.flags.any := c.abnormal
    st.sideLimit := norm.sideDiff
}

Assess_LateSideDiff(rep, list, kind) {
    for i, a in list {
        for j, b in list {
            if (j <= i || a.nerve != b.nerve || a.side = b.side || a.side = "" || b.side = "")
                continue
            if (a.flags.lat = "" || b.flags.lat = "" || a.sideLimit = "")
                continue
            diff := a.flags.lat - b.flags.lat
            longer := (diff > 0) ? a : b
            c := Assess_Check(longer, "Side-to-side difference", Round(Abs(diff), 1), a.sideLimit, "max", "ms", "Preston & Shapiro")
            if (c.abnormal && !longer.flags.prolonged)
                longer.flags.relProlonged := true, longer.flags.any := true, longer.flags.relTo := (longer.side = "R") ? "left" : "right"
        }
    }
}

Assess_LateText(rep) {
    out := []
    for k, kind in ["fwave", "hreflex"] {
        list := rep[kind]
        if (list.Length() = 0)
            continue
        noun := (kind = "fwave") ? "F-wave" : "H-reflex"
        abn := [], nl := 0
        for i, st in list {
            nm := RegExReplace(st.name, " (sensory|motor) nerve.*$", "")
            if (kind = "hreflex")
                nm := Anat_SideWord(st.side)
            nmCap := Util_CapFirst(nm)
            if (st.flags.absent)
                abn.Push(kind = "fwave" ? "The " . nm . " F-waves were absent." : "The " . nm . " H-reflex was absent.")
            else if (st.flags.prolonged)
                abn.Push("The " . nm . " " . noun . " latency was prolonged.")
            else if (st.flags.relProlonged)
                abn.Push("The " . nm . " " . noun . " latency was prolonged relative to the " . st.flags.relTo . ".")
            else
                nl++
        }
        if (abn.Length() = 0)
            out.Push(list.Length() > 1 ? "All " . noun . " latencies were normal." : "The " . (kind = "hreflex" ? Anat_SideWord(list[1].side) : RegExReplace(list[1].name, " (sensory|motor) nerve.*$", "")) . " " . noun . " latency was normal.")
        else {
            s := Util_Join(abn, " ")
            if (nl > 0)
                s .= " All remaining " . noun . " latencies were normal."
            out.Push(s)
        }
    }
    return Util_Join(out, " ")
}

; ---------------------------------------------------------------------------
; Internal comparison studies
; ---------------------------------------------------------------------------
Assess_FindStudy(list, key, side) {
    for i, st in list
        if (st.key = key && st.side = side)
            return st
    return ""
}

Assess_Comparisons(rep, pt) {
    rep.comparisons := []
    pseudo := {name: "Comparison studies", checks: []}
    for k, side in ["R", "L"] {
        sw := Anat_SideWord(side)
        defs := [["medianUlnarMotor", "motor", "medianAPB", "ulnarADM", "lat", sw . " median-ulnar motor distal latency difference"]
            , ["medianUlnarSensory", "sensory", "median", "ulnar", "peak", sw . " median-ulnar sensory peak latency difference"]
            , ["medianUlnarPalm", "sensory", "medianPalmMixed", "ulnarPalm", "peak", sw . " median-ulnar palmar latency difference"]
            , ["medianUlnarPalm", "sensory", "medianPalm", "ulnarPalm", "peak", sw . " median-ulnar palmar latency difference"]
            , ["medianUlnarD4", "sensory", "medianD4", "ulnarD4", "peak", sw . " median-ulnar ring finger latency difference"]
            , ["medianRadialD1", "sensory", "medianD1", "radialD1", "peak", sw . " median-radial thumb latency difference"]]
        for j, dd in defs {
            a := Assess_FindStudy(rep[dd[2]], dd[3], side)
            b := Assess_FindStudy(rep[dd[2]], dd[4], side)
            if (!IsObject(a) || !IsObject(b))
                continue
            ra := a.rows[1], rb := b.rows[1]
            fld := dd[5]
            va := (ra[fld] != "") ? ra[fld] : ra.lat
            vb := (rb[fld] != "") ? rb[fld] : rb.lat
            if (va = "" || vb = "")
                continue
            if (ra.dist != "" && rb.dist != "" && Abs(ra.distCm - rb.distCm) > 0.5) {
                rep.notes.Push("The " . dd[6] . " was not graded because the two recording distances differ (" . Util_Fmt(ra.distCm) . " vs " . Util_Fmt(rb.distCm) . " cm).")
                continue
            }
            lim := Norm_Comparison(dd[1], pt)
            diff := Round(va - vb, 2)
            c := Assess_Check(pseudo, Util_CapFirst(dd[6]), diff, lim.limit, "max", "ms", lim.src)
            rep.comparisons.Push({kind: dd[1], side: side, label: dd[6], value: diff, limit: lim.limit, abnormal: c.abnormal, table: dd[2]})
        }
    }
    rep.comparisonChecks := pseudo.checks
}

Assess_ComparisonText(rep, table) {
    global CFG
    out := []
    if (CFG.ReportComparisons = "never")
        return ""
    for i, c in rep.comparisons {
        if (!c.abnormal || c.table != table)
            continue
        if (CFG.ReportComparisons = "whenNeeded") {
            ms := Assess_FindStudy(rep.sensory, "median", c.side)
            mm := Assess_FindStudy(rep.motor, "medianAPB", c.side)
            if ((IsObject(ms) && ms.abnormal) || (IsObject(mm) && mm.abnormal))
                continue
        }
        out.Push("The " . c.label . " was prolonged.")
    }
    return Util_Join(out, " ")
}

; ---------------------------------------------------------------------------
; Needle EMG
; ---------------------------------------------------------------------------
Assess_Grade(v) {
    s := Util_Lower(Util_Trim(v))
    if (s = "" || RegExMatch(s, "^(none|0|norm|nml|normal|nl|-|--|n|absent|abs|no|neg|negative|nil)$"))
        return 0
    if RegExMatch(s, "O)([1-4])\s*\+", m)
        return m.Value(1) + 0
    if RegExMatch(s, "O)\+\s*([1-4])", m)
        return m.Value(1) + 0
    if RegExMatch(s, "^[1-4]$")
        return s + 0
    if RegExMatch(s, "^(rare|occ\w*|few|trace|sl\w*|single|minimal|scattered|\+/-|\+-)")
        return 0.5
    if RegExMatch(s, "^(some|mod\w*|several)")
        return 2
    if RegExMatch(s, "^(many|abund\w*|full|marked|profuse|frequent|numerous|diffuse|sev\w*)")
        return 3
    if RegExMatch(s, "^(incr\w*|inc|present|pres|yes|y|\+|pos\w*|mild)")
        return 1
    return 0
}

; MUAP amplitude/duration: {dir: 1 increased | -1 decreased | 0, grade, nascent, variable}
Assess_MUAP(v) {
    s := Util_Lower(Util_Trim(v))
    r := {dir: 0, grade: 0, nascent: false, variable: false}
    if (s = "" || RegExMatch(s, "^(norm|nml|normal|nl|n|none|0|-|--)$"))
        return r
    if InStr(s, "nasc") {
        r.nascent := true
        return r
    }
    if RegExMatch(s, "^(var\w*|mix\w*)") {
        r.variable := true
        return r
    }
    if RegExMatch(s, "O)^-\s*([1-4])$|^([1-4])\s*-$", m) {
        r.dir := -1, r.grade := (m.Value(1) != "" ? m.Value(1) : m.Value(2)) + 0
        return r
    }
    if RegExMatch(s, "O)^\+?\s*([1-4])\s*\+?$", m) {
        r.dir := 1, r.grade := m.Value(1) + 0
        return r
    }
    if RegExMatch(s, "^(incr\w*|inc|large|high|long|big|giant|prolong\w*|\+)") {
        r.dir := 1, r.grade := 1
        return r
    }
    if RegExMatch(s, "^(decr\w*|dec|small|low|short|reduc\w*|red|sm|brief|myopath\w*)") {
        r.dir := -1, r.grade := 1
        return r
    }
    return r
}

; "normal" | "reduced" | "early" | "none" | ""
Assess_Recruit(v) {
    s := Util_Lower(Util_Trim(v))
    if (s = "")
        return ""
    if RegExMatch(s, "^(nml|norm|normal|nl|full|complete|n|good)$")
        return "normal"
    if RegExMatch(s, "(early|myopath|^incr|increased|rapid recr)")
        return "early"
    if RegExMatch(s, "(no mu|^none$|absent|no vol|no muap|^0$|no units)")
        return "none"
    if RegExMatch(s, "(decr|dec|reduc|red|discrete|single|neurogen|ff|fast fir|rapid fir|^mild|^mod|^sev|picket|poor|late)")
        return "reduced"
    return "normal"
}

Assess_Muscle(rep, m) {
    global MUSCLE_DB
    match := Anat_MatchMuscle(m.name)
    m.key := match.key
    m.def := (match.key != "") ? MUSCLE_DB[match.key] : ""
    sideWord := Anat_SideWord(m.side)
    if (m.key = "") {
        m.display := (sideWord != "" ? sideWord . " " : "") . m.name
        rep.warnings.Push("Muscle not recognised: """ . m.raw . """ - it is described in the summary but was not used for localization. Add it as an alias in lib\Anatomy.ahk.")
    } else {
        m.display := (sideWord != "" ? sideWord . " " : "") . m.def.display
        if (match.how != "exact")
            rep.notes.Push("""" . m.raw . """ was matched to " . m.def.full . " (" . match.how . ").")
    }
    if (m.side = "" && m.key != "" && !m.def.flags.paraspinal && m.def.limb != "bulbar")
        rep.notes.Push("No side found for """ . m.raw . """.")
    ia := Util_Lower(Util_Trim(m.ia))
    m.iaIncr := RegExMatch(ia, "^(incr|inc|prolong|\+|1\+|2\+|3\+|increased|myoton)") ? true : false
    m.iaDecr := RegExMatch(ia, "^(decr|dec|reduc|red|\-)") ? true : false
    m.fibG := Assess_Grade(m.fib)
    m.pswG := Assess_Grade(m.psw)
    m.fascG := Assess_Grade(m.fasc)
    m.polyG := Assess_Grade(m.poly)
    m.ampM := Assess_MUAP(m.amp)
    m.durM := Assess_MUAP(m.dur)
    m.recr := Assess_Recruit(m.recruit)
    eff := Util_Lower(Util_Trim(m.effort))
    m.effortLimited := RegExMatch(eff, "^(poor|min|mod|sub|fair|limit|var|weak|partial|unable)") ? true : false
    oth := Util_Lower(Util_Trim(m.other))
    m.others := []
    if (oth != "" && !RegExMatch(oth, "^(none|0|norm|nml|-|--|n|no)$")) {
        if RegExMatch(oth, "neuromyoton")
            m.others.Push("neuromyotonic discharges")
        else if RegExMatch(oth, "myoton|myo ?d\b|myot")
            m.others.Push("myotonic discharges")
        if RegExMatch(oth, "crd|complex rep")
            m.others.Push("complex repetitive discharges")
        if RegExMatch(oth, "myokym")
            m.others.Push("myokymic discharges")
        if RegExMatch(oth, "cramp")
            m.others.Push("cramp discharges")
        if RegExMatch(oth, "doublet|multiplet")
            m.others.Push("doublets/multiplets")
        if (m.others.Length() = 0)
            m.others.Push(oth), rep.notes.Push("Unrecognised 'Other' finding """ . m.other . """ in " . m.display . " was reported verbatim.")
    }
    m.myotonia := false
    for i, o in m.others
        if InStr(o, "myotonic")
            m.myotonia := true
    m.active := (m.fibG > 0 || m.pswG > 0)
    m.activeGrade := Max(m.fibG, m.pswG)
    m.reinnervation := (m.ampM.dir > 0 || m.durM.dir > 0)
    m.reduced := (m.recr = "reduced" || m.recr = "none")
    m.myopathicMUAP := (m.ampM.dir < 0 || m.durM.dir < 0)
    m.myopathic := (m.myopathicMUAP || m.recr = "early") && !m.reinnervation && !m.reduced
    m.neurogenic := !m.myopathic && (m.active || m.reinnervation || m.reduced || m.ampM.nascent || m.durM.nascent)
    m.abnormal := m.iaIncr || m.iaDecr || m.active || m.fascG > 0 || m.others.Length() > 0 || m.reduced || m.recr = "early"
        || m.ampM.dir != 0 || m.durM.dir != 0 || m.ampM.nascent || m.durM.nascent || m.polyG > 0 || m.ampM.variable
    if (m.effortLimited && (m.reduced || m.recr = ""))
        rep.notes.Push("Effort was submaximal in the " . m.display . "; recruitment may be under-estimated.")
    m.explained := ""
}

Assess_MusclePhrase(m) {
    if (!m.abnormal)
        return ""
    items := []
    if (m.iaIncr)
        items.Push("increased insertional activity")
    else if (m.iaDecr)
        items.Push("decreased insertional activity")
    if (m.active)
        items.Push("abnormal spontaneous activity")
    if (m.fascG > 0)
        items.Push("fasciculation potentials")
    for i, o in m.others
        items.Push(o)
    if (m.recr = "reduced")
        items.Push("reduced recruitment")
    else if (m.recr = "none")
        items.Push("no voluntary motor unit activity")
    else if (m.recr = "early")
        items.Push("early recruitment")
    a := m.ampM, d := m.durM
    if (a.nascent || d.nascent)
        items.Push("nascent motor units")
    else if (a.dir > 0 && d.dir > 0)
        items.Push("increased motor unit amplitudes and durations")
    else if (a.dir < 0 && d.dir < 0)
        items.Push("decreased motor unit amplitudes and durations")
    else {
        if (a.dir > 0)
            items.Push("increased motor unit amplitudes")
        else if (a.dir < 0)
            items.Push("decreased motor unit amplitudes")
        if (d.dir > 0)
            items.Push("increased motor unit durations")
        else if (d.dir < 0)
            items.Push("decreased motor unit durations")
    }
    if (a.variable)
        items.Push("variable motor unit amplitudes")
    if (m.polyG > 0 && a.dir = 0 && d.dir = 0)
        items.Push("increased polyphasia")
    if (items.Length() = 0)
        return ""
    return "The " . m.display . " showed " . Util_JoinList(items) . "."
}

; ---------------------------------------------------------------------------
; Temperature
; ---------------------------------------------------------------------------
Assess_Temperature(rep) {
    global CFG
    minU := "", minL := ""
    for k, kind in ["sensory", "motor"] {
        for i, st in rep[kind] {
            for j, row in st.rows {
                if (row.temp = "")
                    continue
                if (st.limb = "upper")
                    minU := (minU = "" || row.temp < minU) ? row.temp : minU
                else if (st.limb = "lower")
                    minL := (minL = "" || row.temp < minL) ? row.temp : minL
            }
        }
    }
    msg := []
    if (minU != "" && minU < CFG.WarnTempUpperC)
        msg.Push("upper limb as low as " . Util_Fmt(minU) . " C (AANEM: >" . CFG.WarnTempUpperC . " C)")
    if (minL != "" && minL < CFG.WarnTempLowerC)
        msg.Push("lower limb as low as " . Util_Fmt(minL) . " C (AANEM: >" . CFG.WarnTempLowerC . " C)")
    if (msg.Length() > 0)
        rep.warnings.Push("Recorded temperatures: " . Util_Join(msg, "; ") . ". Cool limbs prolong latencies and slow conduction velocities (about 0.2 ms and 1.5-2.5 m/s per degree)" . (CFG.ApplyTempCorrection ? "; values were temperature-corrected." : "."))
}

; ---------------------------------------------------------------------------
; Summary text
; ---------------------------------------------------------------------------
Assess_Summary(rep) {
    global CFG
    paras := []
    sensAbn := [], sensNl := 0, sensNR := 0
    for i, st in rep.sensory {
        p := Assess_SensoryPhrase(st)
        if (p != "")
            sensAbn.Push(p)
        else
            sensNl++
        if (st.flags.nr)
            sensNR++
    }
    motAbn := [], motNl := 0
    for i, st in rep.motor {
        p := Assess_MotorPhrase(st)
        if (p != "")
            motAbn.Push(p)
        else
            motNl++
    }
    nS := rep.sensory.Length(), nM := rep.motor.Length()
    late := Assess_LateText(rep)
    compS := Assess_ComparisonText(rep, "sensory")
    compM := Assess_ComparisonText(rep, "motor")
    if (nS > 0 && nM > 0 && sensAbn.Length() = 0 && motAbn.Length() = 0 && compS = "" && compM = "") {
        p := "All sensory and motor responses were normal."
        if (late != "")
            p .= " " . late
        paras.Push(p)
    } else {
        if (nS > 0) {
            if (sensAbn.Length() = 0)
                p := "All sensory responses were normal."
            else if (sensNR = nS && nS > 1)
                p := "All sensory responses were absent."
            else {
                p := Util_Join(sensAbn, " ")
                if (sensNl > 0)
                    p .= " All remaining sensory responses were normal."
            }
            if (compS != "")
                p .= " " . compS
            paras.Push(p)
        }
        if (nM > 0) {
            if (motAbn.Length() = 0)
                p := "All motor responses were normal."
            else {
                p := Util_Join(motAbn, " ")
                if (motNl > 0)
                    p .= " All remaining motor responses were normal."
            }
            if (compM != "")
                p .= " " . compM
            if (late != "")
                p .= " " . late
            paras.Push(p)
        } else if (late != "")
            paras.Push(late)
    }
    emgText := ""
    if (rep.emg.Length() > 0) {
        abn := [], nl := 0
        for i, m in rep.emg {
            p := Assess_MusclePhrase(m)
            if (p != "")
                abn.Push(p)
            else
                nl++
        }
        allNormal := "normal insertional activity, no abnormal spontaneous activity, normal motor unit amplitudes and durations, and normal recruitment patterns."
        if (abn.Length() = 0)
            emgText := "All muscles tested showed " . allNormal
        else {
            emgText := Util_Join(abn, " ")
            if (nl > 0)
                emgText .= " All remaining muscles tested showed " . allNormal
        }
    }
    out := Util_Join(paras, "`r`n")
    if (emgText != "")
        out .= (out != "" ? (CFG.BlankLineBeforeEMG ? "`r`n`r`n" : "`r`n") : "") . emgText
    return out
}
