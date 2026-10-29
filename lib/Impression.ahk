; =============================================================================
; Impression.ahk - turns the assessed findings into a draft electrodiagnostic
; impression. Patterns and criteria follow Preston & Shapiro (Electromyography
; and Neuromuscular Disorders) and AANEM practice parameters:
;
;  * Carpal tunnel: mild = median sensory slowing (present SNAP) or abnormal
;    comparison study only; moderate = sensory + median motor distal latency;
;    severe = any median motor axon loss (low/absent CMAP or APB denervation).
;  * Ulnar neuropathy at the elbow: focal slowing (<43 m/s or >15 m/s and >23%
;    drop vs forearm, AANEM) or conduction block across the elbow.
;  * Peroneal neuropathy at the fibular head: focal slowing (<42 m/s with >6 m/s and
;    >12% drop, AANEM) or conduction block (>25% drop) across the fibular head.
;  * Radiculopathy: neurogenic changes in >=2 muscles of the same root innervated by
;    different peripheral nerves (or 1 limb muscle + paraspinals), with normal SNAPs
;    in that territory; root level chosen by a minimal root cover that is least
;    contradicted by normal muscles.
;  * Plexopathy: multi-nerve pattern fitting a trunk/cord/plexus with abnormal SNAPs in
;    its territory, normal paraspinals and spared root-level muscles.
;  * Polyneuropathy: length-dependent lower-limb SNAP (+/- CMAP) abnormalities not
;    explained by a focal lesion; demyelinating if >=2 motor nerves reach the
;    demyelinating range (DL >130% ULN, CV <75% LLN, conduction block/dispersion).
;  * Myopathy: small/short MUAPs and/or early recruitment in >=2 muscles;
;    "irritable" when fibrillations/PSWs are present.
;  * Motor neuron disease: active + chronic denervation in >=3 of bulbar, cervical,
;    thoracic, lumbosacral regions (revised El Escorial EMG distribution).
; =============================================================================

Imp_Build(rep) {
    global CFG
    ctx := {rep: rep, items: [], cts: {}, une: {}, radic: {}, pnScore: 0, pnEMG: false, lowerSnapBilateral: false}
    Imp_PrelimLowerSnaps(ctx)
    Imp_CTS(ctx)
    Imp_UlnarElbow(ctx)
    Imp_UlnarWrist(ctx)
    Imp_PeronealFH(ctx)
    Imp_TibialAnkle(ctx)
    Imp_MND(ctx)
    Imp_Myopathy(ctx)
    Imp_PolyneuropathyEMGScore(ctx)
    Imp_EMGLocalize(ctx)
    Imp_Polyneuropathy(ctx)
    Imp_Leftovers(ctx)
    return Imp_Assemble(ctx)
}

; ---------------------------------------------------------------------------
; helpers
; ---------------------------------------------------------------------------
Imp_Add(ctx, score, text, kind, minor := false, sentence := "") {
    ctx.items.Push({score: score, text: text, kind: kind, minor: minor, sentence: (sentence != "" ? sentence : text), order: ctx.items.Length() + 1})
}

; Nerve name without the recording muscle ("right peroneal motor nerve").
Imp_BareName(st) {
    return RegExReplace(st.name, " at the [A-Z]{2,4}$", "")
}

Imp_Study(list, keys, side) {
    for i, st in list
        if (st.side = side && Util_ArrHas(keys, st.key))
            return st
    return ""
}

Imp_Muscles(rep, keys, side) {
    out := []
    for i, m in rep.emg
        if ((m.side = side || m.side = "B") && Util_ArrHas(keys, m.key))
            out.Push(m)
    return out
}

Imp_AnyNeurogenic(muscles) {
    for i, m in muscles
        if (m.neurogenic)
            return true
    return false
}

Imp_Explain(obj, why) {
    if (IsObject(obj) && obj.explained = "")
        obj.explained := why
}

Imp_SevScore(sev) {
    return (sev = "severe") ? 80 : (sev = "moderate") ? 64 : 45
}

Imp_Comps(ctx, side, kinds) {
    for i, c in ctx.rep.comparisons
        if (c.side = side && c.abnormal && Util_ArrHas(kinds, c.kind))
            return true
    return false
}

; Lower-limb SNAPs abnormal on both sides -> treat them as generalized (polyneuropathy)
; rather than as evidence for a focal plexus/nerve lesion.
Imp_PrelimLowerSnaps(ctx) {
    sides := {}
    for i, st in ctx.rep.sensory
        if ((st.key = "sural" || st.key = "superficialPeroneal") && st.abnormal)
            sides[st.side] := true
    ctx.lowerSnapBilateral := sides.HasKey("R") && sides.HasKey("L")
}

; Combines matching right/left focal neuropathies into one bilateral statement.
Imp_EmitBilateral(ctx, bySide, buildFn) {
    r := bySide.R, l := bySide.L
    if (IsObject(r) && IsObject(l) && r.sev = l.sev && r.path = l.path) {
        Imp_Add(ctx, Imp_SevScore(r.sev) + 2, %buildFn%("B", r.sev, r.path), "focal")
        return
    }
    for i, s in ["R", "L"] {
        x := bySide[s]
        if IsObject(x) {
            if (x.borderline)
                Imp_Add(ctx, 12, x.text, "borderline", true, "There is " . Util_LowerFirst(x.text))
            else
                Imp_Add(ctx, Imp_SevScore(x.sev), %buildFn%(s, x.sev, x.path), "focal")
        }
    }
}

Imp_SidePrefix(side, sev) {
    ; "A right, mild" / "Bilateral, mild"
    if (side = "B")
        return "Bilateral, " . sev
    return "A " . Anat_SideWord(side) . ", " . sev
}

Imp_SideArticle(side, sev) {
    if (side = "B")
        return "bilateral, " . sev
    return "a " . Anat_SideWord(side) . ", " . sev
}

; ---------------------------------------------------------------------------
; Carpal tunnel syndrome
; ---------------------------------------------------------------------------
Imp_CTSText(side, sev, path) {
    plural := (side = "B") ? "median neuropathies" : "median neuropathy"
    syn := (side = "B") ? "bilateral, " . sev . " carpal tunnel syndrome" : Imp_SideArticle(side, sev) . " carpal tunnel syndrome"
    return Imp_SidePrefix(side, sev) . " " . plural . " at the wrist, " . path . ". In this clinical context, this is consistent with " . syn . "."
}

