; =============================================================================
; Normals.ahk - reference values.
;
; Primary source (AANEM):
;   Chen S, Andary M, Buschbacher R, et al. Electrodiagnostic reference values for
;   upper and lower limb nerve conduction studies in adult populations.
;   AANEM Normative Data Task Force. Muscle Nerve 2016;54:371-377
;   (AANEM NDTF chart, revised 4/2020). Upper limits = 97th percentile,
;   lower limits = 3rd percentile. Ages 19-79.
;
; Supplemental (nerves/measures the NDTF did not cover):
;   Preston DC, Shapiro BE. Electromyography and Neuromuscular Disorders, 4th ed.
;   Buschbacher RM. Sural and saphenous 14-cm antidromic studies. AJPMR 2003.
;
; Every getter returns an object; a missing key means "no reference value".
; =============================================================================

global NORM_SRC_AANEM := "AANEM 2016"
global NORM_SRC_PRESTON := "Preston & Shapiro"

Norm_AgeBand(age, bands) {
    ; bands: array of upper bounds, e.g. [39, 59] -> 1 (<=39), 2 (40-59), 3 (60+)
    if (age = "")
        return 0
    for i, ub in bands
        if (age <= ub)
            return i
    return bands.Length() + 1
}

Norm_BMIGroup(pt) {
    global CFG
    if (pt.bmi != "")
        return (pt.bmi < 24) ? "low" : "high"
    return CFG.DefaultBMIGroup
}

; -----------------------------------------------------------------------------
; Sensory nerves. Keys: median, medianPalm, ulnar, ulnarPalm, radial, sural,
; superficialPeroneal, saphenous, labc, mabc, duc, medianD4, ulnarD4, medianD1
; Returns {peak, onset, dist (cm), amp, cv, src, note}
; -----------------------------------------------------------------------------
Norm_Sensory(key, pt) {
    global CFG, NORM_SRC_AANEM, NORM_SRC_PRESTON
    pp := (CFG.SensoryAmpMethod = "PP")
    age := pt.age
    n := {}
    if (key = "median" || key = "medianD3") {
        n := {peak: 4.0, onset: 3.3, dist: 14, cv: 43, src: NORM_SRC_AANEM}
        n.amp := pp ? 13 : 11
        bmi := Norm_BMIGroup(pt)
        if (age != "" && bmi != "all") {
            young := (age < 50)
            if (pp)
                n.amp := young ? (bmi = "low" ? 19 : 13) : (bmi = "low" ? 15 : 8)
            else
                n.amp := young ? (bmi = "low" ? 17 : 11) : (bmi = "low" ? 9 : 7)
            n.note := "age " . (young ? "19-49" : "50-79") . ", BMI " . (bmi = "low" ? "<24" : ">=24")
        }
    } else if (key = "medianPalm") {
        n := {peak: 2.3, onset: 1.6, dist: 7, amp: (pp ? 8 : 6), cv: 43, src: NORM_SRC_AANEM}
    } else if (key = "ulnar") {
        n := {peak: 4.0, onset: 3.1, dist: 14, cv: 45, src: NORM_SRC_AANEM}
        n.amp := pp ? 9 : 10
        bmi := Norm_BMIGroup(pt)
        if (age != "" && bmi != "all") {
            young := (age < 50)
            if (pp)
                n.amp := young ? (bmi = "low" ? 13 : 8) : (bmi = "low" ? 13 : 4)
            else
                n.amp := young ? (bmi = "low" ? 14 : 11) : (bmi = "low" ? 10 : 5)
            n.note := "age " . (young ? "19-49" : "50-79") . ", BMI " . (bmi = "low" ? "<24" : ">=24")
        }
    } else if (key = "radial") {
        n := {peak: 2.8, onset: 2.2, dist: 10, amp: (pp ? 11 : 7), cv: 50, src: NORM_SRC_AANEM}
    } else if (key = "sural") {
        n := {peak: 4.5, onset: 3.6, dist: 14, amp: 4, cv: 40, src: NORM_SRC_AANEM}
    } else if (key = "mabc") {
        n := {peak: 2.6, dist: 10, amp: (pp ? 3 : 4), src: NORM_SRC_AANEM}
    } else if (key = "labc") {
        n := {peak: 2.5, dist: 10, amp: (pp ? 6 : 5), src: NORM_SRC_AANEM}
    } else if (key = "superficialPeroneal") {
        n := {peak: 4.4, dist: 14, amp: 6, cv: 40, src: NORM_SRC_PRESTON}
        if (age != "" && age >= 60)
            n.amp := 4, n.note := "age 60+"
    } else if (key = "saphenous") {
        n := {peak: 4.4, onset: 3.8, dist: 14, amp: 4, cv: 40, src: NORM_SRC_PRESTON}
        if (age != "" && age >= 40)
            n.amp := 2, n.src := "Buschbacher 2003", n.note := "age 40+"
    } else if (key = "duc") {
        n := {peak: 2.5, dist: 8, amp: 8, cv: 50, src: NORM_SRC_PRESTON}
    } else if (key = "ulnarPalm") {
        n := {peak: 2.2, dist: 8, amp: 15, cv: 50, src: NORM_SRC_PRESTON}
    } else if (key = "medianPalmMixed") {
        n := {peak: 2.2, dist: 8, amp: 50, cv: 50, src: NORM_SRC_PRESTON}
    }
    if (age != "" && (age < 19 || age > 79))
        n.ageWarn := true
    return n
}