Imp_CTS(ctx) {
    global CFG
    rep := ctx.rep
    for i, side in ["R", "L"] {
        ms := Imp_Study(rep.sensory, ["median", "medianD3"], side)
        palm := Imp_Study(rep.sensory, ["medianPalm", "medianPalmMixed", "medianD4", "medianD1"], side)
        mm := Imp_Study(rep.motor, ["medianAPB"], side)
        us := Imp_Study(rep.sensory, ["ulnar"], side)
        apb := Imp_Muscles(rep, ["APB", "OPP"], side)
        if (!IsObject(ms) && !IsObject(mm))
            continue
        sensSlow := IsObject(ms) && (ms.flags.lat || ms.flags.cv) && !ms.flags.borderline
        sensSlowBorder := IsObject(ms) && (ms.flags.lat || ms.flags.cv) && ms.flags.borderline
        sensNR := IsObject(ms) && ms.flags.nr
        sensAmp := IsObject(ms) && ms.flags.amp
        palmSlow := IsObject(palm) && (palm.flags.lat || palm.flags.cv || palm.flags.nr)
        motorLat := IsObject(mm) && mm.flags.lat
        motorAxon := (IsObject(mm) && (mm.flags.amp || mm.flags.nr)) || Imp_AnyNeurogenic(apb)
        compAbn := Imp_Comps(ctx, side, ["medianUlnarMotor", "medianUlnarSensory", "medianUlnarPalm", "medianUlnarD4", "medianRadialD1"])
        ulnNR := IsObject(us) && us.flags.nr
        wrist := sensSlow || palmSlow || motorLat || compAbn || (sensNR && !ulnNR)
        if (!wrist) {
            if (sensSlowBorder && !sensAmp && !motorAxon) {
                ctx.cts[side] := {borderline: true, text: "Borderline slowing of the " . ms.name . " at the wrist, of uncertain clinical significance."}
                Imp_Explain(ms, "borderline")
            }
            continue
        }
        ; Is the median slowing disproportionate to the ulnar (vs. polyneuropathy)?
        if (IsObject(us) && (us.flags.lat || us.flags.cv || us.flags.nr) && !compAbn) {
            mr := IsObject(ms) ? ms.flags.latRatio : ""
            ur := us.flags.latRatio
            dispro := (mr != "" && ur != "" && mr - ur >= 0.15) || (sensNR && !us.flags.nr)
            if (!dispro) {
                ctx.ctsPN := true
                continue
            }
        }
        if (motorAxon)
            sev := "severe"
        else if ((sensSlow || sensNR || sensAmp || palmSlow) && motorLat)
            sev := "moderate"
        else if (sensNR)
            sev := CFG.CTSAbsentSNAPGrade
        else if (motorLat)
            sev := "moderate"
        else
            sev := "mild"
        demy := sensSlow || motorLat || palmSlow || compAbn
        path := (sev = "severe") ? (demy ? "demyelinating and axonal" : "axonal") : "demyelinating"
        ctx.cts[side] := {sev: sev, path: path}
        Imp_Explain(ms, "CTS"), Imp_Explain(palm, "CTS"), Imp_Explain(mm, "CTS")
        for j, m in apb
            Imp_Explain(m, "CTS")
    }
    Imp_EmitBilateral(ctx, ctx.cts, "Imp_CTSText")
}

; ---------------------------------------------------------------------------
; Ulnar neuropathy at the elbow / wrist
; ---------------------------------------------------------------------------
Imp_UNEText(side, sev, path) {
    plural := (side = "B") ? "ulnar neuropathies" : "ulnar neuropathy"
    syn := (side = "B") ? "bilateral, " . sev . " cubital tunnel syndrome" : Imp_SideArticle(side, sev) . " cubital tunnel syndrome"
    return Imp_SidePrefix(side, sev) . " " . plural . " at the elbow, " . path . ". In this clinical context, this is consistent with " . syn . "."
}

Imp_UlnarElbow(ctx) {
    rep := ctx.rep
    for i, side in ["R", "L"] {
        motors := []
        for j, k in ["ulnarADM", "ulnarFDI"] {
            st := Imp_Study(rep.motor, [k], side)
            if IsObject(st)
                motors.Push(st)
        }
        if (motors.Length() = 0)
            continue
        strong := false, weak := false, cb := false, axonCMAP := false
        for j, st in motors {
            if (st.flags.amp || st.flags.nr)
                axonCMAP := true
            for k, s in st.flags.segs {
                if (s.type != "acrossElbow")
                    continue
                if (s.cb || s.td || s.nrProx)
                    strong := true, cb := true
                else if (s.slow && s.refSlow && !s.relSlow)
                    continue
                else if ((s.slow && !s.borderline) || (s.slow && s.relSlow))
                    strong := true
                else if (s.slow || s.relSlow)
                    weak := true
            }
        }
        if (!strong && !weak)
            continue
        us := Imp_Study(rep.sensory, ["ulnar", "ulnarD4"], side)
        duc := Imp_Study(rep.sensory, ["duc"], side)
        sensAbn := (IsObject(us) && (us.flags.amp || us.flags.nr)) || (IsObject(duc) && duc.abnormal)
        musc := Imp_Muscles(rep, ["FDI", "ADM", "ADP", "FCU", "FDP45"], side)
        emgAxon := Imp_AnyNeurogenic(musc)
        if (!strong && !sensAbn && !emgAxon && !axonCMAP) {
            ctx.une[side] := {borderline: true, text: "Borderline, focal slowing of the " . Imp_BareName(motors[1]) . " across the elbow, of uncertain clinical significance."}
            for j, st in motors
                Imp_Explain(st, "borderline")
            continue
        }
        sev := (axonCMAP || emgAxon) ? "severe" : (sensAbn || cb) ? "moderate" : "mild"
        path := (sev = "severe") ? "demyelinating and axonal" : "demyelinating"
        ctx.une[side] := {sev: sev, path: path}
        for j, st in motors
            Imp_Explain(st, "UNE")
        Imp_Explain(us, "UNE"), Imp_Explain(duc, "UNE")
        for j, m in musc
            Imp_Explain(m, "UNE")
    }
    Imp_EmitBilateral(ctx, ctx.une, "Imp_UNEText")
}

Imp_UlnarWrist(ctx) {
    rep := ctx.rep
    for i, side in ["R", "L"] {
        if IsObject(ctx.une[side])
            continue
        st := Imp_Study(rep.motor, ["ulnarADM", "ulnarFDI"], side)
        if (!IsObject(st) || !st.flags.lat || st.explained != "")
            continue
        mm := Imp_Study(rep.motor, ["medianAPB"], side)
        if (IsObject(mm) && mm.flags.lat)
            continue        ; diffuse distal slowing - leave for polyneuropathy logic
        forearmSlow := false
        for k, s in st.flags.segs
            if (s.type = "forearm" && s.slow)
                forearmSlow := true
        if (forearmSlow)
            continue
        musc := Imp_Muscles(rep, ["FDI", "ADM", "ADP"], side)
        axon := st.flags.amp || Imp_AnyNeurogenic(musc)
        sev := axon ? "moderate" : "mild"
        path := axon ? "demyelinating and axonal" : "demyelinating"
        Imp_Add(ctx, Imp_SevScore(sev) - 2, "A " . Anat_SideWord(side) . ", " . sev . " ulnar neuropathy at the wrist, " . path . ".", "focal")
        Imp_Explain(st, "ulnar wrist")
        for j, m in musc
            Imp_Explain(m, "ulnar wrist")
    }
}

; ---------------------------------------------------------------------------
; Peroneal neuropathy at the fibular head
; ---------------------------------------------------------------------------
Imp_PeronealFH(ctx) {
    global CFG
    rep := ctx.rep
    per := CFG.PeronealTerm
    for i, side in ["R", "L"] {
        motors := []
        for j, k in ["peronealEDB", "peronealTA"] {
            st := Imp_Study(rep.motor, [k], side)
            if IsObject(st)
                motors.Push(st)
        }
        strong := false, weak := false, cb := false
        for j, st in motors {
            for k, s in st.flags.segs {
                if (s.type != "acrossFH")
                    continue
                if (s.cb || s.td || s.nrProx)
                    strong := true, cb := true
                else if (s.slow && s.refSlow && !s.relSlow)
                    continue
                else if (s.slow && !s.borderline)
                    strong := true
                else if (s.slow || s.relSlow)
                    weak := true
            }
        }
        if (!strong && !weak)
            continue
        sp := Imp_Study(rep.sensory, ["superficialPeroneal"], side)
        spAbn := IsObject(sp) && sp.abnormal && !ctx.lowerSnapBilateral
        musc := Imp_Muscles(rep, ["TA", "EHL", "EDL", "PL", "PB", "EDB"], side)
        bfsh := Imp_Muscles(rep, ["BFSH"], side)
        ta := Imp_Study(rep.motor, ["peronealTA"], side)
        emgAxon := Imp_AnyNeurogenic(musc) && !Imp_AnyNeurogenic(bfsh)
        axon := emgAxon || (IsObject(ta) && (ta.flags.amp || ta.flags.nr))
        if (!strong && !spAbn && !axon) {
            t := "Borderline, focal slowing of the " . Imp_BareName(motors[1]) . " across the fibular head, of uncertain clinical significance."
            Imp_Add(ctx, 12, t, "borderline", true, "There is " . Util_LowerFirst(t))
            for j, st in motors
                Imp_Explain(st, "borderline")
            continue
        }
        sev := axon ? "severe" : (spAbn || cb) ? "moderate" : "mild"
        path := axon ? "demyelinating and axonal" : "demyelinating"
        Imp_Add(ctx, Imp_SevScore(sev), "A " . Anat_SideWord(side) . ", " . sev . " " . per . " neuropathy at the fibular head, " . path . ".", "focal")
        for j, st in motors
            Imp_Explain(st, "peroneal FH")
        Imp_Explain(sp, "peroneal FH")
        if (emgAxon)
            for j, m in musc
                Imp_Explain(m, "peroneal FH")
    }
}

; ---------------------------------------------------------------------------
; Tibial neuropathy at the ankle (tarsal tunnel) - isolated distal slowing only
; ---------------------------------------------------------------------------
Imp_TibialAnkle(ctx) {
    rep := ctx.rep
    for i, side in ["R", "L"] {
        st := Imp_Study(rep.motor, ["tibialAH"], side)
        if (!IsObject(st) || !st.flags.lat || st.flags.borderline || st.explained != "")
            continue
        pe := Imp_Study(rep.motor, ["peronealEDB"], side)
        su := Imp_Study(rep.sensory, ["sural"], side)
        if ((IsObject(pe) && pe.flags.lat) || (IsObject(su) && su.abnormal))
            continue
        Imp_Add(ctx, 40, "A " . Anat_SideWord(side) . ", mild tibial neuropathy at the ankle, demyelinating. In this clinical context, this may be consistent with a " . Anat_SideWord(side) . " tarsal tunnel syndrome.", "focal")
        Imp_Explain(st, "tarsal tunnel")
    }
}

; ---------------------------------------------------------------------------
; Motor neuron disease / diffuse denervation
; ---------------------------------------------------------------------------
Imp_MND(ctx) {
    global CFG
    rep := ctx.rep
    regions := {bulbar: [], cervical: [], thoracic: [], lumbosacral: []}
    for i, m in rep.emg {
        if (m.key = "" || !m.neurogenic)
            continue
        if (!(m.active || m.fascG > 0) || !(m.reinnervation || m.reduced || m.def.flags.paraspinal))
            continue
        regions[m.def.region].Push(m)
    }
    qualifying := []
    for i, r in ["bulbar", "cervical", "thoracic", "lumbosacral"] {
        lst := regions[r]
        if (r = "bulbar" || r = "thoracic") {
            if (lst.Length() >= 1)
                qualifying.Push(r)
        } else {
            nerves := {}
            for j, m in lst
                nerves[m.def.nerve != "" ? m.def.nerve : m.key] := true
            if (Util_Count(nerves) >= 2)
                qualifying.Push(r)
        }
    }
    if (qualifying.Length() < CFG.MNDMinRegions)
        return
    sensNormal := true
    for i, st in rep.sensory
        if (st.abnormal)
            sensNormal := false
    txt := "Active and chronic denervation/reinnervation in the " . Util_JoinList(qualifying) . " myotomes"
    txt .= sensNormal ? ", with normal sensory responses." : "."
    txt .= " In this clinical context, these electrodiagnostic findings may be due to motor neuron disease or a polyradiculopathy."
    Imp_Add(ctx, 100, txt, "mnd")
    ctx.mnd := true
    for i, m in rep.emg
        if (m.neurogenic)
            Imp_Explain(m, "MND")
    for i, st in rep.motor
        if (st.flags.amp && !st.flags.demy)
            Imp_Explain(st, "MND")
}

; ---------------------------------------------------------------------------
; Myopathy / myotonia
; ---------------------------------------------------------------------------
Imp_Myopathy(ctx) {
    rep := ctx.rep
    myo := [], myot := []
    for i, m in rep.emg {
        if (m.explained != "")
            continue
        if (m.myopathic)
            myo.Push(m)
        if (m.myotonia)
            myot.Push(m)
    }
    if (myo.Length() >= 2) {
        irritable := false, nProx := 0, nDist := 0, hasMyot := false
        for i, m in myo {
            if (m.active)
                irritable := true
            if (m.myotonia)
                hasMyot := true
            if (IsObject(m.def) && m.def.flags.prox)
                nProx++
            else
                nDist++
        }
        dist := (nDist = 0) ? "proximal" : (nProx = 0) ? "distal" : "proximal and distal"
        txt := "A " . dist . ", " . (irritable ? "irritable" : "non-irritable") . " myopathy" . (hasMyot ? ", with myotonic discharges" : "") . "."
        if (irritable)
            txt .= " In this clinical context, this may be consistent with an inflammatory or necrotizing myopathy."
        Imp_Add(ctx, irritable ? 78 : 70, txt, "myopathy")
        for i, m in myo
            Imp_Explain(m, "myopathy")
        for i, m in myot
            Imp_Explain(m, "myopathy")
        if (irritable)
            for i, m in rep.emg
                if (m.active && !m.reinnervation && !m.reduced && m.explained = "")
                    Imp_Explain(m, "myopathy")
        for i, st in rep.motor
            if (st.flags.amp && !st.flags.lat && !st.flags.anySeg)
                Imp_Explain(st, "myopathy")
        return
    }
    if (myot.Length() >= 1) {
        names := []
        for i, m in myot
            names.Push(m.display)
        Imp_Add(ctx, 60, "Myotonic discharges in the " . Util_JoinList(names) . ", without myopathic motor unit changes. In this clinical context, these may be seen in a myotonic disorder or channelopathy.", "myotonia")
        for i, m in myot
            Imp_Explain(m, "myotonia")
    }
}