; -----------------------------------------------------------------------------
; Motor nerves. Keys: medianAPB, ulnarADM, ulnarFDI, peronealEDB, peronealTA,
; tibialAH, radialEIP, femoral
; Returns {lat, amp, dist, cv: {segType: LLN}, cvDefault, cb: {segType: %drop},
;          cvDropAbs, cvDropPct (focal slowing limits), src}
; Segment types: forearm, acrossElbow, aboveElbow, axilla, leg, acrossFH,
;                aboveFH, knee, generic
; -----------------------------------------------------------------------------
Norm_Motor(key, pt) {
    global NORM_SRC_AANEM, NORM_SRC_PRESTON
    age := pt.age, sex := pt.sex, ht := pt.heightCm
    n := {cv: {}, cb: {forearm: 30, acrossElbow: 20, aboveElbow: 20, axilla: 30, leg: 32, acrossFH: 25, aboveFH: 25, knee: 71, generic: 30}}
    if (key = "medianAPB") {
        n.src := NORM_SRC_AANEM, n.dist := 8
        if (sex = "M")
            n.lat := (age != "" && age >= 50) ? 4.7 : 4.6
        else if (sex = "F")
            n.lat := 4.4
        else
            n.lat := 4.5
        band := Norm_AgeBand(age, [39, 59])
        n.amp := (band = 1) ? 5.9 : (band = 2) ? 4.2 : (band = 3) ? 3.8 : 4.1
        if (age != "" && age < 40)
            cv := (sex = "F") ? 53 : (sex = "M") ? 49 : 49
        else if (age != "")
            cv := (sex = "F") ? 51 : (sex = "M") ? 47 : 49
        else
            cv := 49
        n.cvDefault := cv
        n.cv.forearm := cv
    } else if (key = "ulnarADM" || key = "ulnarFDI") {
        if (key = "ulnarADM")
            n.src := NORM_SRC_AANEM, n.dist := 8, n.lat := 3.7, n.amp := 7.9
        else
            n.src := NORM_SRC_PRESTON . " (DL/amp); AANEM (CV)", n.dist := 9, n.lat := 4.5, n.amp := 7.0
        n.cv.forearm := 52, n.cv.acrossElbow := 43, n.cv.aboveElbow := 50
        n.cvDefault := 50
        n.cvDropAbs := 15, n.cvDropPct := 23, n.focalSeg := "acrossElbow", n.focalRef := "forearm"
    } else if (key = "peronealEDB" || key = "peronealTA") {
        if (key = "peronealEDB") {
            n.src := NORM_SRC_AANEM, n.dist := 8, n.lat := 6.5
            n.amp := (age = "") ? 1.3 : (age < 40) ? 2.6 : 1.1
            if (age != "" && ht != "")
                n.cv.leg := (age < 40) ? (ht < 170 ? 43 : 37) : (ht < 170 ? 39 : 36)
            else
                n.cv.leg := 38
        } else {
            n.src := NORM_SRC_PRESTON . " (DL/amp); AANEM (CV)", n.dist := 10, n.lat := 6.7, n.amp := 3.0
            n.cv.leg := 44
        }
        n.cv.acrossFH := 42, n.cv.aboveFH := 42
        n.cvDefault := 38
        n.cvDropAbs := 6, n.cvDropPct := 12, n.focalSeg := "acrossFH", n.focalRef := "leg"
    } else if (key = "tibialAH") {
        n.src := NORM_SRC_AANEM, n.dist := 8, n.lat := 6.1
        band := Norm_AgeBand(age, [29, 59])
        n.amp := (band = 1) ? 5.8 : (band = 2) ? 5.3 : (band = 3) ? 1.1 : 4.4
        if (age != "" && ht != "") {
            if (age < 50)
                n.cv.knee := (ht < 160) ? 44 : (ht < 170) ? 42 : 37
            else
                n.cv.knee := (ht < 160) ? 40 : (ht < 170) ? 37 : 34
        } else
            n.cv.knee := 39
        n.cvDefault := n.cv.knee
    } else if (key = "radialEIP") {
        n.src := NORM_SRC_PRESTON, n.dist := 6, n.lat := 2.9, n.amp := 2.0
        n.cvDefault := 49
    } else if (key = "femoral") {
        n.src := "AANEM coursebook", n.amp := (age != "" && age >= 40) ? 0.8 : 3.7
    } else
        return {}
    if (age != "" && (age < 19 || age > 79))
        n.ageWarn := true
    return n
}