; ---------------------------------------------------------------------------
; Should distal, symmetric leg denervation be attributed to a polyneuropathy?
; Score (see README): lower SNAPs abnormal (2 bilateral / 1 one side), lower CMAPs
; abnormal (2 bilateral / 1 two nerves one side), symmetric EMG +1, foot intrinsic
; involvement +1, proximal or paraspinal involvement -2, asymmetric EMG -1.
; ---------------------------------------------------------------------------
Imp_PolyneuropathyEMGScore(ctx) {
    global CFG
    rep := ctx.rep
    snapSides := {}, cmapSides := {}, nCmap := 0
    for i, st in rep.sensory
        if ((st.key = "sural" || st.key = "superficialPeroneal") && st.abnormal && st.explained = "")
            snapSides[st.side] := true
    for i, st in rep.motor
        if (st.limb = "lower" && (st.flags.amp || st.flags.nr) && st.explained = "")
            cmapSides[st.side] := true, nCmap++
    s := Util_Count(snapSides) >= 2 ? 2 : Util_Count(snapSides)
    s += Util_Count(cmapSides) >= 2 ? 2 : (nCmap >= 2 ? 1 : 0)
    neuro := {R: {}, L: {}}, tested := {R: false, L: false}, prox := false, foot := false
    for i, m in rep.emg {
        if (m.key = "" || m.def.region != "lumbosacral")
            continue
        if (m.side = "R" || m.side = "L")
            tested[m.side] := true
        if (!m.neurogenic || m.explained != "")
            continue
        if (m.def.flags.prox || m.def.flags.paraspinal)
            prox := true
        if (m.def.flags.foot)
            foot := true
        if (m.side = "R" || m.side = "L")
            neuro[m.side][m.key] := true
    }
    nR := Util_Count(neuro.R), nL := Util_Count(neuro.L)
    if (nR + nL = 0) {
        ctx.pnScore := s
        return
    }
    if (nR > 0 && nL > 0) {
        common := 0
        for k in neuro.R
            if neuro.L.HasKey(k)
                common++
        if (common > 0)
            s += 1
    } else if (tested.R && tested.L)
        s -= 1
    if (foot)
        s += 1
    if (prox)
        s -= 2
    ctx.pnScore := s
    if (s >= CFG.PolyneuropathyEMGThreshold && Util_Count(snapSides) > 0 && !prox) {
        ctx.pnEMG := true
        for i, m in rep.emg
            if (m.key != "" && m.neurogenic && m.explained = "" && m.def.flags.distleg) {
                m.explained := "PN"
                if (m.active)
                    ctx.pnEMGActive := true
            }
    }
}

; ---------------------------------------------------------------------------
; EMG localization: radiculopathy / plexopathy / mononeuropathy
; ---------------------------------------------------------------------------
Imp_EMGLocalize(ctx) {
    rep := ctx.rep
    groups := {}
    for i, m in rep.emg {
        if (m.key = "" || m.explained != "" || !m.neurogenic)
            continue
        reg := (m.def.limb = "upper" || m.key = "CPS") ? "C" : (m.def.limb = "lower" || m.key = "LPS") ? "LS" : ""
        if (reg = "") {
            Imp_Add(ctx, m.active ? 22 : 16, Imp_IsolatedText(m, ""), "nonspecific")
            Imp_Explain(m, "isolated")
            continue
        }
        sides := (m.side = "B" || m.side = "") ? ["R", "L"] : [m.side]
        for j, s in sides {
            g := s . reg
            if !groups.HasKey(g)
                groups[g] := {side: s, reg: reg, abn: [], ps: []}
            if (m.def.flags.paraspinal)
                groups[g].ps.Push(m)
            else
                groups[g].abn.Push(m)
        }
    }
    results := {}
    for g, grp in groups
        results[g] := Imp_LocalizeGroup(ctx, grp, groups)
    ; Merge bilateral radiculopathies of the same region into one statement.
    for i, reg in ["C", "LS"] {
        r := results["R" . reg], l := results["L" . reg]
        if (IsObject(r) && IsObject(l) && r.type = "radic" && l.type = "radic") {
            Imp_EmitRadic(ctx, [r, l])
            r.emitted := true, l.emitted := true
        }
    }
    for g, res in results
        if (IsObject(res) && !res.emitted && res.type = "radic")
            Imp_EmitRadic(ctx, [res])
}