; -----------------------------------------------------------------------------
; Late responses (Preston & Shapiro adult limits; height-independent).
; -----------------------------------------------------------------------------
Norm_FWave(nerve) {
    global NORM_SRC_PRESTON
    if (nerve = "median")
        return {lat: 31, sideDiff: 2.0, src: NORM_SRC_PRESTON}
    if (nerve = "ulnar")
        return {lat: 32, sideDiff: 2.0, src: NORM_SRC_PRESTON}
    if (nerve = "peroneal")
        return {lat: 56, sideDiff: 4.0, src: NORM_SRC_PRESTON}
    if (nerve = "tibial")
        return {lat: 56, sideDiff: 4.0, src: NORM_SRC_PRESTON}
    return {}
}

Norm_HReflex() {
    global NORM_SRC_PRESTON
    return {lat: 34, sideDiff: 1.5, src: NORM_SRC_PRESTON}
}

; -----------------------------------------------------------------------------
; Internal comparison studies (latency differences, ms; abnormal if greater).
; -----------------------------------------------------------------------------
Norm_Comparison(kind, pt) {
    global NORM_SRC_AANEM, NORM_SRC_PRESTON
    if (kind = "medianUlnarSensory")      ; D2/D3 vs D5, identical distance, peak latency
        return {limit: 0.4, src: NORM_SRC_AANEM}
    if (kind = "medianUlnarMotor")        ; APB vs ADM distal latency, identical distance
        return {limit: (pt.age != "" && pt.age >= 50) ? 1.7 : 1.4, src: NORM_SRC_AANEM}
    if (kind = "medianUlnarPalm")         ; mixed palmar, 8 cm
        return {limit: 0.3, src: NORM_SRC_PRESTON}
    if (kind = "medianUlnarD4")           ; ring finger, 14 cm
        return {limit: 0.4, src: NORM_SRC_PRESTON}
    if (kind = "medianRadialD1")          ; thumb, 10 cm
        return {limit: 0.4, src: NORM_SRC_PRESTON}
    return {}
}

; Segment-specific conduction-velocity limit, falling back to the nerve default.
Norm_SegCV(norm, segType) {
    if (norm.cv.HasKey(segType))
        return norm.cv[segType]
    return norm.cvDefault
}

Norm_SegCB(norm, segType) {
    if (norm.cb.HasKey(segType))
        return norm.cb[segType]
    return 30
}