Imp_LocalizeGroup(ctx, grp, groups) {
    global MUSCLE_DB
    rep := ctx.rep
    side := grp.side, reg := grp.reg
    abn := grp.abn
    psActive := false
    for i, m in grp.ps
        if (m.active)
            psActive := true
    psAny := grp.ps.Length() > 0
    ; normal muscles of the same side and region
    nl := []
    for i, m in rep.emg {
        if (m.key = "" || m.abnormal || !(m.side = side || m.side = "B"))
            continue
        r := (m.def.limb = "upper") ? "C" : (m.def.limb = "lower") ? "LS" : ""
        if (r = reg)
            nl.Push(m)
    }
    if (abn.Length() = 0) {
        if (psAny) {
            names := []
            for i, m in grp.ps
                names.Push(m.display)
            regName := (reg = "C") ? "cervical" : "lumbosacral"
            Imp_Add(ctx, 20, "Abnormal spontaneous activity isolated to the " . Util_JoinList(names) . ", which is nonspecific but may be seen in a " . regName . " radiculopathy.", "nonspecific")
            for i, m in grp.ps
                Imp_Explain(m, "isolated")
        }
        return ""
    }
    roots := Imp_BestRoots(abn, nl, reg)
    nerve := Imp_CommonNerve(abn)
    plex := Imp_BestPlexus(abn, nl, reg)
    rootLevelAbn := psAny
    for i, m in abn
        if (m.def.plexus.Length() = 0)
            rootLevelAbn := true
    ; Is the same root pattern present on the other side (bilateral -> root, not plexus)?
    other := groups[(side = "R" ? "L" : "R") . reg]
    bilateral := false
    if IsObject(other)
        for i, m in other.abn
            for j, r in m.def.roots
                if Util_ArrHas(roots.roots, r)
                    bilateral := true
    nerves := {}
    for i, m in abn
        nerves[m.def.nerve] := true
    nNerves := Util_Count(nerves)
    ; ---- mononeuropathy
    if (nerve != "" && !psAny && !bilateral) {
        snap := Imp_SnapStatus(ctx, side, Anat_NerveSensory(nerve))
        if ((abn.Length() >= 2 || snap.abnormal) && (roots.contra >= 1 || snap.abnormal)) {
            Imp_EmitMono(ctx, side, nerve, abn, nl)
            return ""
        }
    }
    ; ---- plexopathy
    if (plex.elem != "" && !rootLevelAbn && !bilateral && nNerves >= 2) {
        snap := Imp_SnapStatus(ctx, side, Anat_PlexusSensory(plex.elem))
        if (snap.abnormal) {
            Imp_EmitPlexus(ctx, side, plex.elem, abn, snap)
            return ""
        }
    }
    ; ---- radiculopathy
    if (roots.roots.Length() > 0 && (psAny || (abn.Length() >= 2 && nNerves >= 2))) {
        res := {type: "radic", side: side, reg: reg, roots: roots.roots, muscles: abn, ps: grp.ps}
        for i, m in abn
            Imp_Explain(m, "radic")
        for i, m in grp.ps
            Imp_Explain(m, "radic")
        Imp_ExplainCMAPs(ctx, side, roots.roots)
        Imp_ExplainLate(ctx, side, roots.roots)
        return res
    }
    ; ---- not localizable
    if (abn.Length() >= 2 && nerve != "") {
        names := []
        for i, m in abn
            names.Push(m.display)
        rootTxt := Util_JoinList(Anat_SortRoots(roots.roots))
        txt := "Neurogenic changes in the " . Util_JoinList(names) . ", in the overlapping distribution of the " . Anat_SideWord(side) . " " . Anat_NerveName(nerve) . " nerve and the " . rootTxt . " myotome" . (roots.roots.Length() > 1 ? "s" : "") . "; these findings do not distinguish between a " . Anat_SideWord(side) . " " . Anat_RootRegion(roots.roots) . " radiculopathy and a " . Anat_SideWord(side) . " " . Anat_NerveName(nerve) . " neuropathy."
        Imp_Add(ctx, 40, txt, "nonspecific")
        for i, m in abn
            Imp_Explain(m, "nonlocalizing")
        return ""
    }
    for i, m in abn {
        Imp_Add(ctx, m.active ? 24 : 18, Imp_IsolatedText(m, Anat_RootRegion(m.def.major.Length() ? m.def.major : m.def.roots)), "nonspecific")
        Imp_Explain(m, "isolated")
    }
    return ""
}

Imp_ChangeWords(m) {
    chronic := m.reinnervation || m.ampM.nascent
    if (m.active && chronic)
        return "active and chronic neurogenic changes"
    if (m.active)
        return "active denervation"
    if (chronic)
        return "chronic neurogenic changes"
    return "reduced recruitment"
}

Imp_IsolatedText(m, region) {
    mild := (Max(m.ampM.grade, m.durM.grade) <= 1 && m.activeGrade <= 1)
    txt := "Isolated, " . (mild ? "mild " : "") . Imp_ChangeWords(m) . " in the " . m.display
    if (!m.active && m.reinnervation)
        txt .= ", without active denervation"
    txt .= "."
    if (region != "" && region != "spinal")
        txt .= " This is a nonspecific finding that does not meet electrodiagnostic criteria for a " . region . " radiculopathy."
    else
        txt .= " This is a nonspecific finding."
    return txt
}

; Minimal set of roots (1-3) covering every abnormal muscle, penalised for
; covering through a minor root only and for normal muscles whose major root is in the set.
Imp_BestRoots(abn, nl, reg) {
    cand := []
    for i, m in abn
        for j, r in m.def.roots
            if ((reg = "C" && RegExMatch(r, "^(C[3-8]|T1)$")) || (reg = "LS" && RegExMatch(r, "^(L[1-5]|S[12])$")))
                Util_ArrPushUnique(cand, r)
    cand := Anat_SortRoots(cand)
    best := "", bestPen := 999999, ties := []
    n := cand.Length()
    sets := []
    Loop, % n
        sets.Push([cand[A_Index]])
    Loop, % n {
        a := A_Index
        Loop, % n - a {
            b := a + A_Index
            sets.Push([cand[a], cand[b]])
            Loop, % n - b {
                c := b + A_Index
                sets.Push([cand[a], cand[b], cand[c]])
            }
        }
    }
    for i, S in sets {
        pen := S.Length() * 10
        ok := true
        for j, m in abn {
            hit := false, majorHit := false
            for k, r in m.def.roots
                if Util_ArrHas(S, r)
                    hit := true
            for k, r in m.def.major
                if Util_ArrHas(S, r)
                    majorHit := true
            if (!hit) {
                ok := false
                break
            }
            if (!majorHit)
                pen += 3
        }
        if (!ok)
            continue
        contra := 0
        for j, m in nl
            for k, r in m.def.major
                if Util_ArrHas(S, r) {
                    contra++
                    break
                }
        pen += 2 * contra
        idx1 := Anat_RootIndex(S[1]), idxN := Anat_RootIndex(S[S.Length()])
        if (idxN - idx1 + 1 > S.Length())
            pen += 4
        if (pen < bestPen) {
            bestPen := pen, best := {roots: S, contra: contra}, ties := [S]
        } else if (pen = bestPen && S.Length() = best.roots.Length())
            ties.Push(S)
    }
    if !IsObject(best)
        return {roots: [], contra: 0}
    if (ties.Length() > 1 && best.roots.Length() = 1) {
        u := []
        for i, S in ties
            for j, r in S
                Util_ArrPushUnique(u, r)
        if (u.Length() <= 2)
            best.roots := Anat_SortRoots(u)
    }
    return best
}

; Most distal nerve element shared by every abnormal muscle ("" if none).
Imp_CommonNerve(abn) {
    common := ""
    for i, m in abn {
        if (m.def.path.Length() = 0)
            return ""
        if !IsObject(common) {
            common := m.def.path.Clone()
            continue
        }
        k := 0
        Loop, % Min(common.Length(), m.def.path.Length()) {
            if (common[A_Index] != m.def.path[A_Index])
                break
            k := A_Index
        }
        if (k = 0)
            return ""
        common.RemoveAt(k + 1, common.Length() - k)
    }
    return IsObject(common) ? common[common.Length()] : ""
}

Imp_BestPlexus(abn, nl, reg) {
    elems := (reg = "C") ? ["UT", "MT", "LT", "LC", "PC", "MC"] : ["LP", "SP"]
    best := {elem: "", contra: 999}
    for i, e in elems {
        all := true
        for j, m in abn
            if !Util_ArrHas(m.def.plexus, e) {
                all := false
                break
            }
        if (!all)
            continue
        contra := 0
        for j, m in nl
            if (Util_ArrHas(m.def.plexus, e) && m.def.plexus.Length() <= 2)
                contra++
        if (contra < best.contra)
            best := {elem: e, contra: contra}
    }
    return best
}

; Status of the SNAPs that test a territory on one side (ignoring SNAPs already
; attributed to another diagnosis, and bilateral leg SNAP loss = generalized).
Imp_SnapStatus(ctx, side, keys) {
    res := {tested: false, abnormal: false, names: [], studies: []}
    for i, st in ctx.rep.sensory {
        if (st.side != side || !Util_ArrHas(keys, st.key))
            continue
        res.tested := true
        if (!st.abnormal || st.explained != "")
            continue
        if ((st.key = "sural" || st.key = "superficialPeroneal") && ctx.lowerSnapBilateral)
            continue
        res.abnormal := true
        res.names.Push(st.name)
        res.studies.Push(st)
    }
    return res
}

; Low CMAP amplitudes in muscles of the involved roots are explained by the
; radiculopathy (axon loss), provided there is no demyelinating-range slowing.
Imp_ExplainCMAPs(ctx, side, roots) {
    global MUSCLE_DB
    recMuscle := {medianAPB: "APB", ulnarADM: "ADM", ulnarFDI: "FDI", peronealEDB: "EDB", peronealTA: "TA", tibialAH: "AH", radialEIP: "EIP"}
    for i, st in ctx.rep.motor {
        if (st.side != side || st.explained != "" || !recMuscle.HasKey(st.key))
            continue
        if (!(st.flags.amp || st.flags.nr) || st.flags.demy || st.flags.anySeg)
            continue
        if (st.flags.lat && st.flags.latRatio > 1.3)
            continue
        md := MUSCLE_DB[recMuscle[st.key]]
        for j, r in md.roots
            if Util_ArrHas(roots, r) {
                st.explained := "radic"
                break
            }
    }
}

Imp_ExplainLate(ctx, side, roots) {
    lateRoots := {median: ["C8", "T1"], ulnar: ["C8", "T1"], peroneal: ["L5", "S1"], tibial: ["S1", "S2"]}
    for k, kind in ["fwave", "hreflex"]
        for i, st in ctx.rep[kind] {
            if (st.side != side || st.explained != "" || !st.flags.any)
                continue
            rr := (kind = "hreflex") ? ["S1"] : lateRoots[st.nerve]
            for j, r in rr
                if Util_ArrHas(roots, r) {
                    st.explained := "radic"
                    break
                }
        }
}

Imp_Chronicity(muscles) {
    global CFG
    act := false, chr := false
    for i, m in muscles {
        if (m.active)
            act := true
        if (m.reinnervation || m.ampM.nascent)
            chr := true
    }
    term := (act && chr) ? CFG.ChronicActiveTerm : act ? "acute" : chr ? "chronic" : ""
    return {active: act, chronic: chr, term: term}
}

Imp_EmitRadic(ctx, list) {
    all := []
    for i, r in list {
        for j, m in r.muscles
            all.Push(m)
        for j, m in r.ps
            all.Push(m)
    }
    ch := Imp_Chronicity(all)
    regAll := []
    for i, r in list
        for j, x in r.roots
            Util_ArrPushUnique(regAll, x)
    region := Anat_RootRegion(regAll)
    if (list.Length() = 2) {
        r := list[1], l := list[2]
        same := (Util_Join(Anat_SortRoots(r.roots)) = Util_Join(Anat_SortRoots(l.roots)))
        sideTxt := "bilateral"
        if (same)
            rootTxt := "of " . Anat_MyotomePhrase(r.roots)
        else
            rootTxt := "of " . Anat_MyotomePhrase(r.roots) . " on the right and " . Anat_MyotomePhrase(l.roots) . " on the left"
        chR := Imp_Chronicity(Imp_Concat(r.muscles, r.ps)), chL := Imp_Chronicity(Imp_Concat(l.muscles, l.ps))
        if (chR.active && chL.active)
            actTxt := "with active denervation"
        else if (chR.active)
            actTxt := "with active denervation on the right"
        else if (chL.active)
            actTxt := "with active denervation on the left"
        else
            actTxt := "without active denervation"
        nRoots := regAll.Length()
    } else {
        r := list[1]
        sideTxt := Anat_SideWord(r.side)
        rootTxt := "of " . Anat_MyotomePhrase(r.roots)
        actTxt := ch.active ? "with active denervation" : "without active denervation"
        nRoots := r.roots.Length()
    }
    lead := (ch.term != "") ? ch.term . ", " . sideTxt : sideTxt
    art := RegExMatch(lead, "i)^[aeiou]") ? "An " : "A "
    txt := art . lead . " " . region . " radiculopathy " . rootTxt . ", " . actTxt . "."
    score := (ch.active ? 75 : 60) + Min(nRoots, 3) + (list.Length() = 2 ? 2 : 0)
    Imp_Add(ctx, score, txt, "radic")
}

Imp_Concat(a, b) {
    out := []
    for i, x in a
        out.Push(x)
    for i, x in b
        out.Push(x)
    return out
}

Imp_EmitMono(ctx, side, nerve, abn, nl) {
    rep := ctx.rep
    ch := Imp_Chronicity(abn)
    name := Anat_NerveName(nerve)
    loc := ""
    if (nerve = "commonPeroneal") {
        bf := Imp_Muscles(rep, ["BFSH"], side)
        loc := (bf.Length() > 0 && !Imp_AnyNeurogenic(bf)) ? "at or near the fibular head" : "non-localizable"
    } else if (nerve = "radialSG") {
        tri := Imp_Muscles(rep, ["TRI", "ANC"], side)
        loc := (tri.Length() > 0 && !Imp_AnyNeurogenic(tri)) ? "at the spiral groove" : "at or above the spiral groove"
    } else if (nerve = "ulnarDeep" || nerve = "ulnar") {
        prox := Imp_Muscles(rep, ["FCU", "FDP45"], side)
        loc := (nerve = "ulnar" && Imp_AnyNeurogenic(prox)) ? "at or above the elbow" : "non-localizable"
    } else
        loc := Anat_NerveLocation(nerve)
    txt := "A " . Anat_SideWord(side) . " " . name . " neuropathy" . ((loc != "" && loc != "non-localizable") ? " " . loc : "") . ", axonal"
    txt .= (loc = "non-localizable") ? ", non-localizable" : ""
    txt .= ch.active ? ", with active denervation." : ", without active denervation."
    Imp_Add(ctx, ch.active ? 68 : 58, txt, "mono")
    for i, m in abn
        Imp_Explain(m, "mono")
    for i, st in ctx.rep.sensory
        if (st.side = side && Util_ArrHas(Anat_NerveSensory(nerve), st.key))
            Imp_Explain(st, "mono")
    nerveMotor := {median: "medianAPB", medianWrist: "medianAPB", ulnar: "ulnarADM", ulnarDeep: "ulnarADM", radial: "radialEIP", radialSG: "radialEIP", PIN: "radialEIP"
        , sciatic: "peronealEDB", commonPeroneal: "peronealEDB", deepPeroneal: "peronealEDB", tibial: "tibialAH"}
    for i, st in ctx.rep.motor
        if (st.side = side && nerveMotor[nerve] != "" && (st.key = nerveMotor[nerve] || (nerve = "sciatic" && st.key = "tibialAH") || (InStr(nerve, "ulnar") && st.key = "ulnarFDI") || (InStr(nerve, "eroneal") && st.key = "peronealTA")))
            Imp_Explain(st, "mono")
}

Imp_EmitPlexus(ctx, side, elem, abn, snap) {
    ch := Imp_Chronicity(abn)
    txt := "A " . Anat_SideWord(side) . " " . Anat_PlexusName(elem) . ", axonal"
    txt .= ch.active ? ", with active denervation." : ", without active denervation."
    Imp_Add(ctx, ch.active ? 85 : 78, txt, "plexus")
    for i, m in abn
        Imp_Explain(m, "plexus")
    for i, st in snap.studies
        Imp_Explain(st, "plexus")
    Imp_ExplainCMAPs(ctx, side, ["C5", "C6", "C7", "C8", "T1", "L2", "L3", "L4", "L5", "S1", "S2"])
}

; ---------------------------------------------------------------------------
; Polyneuropathy
; ---------------------------------------------------------------------------
Imp_Polyneuropathy(ctx) {
    global CFG
    rep := ctx.rep
    pt := rep.patient
    lowerS := [], upperS := [], lowerM := [], upperM := [], lateAbn := []
    for i, st in rep.sensory {
        if (!st.abnormal || st.explained != "" || Imp_IsMinor(st))
            continue
        if (st.key = "saphenous" && pt.age != "" && pt.age >= 40)
            continue
        if (st.limb = "lower")
            lowerS.Push(st)
        else if (st.limb = "upper")
            upperS.Push(st)
    }
    for i, st in rep.motor {
        if (!st.abnormal || st.explained != "" || Imp_IsMinor(st))
            continue
        if (st.limb = "lower")
            lowerM.Push(st)
        else if (st.limb = "upper")
            upperM.Push(st)
    }
    for k, kind in ["fwave", "hreflex"]
        for i, st in rep[kind]
            if (st.flags.any && st.explained = "")
                lateAbn.Push(st)
    total := lowerS.Length() + upperS.Length() + lowerM.Length() + upperM.Length()
    strongLower := false
    sides := {}
    for i, st in lowerS {
        sides[st.side] := true
        if (st.flags.nr || (st.flags.ampRatio != "" && st.flags.ampRatio < 0.5))
            strongLower := true
    }
    if (Util_Count(sides) >= 2)
        strongLower := true
    young := (pt.age = "" || pt.age < 70)
    isPN := (lowerS.Length() >= 1 && (total >= 2 || (strongLower && young)))
    ; non-length-dependent sensory pattern (e.g. sensory neuronopathy)
    nonLD := (lowerS.Length() = 0 && upperS.Length() >= 2 && lowerM.Length() + upperM.Length() = 0)
    if (!isPN && lowerM.Length() >= 2 && lowerS.Length() = 0 && rep.sensory.Length() > 0) {
        ; motor-predominant (e.g. motor neuropathy) - only if CMAPs are abnormal bilaterally
        ms := {}
        for i, st in lowerM
            ms[st.side] := true
        if (Util_Count(ms) >= 2)
            isPN := true
    }
    if (!isPN && !nonLD) {
        if (lowerS.Length() = 1 && !young)
            rep.notes.Push("An isolated abnormal " . lowerS[1].name . " response at age " . pt.age . " can be age-related; it was not called a polyneuropathy.")
        return
    }
    motorInvolved := (lowerM.Length() + upperM.Length() > 0) || ctx.pnEMG
    sensInvolved := (lowerS.Length() + upperS.Length() > 0)
    modality := (motorInvolved && sensInvolved) ? "sensorimotor" : motorInvolved ? "motor" : "sensory"
    ; pathophysiology
    demyN := 0, axonN := 0, cbN := 0
    for i, st in Imp_Concat(lowerM, upperM) {
        if (st.flags.demy)
            demyN++
        if (st.flags.amp || st.flags.nr)
            axonN++
        for j, s in st.flags.segs
            if (s.cb || s.td)
                cbN++
    }
    for i, st in Imp_Concat(lowerS, upperS)
        if (st.flags.amp || st.flags.nr)
            axonN++
    for i, st in lateAbn
        if (st.flags.prolonged && st.checks.Length() && st.checks[1].limit != "" && st.flags.lat > 1.3 * st.checks[1].limit)
            demyN++
    if (demyN >= 2)
        path := (axonN > 0) ? "demyelinating and axonal" : "demyelinating"
    else
        path := "axonal"
    ; severity
    sev := 1
    if (lowerM.Length() > 0 || ctx.pnEMG)
        sev := 2
    upperCount := upperS.Length() + upperM.Length()
    lowerMNR := false
    for i, st in lowerM
        if (st.flags.nr)
            lowerMNR := true
    if (lowerMNR || (upperCount >= 2 && sev >= 2))
        sev := 3
    sevTxt := (sev = 3) ? "severe" : (sev = 2) ? "moderate" : "mild"
    ld := nonLD ? "non-length-dependent" : (lowerS.Length() + lowerM.Length() >= upperS.Length() + upperM.Length()) ? "length-dependent" : "non-length-dependent"
    txt := "A " . sevTxt . ", " . ld . ", " . path . ", " . modality . ", large-fiber polyneuropathy"
    ind := Util_Lower(pt.indication . " " . pt.history)
    if (CFG.MarkIncidentalPolyneuropathy && pt.indication != "" && !RegExMatch(Util_Lower(pt.indication), "neuropath|polyneur|numb|tingl|paresth|sensory|burning|feet|stocking|diabet"))
        txt .= "; incidental finding"
    txt .= "."
    if (ld = "non-length-dependent" && modality = "sensory")
        txt .= " In this clinical context, a sensory neuronopathy (ganglionopathy) should be considered."
    else if (cbN >= 2 && InStr(path, "demyelinating"))
        txt .= " The presence of conduction block or temporal dispersion at non-entrapment sites suggests an acquired demyelinating process."
    Imp_Add(ctx, (sev = 3) ? 85 : (sev = 2) ? 68 : 50, txt, "pn")
    ctx.pn := true
    for i, st in Imp_Concat(Imp_Concat(lowerS, upperS), Imp_Concat(lowerM, upperM))
        Imp_Explain(st, "PN")
    for i, st in lateAbn
        Imp_Explain(st, "PN")
    ; median studies left unexplained because the CTS check deferred to polyneuropathy
    for i, st in rep.sensory
        if (st.abnormal && st.explained = "")
            Imp_Explain(st, "PN")
}

; ---------------------------------------------------------------------------
; Anything still unexplained
; ---------------------------------------------------------------------------
Imp_Leftovers(ctx) {
    rep := ctx.rep
    parts := [], borderParts := []
    for k, kind in ["sensory", "motor"] {
        for i, st in rep[kind] {
            if (!st.abnormal || st.explained != "")
                continue
            ph := Imp_ShortFindings(st)
            if (Imp_IsMinor(st))
                borderParts.Push("the " . st.name . " (" . ph . ")")
            else
                parts.Push("the " . st.name . " (" . ph . ")")
        }
    }
    for k, kind in ["fwave", "hreflex"] {
        for i, st in rep[kind] {
            if (!st.flags.any || st.explained != "")
                continue
            noun := (kind = "fwave") ? "F-wave" : "H-reflex"
            what := st.flags.absent ? "absent" : st.flags.relProlonged ? "prolonged relative to the " . st.flags.relTo : "prolonged latency"
            parts.Push("the " . st.name . " " . noun . " (" . what . ")")
        }
    }
    other := []
    for i, m in rep.emg {
        if (!m.abnormal || m.explained != "" || m.neurogenic || m.myopathic)
            continue
        ph := Assess_MusclePhrase(m)
        if (ph != "")
            other.Push(RegExReplace(ph, "^The (.*) showed (.*)\.$", "$2 in the $1"))
    }
    if (parts.Length() > 0)
        Imp_Add(ctx, 15, "Nonspecific abnormalities of " . Util_JoinList(parts) . ", of uncertain clinical significance.", "nonspecific")
    if (other.Length() > 0)
        Imp_Add(ctx, 14, Util_CapFirst(Util_JoinList(other)) . ", which " . (other.Length() > 1 ? "are" : "is") . " nonspecific and of uncertain clinical significance.", "nonspecific")
    if (borderParts.Length() > 0) {
        t := "Borderline abnormalities of " . Util_JoinList(borderParts) . ", of uncertain clinical significance."
        Imp_Add(ctx, 10, t, "borderline", true, "There " . (borderParts.Length() > 1 ? "are" : "is") . " " . Util_LowerFirst(StrReplace(t, "Borderline abnormalities", borderParts.Length() > 1 ? "borderline abnormalities" : "a borderline abnormality")))
    }
}

; True when every abnormal value is within CFG.MinorFraction of its limit.
Imp_IsMinor(st) {
    global CFG
    worst := 0
    for i, c in st.checks {
        if (!c.abnormal)
            continue
        if (c.value = "NR" || c.limit = "" || c.limit = 0)
            return false
        worst := Max(worst, Abs(c.value - c.limit) / Abs(c.limit))
    }
    return worst <= CFG.MinorFraction
}

Imp_ShortFindings(st) {
    f := st.flags
    if (f.nr)
        return "absent response"
    items := []
    if (f.lat)
        items.Push(st.kind = "motor" ? "prolonged distal latency" : "prolonged latency")
    if (f.amp)
        items.Push("low amplitude")
    if (f.cv)
        items.Push("slow conduction velocity")
    if (st.kind = "motor")
        for i, s in f.segs {
            if (s.slow || s.relSlow)
                items.Push("slowing " . s.region)
            if (s.cb)
                items.Push("conduction block " . s.region)
            if (s.td)
                items.Push("temporal dispersion " . s.region)
            if (s.nrProx)
                items.Push("no response " . Assess_SitePhrase(s.site))
        }
    for i, e in st.extra
        items.Push("abnormal " . Util_Lower(e.site) . " stimulation")
    return Util_JoinList(items)
}

; ---------------------------------------------------------------------------
; Final text
; ---------------------------------------------------------------------------
Imp_LimbsPhrase(rep) {
    has := {}
    for k, kind in ["sensory", "motor", "fwave", "hreflex"]
        for i, st in rep[kind]
            if (st.limb != "")
                Imp_MarkLimb(has, st.side, st.limb)
    for i, m in rep.emg
        if (m.key != "" && (m.def.limb = "upper" || m.def.limb = "lower"))
            Imp_MarkLimb(has, m.side, m.def.limb)
    ru := has.HasKey("RU"), lu := has.HasKey("LU"), rl := has.HasKey("RL"), ll := has.HasKey("LL")
    n := ru + lu + rl + ll
    if (n = 0)
        return ""
    if (n = 4)
        return "bilateral upper and lower extremities"
    if (n = 2 && ru && lu)
        return "bilateral upper extremities"
    if (n = 2 && rl && ll)
        return "bilateral lower extremities"
    lst := []
    if (ru)
        lst.Push("right upper")
    if (lu)
        lst.Push("left upper")
    if (rl)
        lst.Push("right lower")
    if (ll)
        lst.Push("left lower")
    return Util_JoinList(lst) . (n = 1 ? " extremity" : " extremities")
}

Imp_MarkLimb(has, side, limb) {
    l := (limb = "upper") ? "U" : "L"
    if (side = "R" || side = "B")
        has["R" . l] := true
    if (side = "L" || side = "B")
        has["L" . l] := true
}

Imp_DefaultIndication(rep) {
    lp := Imp_LimbsPhrase(rep)
    up := InStr(lp, "upper"), lo := InStr(lp, "lower")
    if (up && !lo)
        return "a cervical radiculopathy, brachial plexopathy, mononeuropathy, or large-fiber polyneuropathy"
    if (lo && !up)
        return "a lumbosacral radiculopathy, plexopathy, mononeuropathy, or large-fiber polyneuropathy"
    return "a radiculopathy, plexopathy, mononeuropathy, myopathy, or large-fiber polyneuropathy"
}

Imp_Assemble(ctx) {
    global CFG
    rep := ctx.rep
    items := ctx.items
    ; stable sort by score (desc)
    sorted := []
    for i, it in items {
        pos := sorted.Length() + 1
        for j, s in sorted
            if (it.score > s.score) {
                pos := j
                break
            }
        sorted.InsertAt(pos, it)
    }
    ind := (rep.patient.indication != "") ? rep.patient.indication : Imp_DefaultIndication(rep)
    limbs := Imp_LimbsPhrase(rep)
    ofLimbs := (limbs != "") ? " of the " . limbs : ""
    major := [], minor := []
    for i, it in sorted
        if (it.minor)
            minor.Push(it)
        else
            major.Push(it)
    if (major.Length() = 0) {
        if (minor.Length() = 0)
            return "This is a normal electrodiagnostic study. No electrophysiological evidence of " . ind . " was found."
        txt := "This is an essentially normal electrodiagnostic study" . ofLimbs . ". No electrophysiological evidence of " . ind . " was found."
        for i, it in minor
            txt .= " " . it.sentence
        return txt
    }
    head := "This is an abnormal electrodiagnostic study" . ofLimbs . " which shows evidence of"
    if (sorted.Length() = 1)
        return head . " " . Util_LowerFirst(sorted[1].text)
    txt := head . ":"
    for i, it in sorted
        txt .= "`r`n" . StrReplace(CFG.NumberedListFormat, "{1}", i) . it.text
    return txt
}
