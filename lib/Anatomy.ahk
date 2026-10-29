; =============================================================================
; Anatomy.ahk - muscle, root, nerve and plexus reference table plus fuzzy name
; matching for muscles, nerves and stimulation sites.
;
; Root assignments follow Preston & Shapiro (Electromyography and Neuromuscular
; Disorders, 4th ed., myotome tables) and the AANEM root/plexus charts:
;   roots  = every root that contributes to the muscle
;   major  = the predominant root(s); used first when choosing the root level
;   path   = peripheral nerve elements, proximal > distal (used for mononeuropathy)
;   plexus = UT/MT/LT (trunks), LC/PC/MC (cords), LP (lumbar plexus),
;            SP (sacral plexus); empty for root-level nerves and paraspinals
;   limb   = upper | lower | axial | bulbar
;   region = cervical | thoracic | lumbosacral | bulbar  (for MND region counting)
;   flags  = prox (proximal muscle), distleg (distal leg), foot (foot intrinsic),
;            paraspinal
; =============================================================================

global MUSCLE_DB := {}
global MUSCLE_ALIAS := []        ; [{alias, key, tokens}]
global ROOT_ORDER := ["C3","C4","C5","C6","C7","C8","T1","T2","T3","T4","T5","T6","T7","T8","T9","T10","T11","T12","L1","L2","L3","L4","L5","S1","S2"]

Anat_M(key, display, full, limb, region, path, roots, major, plexus, flags, aliases) {
    global MUSCLE_DB, MUSCLE_ALIAS
    m := {key: key, display: display, full: full, limb: limb, region: region}
    m.path := Util_Split(path, ">")
    m.nerve := m.path.Length() ? m.path[m.path.Length()] : ""
    m.roots := Util_Split(roots, ",")
    m.major := Util_Split(major, ",")
    m.plexus := Util_Split(plexus, ",")
    m.flags := {}
    for i, f in Util_Split(flags, ",")
        m.flags[f] := true
    MUSCLE_DB[key] := m
    all := Util_Split(aliases, "|")
    all.Push(full)
    all.Push(display)
    for i, a in all {
        na := Anat_NormMuscle(a)
        if (na != "")
            MUSCLE_ALIAS.Push({alias: na, key: key, tokens: StrSplit(na, " ")})
    }
}

Anat_Init() {
    static done := false
    if (done)
        return
    done := true
    ; ---------------------------------------------------------------- hand
    Anat_M("APB", "APB", "Abductor Pollicis Brevis", "upper", "cervical", "median>medianWrist", "C8,T1", "C8,T1", "LT,MC", "", "abductor pollicis brevis|abd pollicis brevis|abductor pol brevis|abd poll brevis|apb")
    Anat_M("OPP", "Opponens Pollicis", "Opponens Pollicis", "upper", "cervical", "median>medianWrist", "C8,T1", "C8,T1", "LT,MC", "", "opponens pollicis|opponens|opp pollicis|op")
    Anat_M("FDI", "FDI", "First Dorsal Interosseous", "upper", "cervical", "ulnar>ulnarDeep", "C8,T1", "C8,T1", "LT,MC", "", "first dorsal interosseous|1st dorsal interosseous|first dorsal interossei|first dorsal interosseus|dorsal interosseous|1st di|fdi|first di|di 1|1 di|1st dorsal interossei")
    Anat_M("ADM", "ADM", "Abductor Digiti Minimi", "upper", "cervical", "ulnar>ulnarDeep", "C8,T1", "C8,T1", "LT,MC", "", "abductor digiti minimi|abductor digiti quinti|abd digiti minimi|abductor digiti minimi manus|adq|adm|abd dig min")
    Anat_M("ADP", "Adductor Pollicis", "Adductor Pollicis", "upper", "cervical", "ulnar>ulnarDeep", "C8,T1", "C8,T1", "LT,MC", "", "adductor pollicis|add pollicis|adp")
    ; ---------------------------------------------------------------- forearm
    Anat_M("FCU", "FCU", "Flexor Carpi Ulnaris", "upper", "cervical", "ulnar", "C7,C8,T1", "C8", "MT,LT,MC", "", "flexor carpi ulnaris|flex carpi ulnaris|fcu")
    Anat_M("FDP45", "FDP (4,5)", "Flexor Digitorum Profundus (ulnar)", "upper", "cervical", "ulnar", "C7,C8,T1", "C8", "LT,MC", "", "flexor digitorum profundus 4 5|flexor digitorum profundus iv v|fdp 4 5|fdp iv v|fdp45|fdp ulnar|flexor digitorum profundus ulnar|flexor digitorum profundus|fdp|fdp 4|fdp 5|fdp v|fdp iv")
    Anat_M("FDP23", "FDP (2,3)", "Flexor Digitorum Profundus (median)", "upper", "cervical", "median>AIN", "C7,C8,T1", "C8", "MT,LT,LC,MC", "", "flexor digitorum profundus 2 3|flexor digitorum profundus ii iii|fdp 2 3|fdp ii iii|fdp23|fdp median|flexor digitorum profundus median|fdp 2|fdp ii")
    Anat_M("FPL", "FPL", "Flexor Pollicis Longus", "upper", "cervical", "median>AIN", "C7,C8,T1", "C8", "MT,LT,LC,MC", "", "flexor pollicis longus|flex pollicis longus|fpl")
    Anat_M("PQ", "Pronator Quadratus", "Pronator Quadratus", "upper", "cervical", "median>AIN", "C7,C8,T1", "C8", "MT,LT,LC,MC", "", "pronator quadratus|pq")
    Anat_M("FDS", "FDS", "Flexor Digitorum Superficialis", "upper", "cervical", "median", "C7,C8,T1", "C8", "MT,LT,LC,MC", "", "flexor digitorum superficialis|flexor digitorum sublimis|fds")
    Anat_M("FCR", "FCR", "Flexor Carpi Radialis", "upper", "cervical", "median", "C6,C7", "C6,C7", "UT,MT,LC", "", "flexor carpi radialis|flex carpi radialis|fcr")
    Anat_M("PT", "PT", "Pronator Teres", "upper", "cervical", "median", "C6,C7", "C6,C7", "UT,MT,LC", "", "pronator teres|pron teres|pt")
    Anat_M("EIP", "EIP", "Extensor Indicis Proprius", "upper", "cervical", "radial>radialSG>PIN", "C7,C8", "C8", "MT,LT,PC", "", "extensor indicis proprius|extensor indicis|ext indicis proprius|ext indicis|eip|ei")
    Anat_M("EDC", "EDC", "Extensor Digitorum Communis", "upper", "cervical", "radial>radialSG>PIN", "C7,C8", "C7", "MT,LT,PC", "", "extensor digitorum communis|extensor digitorum|ext digitorum communis|ext digitorum|edc")
    Anat_M("ECU", "ECU", "Extensor Carpi Ulnaris", "upper", "cervical", "radial>radialSG>PIN", "C7,C8", "C7,C8", "MT,LT,PC", "", "extensor carpi ulnaris|ext carpi ulnaris|ecu")
    Anat_M("EPB", "EPB", "Extensor Pollicis Brevis", "upper", "cervical", "radial>radialSG>PIN", "C7,C8", "C7,C8", "MT,LT,PC", "", "extensor pollicis brevis|ext pollicis brevis|epb")
    Anat_M("EPL", "EPL", "Extensor Pollicis Longus", "upper", "cervical", "radial>radialSG>PIN", "C7,C8", "C7,C8", "MT,LT,PC", "", "extensor pollicis longus|ext pollicis longus|epl")
    Anat_M("APL", "APL", "Abductor Pollicis Longus", "upper", "cervical", "radial>radialSG>PIN", "C7,C8", "C7,C8", "MT,LT,PC", "", "abductor pollicis longus|abd pollicis longus|apl")
    Anat_M("SUP", "Supinator", "Supinator", "upper", "cervical", "radial>radialSG>PIN", "C5,C6,C7", "C6", "UT,PC", "", "supinator")
    Anat_M("ECR", "ECR", "Extensor Carpi Radialis", "upper", "cervical", "radial>radialSG", "C6,C7", "C6,C7", "UT,MT,PC", "", "extensor carpi radialis|extensor carpi radialis longus|extensor carpi radialis brevis|ext carpi radialis|ecrl|ecrb|ecr")
    Anat_M("BR", "Brachioradialis", "Brachioradialis", "upper", "cervical", "radial>radialSG", "C5,C6", "C5,C6", "UT,PC", "prox", "brachioradialis|brachio radialis|br")
    ; ---------------------------------------------------------------- arm / shoulder
    Anat_M("TRI", "Triceps", "Triceps", "upper", "cervical", "radial", "C6,C7,C8", "C7", "UT,MT,LT,PC", "prox", "triceps|triceps brachii|tricep|triceps lateral head|triceps long head|triceps medial head|triceps lat head")
    Anat_M("ANC", "Anconeus", "Anconeus", "upper", "cervical", "radial", "C7,C8", "C7,C8", "MT,LT,PC", "", "anconeus")
    Anat_M("BIC", "Biceps", "Biceps", "upper", "cervical", "musculocutaneous", "C5,C6", "C5,C6", "UT,LC", "prox", "biceps|biceps brachii|bicep|biceps brachi")
    Anat_M("BRA", "Brachialis", "Brachialis", "upper", "cervical", "musculocutaneous", "C5,C6", "C5,C6", "UT,LC", "prox", "brachialis")
    Anat_M("DEL", "Deltoid", "Deltoid", "upper", "cervical", "axillary", "C5,C6", "C5,C6", "UT,PC", "prox", "deltoid|deltoid middle|middle deltoid|mid deltoid|deltoid anterior|anterior deltoid|ant deltoid|deltoid posterior|posterior deltoid|deltoideus|deltoid med")
    Anat_M("TMIN", "Teres Minor", "Teres Minor", "upper", "cervical", "axillary", "C5,C6", "C5", "UT,PC", "prox", "teres minor")
    Anat_M("SUPRA", "Supraspinatus", "Supraspinatus", "upper", "cervical", "suprascapular", "C5,C6", "C5,C6", "UT", "prox", "supraspinatus|supra spinatus")
    Anat_M("INFRA", "Infraspinatus", "Infraspinatus", "upper", "cervical", "suprascapular", "C5,C6", "C5,C6", "UT", "prox", "infraspinatus|infra spinatus")
    Anat_M("RHO", "Rhomboid", "Rhomboid", "upper", "cervical", "dorsalScapular", "C4,C5", "C5", "", "prox", "rhomboid|rhomboids|rhomboid major|rhomboid minor")
    Anat_M("SA", "Serratus Anterior", "Serratus Anterior", "upper", "cervical", "longThoracic", "C5,C6,C7", "C6,C7", "", "prox", "serratus anterior|serratus")
    Anat_M("LAT", "Latissimus Dorsi", "Latissimus Dorsi", "upper", "cervical", "thoracodorsal", "C6,C7,C8", "C7", "UT,MT,LT,PC", "prox", "latissimus dorsi|latissimus|lat dorsi")
    Anat_M("PEC", "Pectoralis Major", "Pectoralis Major", "upper", "cervical", "pectoral", "C5,C6,C7,C8,T1", "C6,C7", "UT,MT,LT,LC,MC", "prox", "pectoralis major|pectoralis|pec major|pectoralis major clavicular|pectoralis major sternal")
    Anat_M("TMAJ", "Teres Major", "Teres Major", "upper", "cervical", "lowerSubscapular", "C5,C6,C7", "C6", "UT,MT,PC", "prox", "teres major")
    Anat_M("TRAP", "Trapezius", "Trapezius", "axial", "cervical", "accessory", "C3,C4", "", "", "prox", "trapezius|upper trapezius|trap|lower trapezius|middle trapezius")
    Anat_M("SCM", "Sternocleidomastoid", "Sternocleidomastoid", "bulbar", "bulbar", "accessory", "", "", "", "prox", "sternocleidomastoid|scm|sternomastoid")
    ; ---------------------------------------------------------------- axial
    Anat_M("CPS", "Cervical Paraspinals", "Cervical Paraspinals", "axial", "cervical", "", "C4,C5,C6,C7,C8,T1", "", "", "paraspinal,prox", "cervical paraspinals|cervical paraspinal|c paraspinals|cervical psp|paraspinals cervical|cervical paraspinal muscles|cervical multifidus|c spine paraspinals|cervical ps")
    Anat_M("TPS", "Thoracic Paraspinals", "Thoracic Paraspinals", "axial", "thoracic", "", "T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12", "", "", "paraspinal,prox", "thoracic paraspinals|thoracic paraspinal|t paraspinals|thoracic psp|paraspinals thoracic|thoracic ps")
    Anat_M("LPS", "Lumbar Paraspinals", "Lumbar Paraspinals", "axial", "lumbosacral", "", "L1,L2,L3,L4,L5,S1", "", "", "paraspinal,prox", "lumbar paraspinals|lumbar paraspinal|lumbosacral paraspinals|lumbosacral paraspinal|l paraspinals|lumbar psp|paraspinals lumbar|lumbar multifidus|multifidus|ls paraspinals|lumbar ps|sacral paraspinals")
    Anat_M("RA", "Rectus Abdominis", "Rectus Abdominis", "axial", "thoracic", "", "T6,T7,T8,T9,T10,T11,T12", "", "", "prox", "rectus abdominis|rectus abdominus|rectus abd|abdominal|abdominals")
    ; ---------------------------------------------------------------- bulbar
    Anat_M("GG", "Genioglossus", "Genioglossus", "bulbar", "bulbar", "hypoglossal", "", "", "", "", "genioglossus|tongue|genioglossal")
    Anat_M("MASS", "Masseter", "Masseter", "bulbar", "bulbar", "trigeminal", "", "", "", "", "masseter")
    Anat_M("FRON", "Frontalis", "Frontalis", "bulbar", "bulbar", "facial", "", "", "", "", "frontalis")
    Anat_M("OOC", "Orbicularis Oculi", "Orbicularis Oculi", "bulbar", "bulbar", "facial", "", "", "", "", "orbicularis oculi|orb oculi")
    Anat_M("OOR", "Orbicularis Oris", "Orbicularis Oris", "bulbar", "bulbar", "facial", "", "", "", "", "orbicularis oris|orb oris")
    Anat_M("MENT", "Mentalis", "Mentalis", "bulbar", "bulbar", "facial", "", "", "", "", "mentalis")
    ; ---------------------------------------------------------------- leg
    Anat_M("TA", "TA", "Tibialis Anterior", "lower", "lumbosacral", "sciatic>commonPeroneal>deepPeroneal", "L4,L5", "L5", "SP", "distleg", "tibialis anterior|tib anterior|tib ant|anterior tibialis|tibialis ant|ant tibialis|ta|tibialis anterio|tibial anterior")
    Anat_M("EHL", "EHL", "Extensor Hallucis Longus", "lower", "lumbosacral", "sciatic>commonPeroneal>deepPeroneal", "L5,S1", "L5", "SP", "distleg", "extensor hallucis longus|ext hallucis longus|ehl")
    Anat_M("EDL", "EDL", "Extensor Digitorum Longus", "lower", "lumbosacral", "sciatic>commonPeroneal>deepPeroneal", "L5,S1", "L5", "SP", "distleg", "extensor digitorum longus|ext digitorum longus|edl")
    Anat_M("EDB", "EDB", "Extensor Digitorum Brevis", "lower", "lumbosacral", "sciatic>commonPeroneal>deepPeroneal", "L5,S1", "L5,S1", "SP", "distleg,foot", "extensor digitorum brevis|ext digitorum brevis|edb")
    Anat_M("PL", "Peroneus Longus", "Peroneus Longus", "lower", "lumbosacral", "sciatic>commonPeroneal>superficialPeroneal", "L5,S1", "L5,S1", "SP", "distleg", "peroneus longus|fibularis longus|peroneal longus|peroneus|peroneus long|pl|fibularis")
    Anat_M("PB", "Peroneus Brevis", "Peroneus Brevis", "lower", "lumbosacral", "sciatic>commonPeroneal>superficialPeroneal", "L5,S1", "L5,S1", "SP", "distleg", "peroneus brevis|fibularis brevis|pb")
    Anat_M("TP", "Tibialis Posterior", "Tibialis Posterior", "lower", "lumbosacral", "sciatic>tibial", "L5,S1", "L5", "SP", "distleg", "tibialis posterior|posterior tibialis|tib post|tibialis post|tp|tib posterior")
    Anat_M("FDL", "Flexor Digitorum Longus", "Flexor Digitorum Longus", "lower", "lumbosacral", "sciatic>tibial", "L5,S1,S2", "L5,S1", "SP", "distleg", "flexor digitorum longus|flex digitorum longus|fdl")
    Anat_M("FHL", "Flexor Hallucis Longus", "Flexor Hallucis Longus", "lower", "lumbosacral", "sciatic>tibial", "L5,S1,S2", "S1", "SP", "distleg", "flexor hallucis longus|fhl")
    Anat_M("MG", "Gastrocnemius", "Gastrocnemius (medial head)", "lower", "lumbosacral", "sciatic>tibial", "S1,S2", "S1", "SP", "distleg", "gastrocnemius medial head|medial gastrocnemius|gastrocnemius|gastroc|med gastroc|gastrocnemius med|medial gastroc|mg|gastroc medial head|gastrocnemius medial|gastroc med|gastrocnemius mh|medial head gastrocnemius")
    Anat_M("LG", "Gastrocnemius (lateral head)", "Gastrocnemius (lateral head)", "lower", "lumbosacral", "sciatic>tibial", "L5,S1,S2", "S1", "SP", "distleg", "gastrocnemius lateral head|lateral gastrocnemius|lat gastroc|gastroc lateral|gastrocnemius lat|lateral gastroc|lg|gastroc lateral head|gastrocnemius lateral")
    Anat_M("SOL", "Soleus", "Soleus", "lower", "lumbosacral", "sciatic>tibial", "S1,S2", "S1", "SP", "distleg", "soleus")
    Anat_M("AH", "AH", "Abductor Hallucis", "lower", "lumbosacral", "sciatic>tibial>medialPlantar", "S1,S2", "S1,S2", "SP", "distleg,foot", "abductor hallucis|abd hallucis|ah|abductor hallucis brevis|ahb")
    Anat_M("ADQP", "ADQP", "Abductor Digiti Quinti Pedis", "lower", "lumbosacral", "sciatic>tibial>lateralPlantar", "S1,S2", "S1,S2", "SP", "distleg,foot", "abductor digiti quinti pedis|abductor digiti minimi pedis|adqp|adm pedis|abductor digiti minimi foot|adm foot|abductor digiti quinti foot")
    ; ---------------------------------------------------------------- thigh / hip
    Anat_M("BFSH", "Biceps Femoris (short head)", "Biceps Femoris (short head)", "lower", "lumbosacral", "sciatic", "L5,S1,S2", "L5,S1", "SP", "prox", "biceps femoris short head|short head biceps femoris|short head of biceps femoris|bfsh|sh biceps femoris|biceps femoris sh|short head biceps|bf short head|biceps fem short head")
    Anat_M("BFLH", "Biceps Femoris (long head)", "Biceps Femoris (long head)", "lower", "lumbosacral", "sciatic", "L5,S1,S2", "S1", "SP", "prox", "biceps femoris long head|long head biceps femoris|long head of biceps femoris|biceps femoris|bflh|biceps femoris lh|bf long head|lateral hamstring|lateral hamstrings|biceps fem")
    Anat_M("ST", "Semitendinosus", "Semitendinosus", "lower", "lumbosacral", "sciatic", "L5,S1,S2", "L5", "SP", "prox", "semitendinosus|medial hamstring|medial hamstrings|semitendonosus")
    Anat_M("SM", "Semimembranosus", "Semimembranosus", "lower", "lumbosacral", "sciatic", "L5,S1,S2", "L5", "SP", "prox", "semimembranosus|semimembranous")
    Anat_M("GMED", "Gluteus Medius", "Gluteus Medius", "lower", "lumbosacral", "superiorGluteal", "L4,L5,S1", "L5", "SP", "prox", "gluteus medius|glut med|gluteus med|glute med|g medius|gluteal medius|gluteus medias")
    Anat_M("TFL", "Tensor Fascia Lata", "Tensor Fascia Lata", "lower", "lumbosacral", "superiorGluteal", "L4,L5,S1", "L5", "SP", "prox", "tensor fascia lata|tensor fasciae latae|tensor fascia latae|tfl")
    Anat_M("GMAX", "Gluteus Maximus", "Gluteus Maximus", "lower", "lumbosacral", "inferiorGluteal", "L5,S1,S2", "S1", "SP", "prox", "gluteus maximus|glut max|gluteus max|glute max|g maximus|gluteal maximus")
    Anat_M("VL", "VL", "Vastus Lateralis", "lower", "lumbosacral", "femoral", "L2,L3,L4", "L3,L4", "LP", "prox", "vastus lateralis|vast lateralis|vastus lat|vast lat|vl")
    Anat_M("VM", "VM", "Vastus Medialis", "lower", "lumbosacral", "femoral", "L2,L3,L4", "L3,L4", "LP", "prox", "vastus medialis|vast medialis|vastus med|vast med|vm|vmo|vastus medialis oblique")
    Anat_M("RF", "Rectus Femoris", "Rectus Femoris", "lower", "lumbosacral", "femoral", "L2,L3,L4", "L3,L4", "LP", "prox", "rectus femoris|rf|quadriceps|quads|quadricep|quadriceps femoris")
    Anat_M("ILIO", "Iliopsoas", "Iliopsoas", "lower", "lumbosacral", "femoral", "L2,L3,L4", "L2,L3", "LP", "prox", "iliopsoas|iliacus|psoas|ilio psoas|iliopsoas muscle")
    Anat_M("SART", "Sartorius", "Sartorius", "lower", "lumbosacral", "femoral", "L2,L3", "L2,L3", "LP", "prox", "sartorius")
    Anat_M("ADL", "Adductor Longus", "Adductor Longus", "lower", "lumbosacral", "obturator", "L2,L3,L4", "L3", "LP", "prox", "adductor longus|add longus|adductor|adductors|thigh adductor")
    Anat_M("ADMG", "Adductor Magnus", "Adductor Magnus", "lower", "lumbosacral", "obturator", "L2,L3,L4", "L3,L4", "LP", "prox", "adductor magnus|add magnus")
    Anat_M("GRAC", "Gracilis", "Gracilis", "lower", "lumbosacral", "obturator", "L2,L3", "L2,L3", "LP", "prox", "gracilis")
}

; -----------------------------------------------------------------------------
; Name normalisation used for both aliases and report text.
; -----------------------------------------------------------------------------
Anat_NormMuscle(s) {
    s := Util_Normalize(s)
    s := " " . s . " "
    ; Paraspinal level descriptors ("Lumbar paraspinals (low)", "L5 paraspinals")
    if InStr(s, "paraspin") || InStr(s, "multifid") || InStr(s, " psp ") {
        if RegExMatch(s, "\b(c[1-8])\b") && !InStr(s, "cervical")
            s .= " cervical "
        if RegExMatch(s, "\b(t1[0-2]|t[1-9])\b") && !InStr(s, "thoracic")
            s .= " thoracic "
        if RegExMatch(s, "\b(l[1-5]|s[1-2])\b") && !InStr(s, "lumbar")
            s .= " lumbar "
        s := RegExReplace(s, "\b(c[1-8]|t1[0-2]|t[1-9]|l[1-5]|s[1-2])\b", " ")
    }
    for i, w in ["muscle", "muscles", "musc", "m", "mm", "the", "of", "low", "mid", "high", "upper", "lower", "level", "proximal", "distal", "prox", "dist"]
        s := RegExReplace(s, "\s" . w . "(?=\s)", " ")
    s := RegExReplace(s, "\s+", " ")
    return Util_Trim(s)
}

; Returns {side: "R"|"L"|"", name: remainder}
Anat_SplitSide(raw) {
    s := Util_Trim(raw)
    side := ""
    if RegExMatch(s, "Oi)^(right|rt\.?|rgt\.?|r\.|r)(?:\s+|(?<=\.))(.*)$", m)
        side := "R", s := m.Value(2)
    else if RegExMatch(s, "Oi)^(left|lt\.?|lft\.?|l\.|l)(?:\s+|(?<=\.))(.*)$", m)
        side := "L", s := m.Value(2)
    else if RegExMatch(s, "Oi)^(bilat\w*\.?|bil\.?|b/l)\s+(.*)$", m)
        side := "B", s := m.Value(2)
    if (side = "") {
        if RegExMatch(s, "Oi)^(.*?)[\s,\-]*\(?\b(right|rt|r)\)?\s*$", m) && m.Value(1) != ""
            side := "R", s := m.Value(1)
        else if RegExMatch(s, "Oi)^(.*?)[\s,\-]*\(?\b(left|lt|l)\)?\s*$", m) && m.Value(1) != ""
            side := "L", s := m.Value(1)
    }
    return {side: side, name: Util_Trim(s)}
}

Anat_SideFromCell(cell) {
    c := Util_Lower(Util_Trim(cell))
    if RegExMatch(c, "^(r|rt|right|rgt)\.?$")
        return "R"
    if RegExMatch(c, "^(l|lt|left|lft)\.?$")
        return "L"
    if RegExMatch(c, "^(b|bil|bilat|bilateral)\.?$")
        return "B"
    return ""
}

; -----------------------------------------------------------------------------
; Fuzzy muscle lookup. Returns {key, score, how} or {key: ""}.
; Tolerates abbreviations ("Vast. Lat."), word order ("Medial head gastroc"),
; small typos ("Gastrocnemious") and extra qualifiers ("Deltoid (middle)").
; -----------------------------------------------------------------------------
Anat_MatchMuscle(name) {
    global MUSCLE_ALIAS
    static cache := {}
    n := Anat_NormMuscle(name)
    if (n = "")
        return {key: "", score: 0}
    if cache.HasKey("k" . n)
        return cache["k" . n]
    toks := StrSplit(n, " ")
    sortedN := Anat_SortTokens(toks)
    best := {key: "", score: 0, how: ""}
    for i, a in MUSCLE_ALIAS {
        score := 0, how := ""
        if (a.alias == n)
            score := 100, how := "exact"
        else if (StrLen(a.alias) >= 4 && Anat_SortTokens(a.tokens) == sortedN)
            score := 96, how := "word order"
        else if (StrLen(a.alias) >= 4) {
            pm := Anat_TokenMatch(toks, a.tokens)
            if (pm > 0)
                score := pm, how := "abbreviation/typo"
            else if (StrLen(n) >= 6 && StrLen(a.alias) >= 6) {
                sim := Util_Similarity(n, a.alias)
                if (sim >= 0.84)
                    score := Round(60 + sim * 30), how := "spelling"
            }
            if (score < 70 && a.tokens.Length() >= 2 && Anat_ContainsAll(toks, a.tokens))
                score := 72 + a.tokens.Length(), how := "contains"
        }
        ; Prefer longer (more specific) aliases on ties.
        if (score > best.score || (score = best.score && score > 0 && StrLen(a.alias) > StrLen(best.alias)))
            best := {key: a.key, score: score, how: how, alias: a.alias}
    }
    if (best.score < 70)
        best := {key: "", score: best.score, how: "unmatched"}
    cache["k" . n] := best
    return best
}

Anat_SortTokens(toks) {
    s := Util_Join(toks, "`n")
    Sort, s
    return StrReplace(s, "`n", " ")
}

; Same number of words, in order; each word equal, a >=2-letter prefix, or a
; one/two-letter typo of the alias word. Returns a score (0 = no match).
Anat_TokenMatch(toks, atoks) {
    if (toks.Length() != atoks.Length())
        return 0
    total := 0
    for i, t in toks {
        a := atoks[i]
        if (t == a) {
            total += 3
            continue
        }
        if (StrLen(t) >= 2 && StrLen(t) < StrLen(a) && SubStr(a, 1, StrLen(t)) == t) {
            total += 2
            continue
        }
        if (StrLen(t) >= 5 && StrLen(a) >= 5) {
            d := Util_Levenshtein(t, a)
            if (d <= (StrLen(a) >= 9 ? 2 : 1)) {
                total += 2
                continue
            }
        }
        return 0
    }
    return 80 + Round(10 * total / (3 * toks.Length()))
}

Anat_ContainsAll(toks, atoks) {
    for i, a in atoks {
        found := false
        for j, t in toks
            if (t == a || (StrLen(a) >= 6 && Util_Levenshtein(t, a) <= 1)) {
                found := true
                break
            }
        if !found
            return false
    }
    return true
}

; -----------------------------------------------------------------------------
; Nerve study identification from a table heading such as
; "R Median - Dig II (Antidromic)", "Left Peroneal (EDB) Motor", "L Fibular - Tib Ant".
; kind = "sensory" | "motor" | "fwave" | "hreflex"
; Returns {side, nerve, key, rec, label}
; -----------------------------------------------------------------------------
Anat_IdentifyNerve(raw, kind) {
    sp := Anat_SplitSide(raw)
    side := sp.side
    t := " " . Util_Normalize(sp.name) . " "
    t := StrReplace(t, " fibular ", " peroneal ")
    nerve := "", key := "", rec := ""
    ; ---- recording site / digit
    if RegExMatch(t, "\b(dig(it)?\s*(ii|2)|d2|index|2nd digit)\b")
        rec := "D2"
    else if RegExMatch(t, "\b(dig(it)?\s*(iii|3)|d3|middle finger|long finger)\b")
        rec := "D3"
    else if RegExMatch(t, "\b(dig(it)?\s*(iv|4)|d4|ring)\b")
        rec := "D4"
    else if RegExMatch(t, "\b(dig(it)?\s*(v|5)|d5|little|small finger|pinky)\b")
        rec := "D5"
    else if RegExMatch(t, "\b(dig(it)?\s*(i|1)|d1|thumb)\b")
        rec := "D1"
    if RegExMatch(t, "\bpalm")
        rec := (rec = "") ? "palm" : rec . "palm"

    if RegExMatch(t, "\b(dorsal ulnar|duc|dorsal cutaneous)\b")
        nerve := "duc"
    else if RegExMatch(t, "\b(lat(eral)? ante?brach\w*|labc|lacn|lat antebrach\w*|lateral cutaneous forearm)\b")
        nerve := "labc"
    else if RegExMatch(t, "\b(med(ial)? ante?brach\w*|mabc|macn|med antebrach\w*|medial cutaneous forearm)\b")
        nerve := "mabc"
    else if RegExMatch(t, "\b(sup(erficial)?|superf|sp) (peroneal|per)\b") || RegExMatch(t, "\bsuperficial peroneal\b") || (kind = "sensory" && RegExMatch(t, "\bperoneal\b"))
        nerve := "superficialPeroneal"
    else if RegExMatch(t, "\bsaph\w*")
        nerve := "saphenous"
    else if RegExMatch(t, "\bsural\b")
        nerve := "sural"
    else if RegExMatch(t, "\bmedial plantar\b")
        nerve := "medialPlantar"
    else if RegExMatch(t, "\blateral plantar\b")
        nerve := "lateralPlantar"
    else if RegExMatch(t, "\bmedian\b")
        nerve := "median"
    else if RegExMatch(t, "\bulnar\b")
        nerve := "ulnar"
    else if RegExMatch(t, "\bradial\b")
        nerve := "radial"
    else if RegExMatch(t, "\b(peroneal|per|deep peroneal)\b")
        nerve := "peroneal"
    else if RegExMatch(t, "\btibial\b")
        nerve := "tibial"
    else if RegExMatch(t, "\bmusculocutaneous\b")
        nerve := "musculocutaneous"
    else if RegExMatch(t, "\baxillary\b")
        nerve := "axillary"
    else if RegExMatch(t, "\bfemoral\b")
        nerve := "femoral"
    else if RegExMatch(t, "\bfacial\b")
        nerve := "facial"
    else if RegExMatch(t, "\b(spinal )?accessory\b")
        nerve := "accessory"
    else if RegExMatch(t, "\bsuprascapular\b")
        nerve := "suprascapular"
    else if RegExMatch(t, "\bphrenic\b")
        nerve := "phrenic"

    if (kind = "sensory") {
        if (nerve = "median")
            key := InStr(rec, "palm") ? "medianPalm" : (rec = "D4") ? "medianD4" : (rec = "D1") ? "medianD1" : "median"
        else if (nerve = "ulnar")
            key := InStr(rec, "palm") ? "ulnarPalm" : (rec = "D4") ? "ulnarD4" : "ulnar"
        else if (nerve = "radial")
            key := (rec = "D1") ? "radialD1" : "radial"
        else
            key := nerve
        if (key = "medianPalm" && RegExMatch(t, "\b(mixed|orthodromic|ortho)\b"))
            key := "medianPalmMixed"
    } else if (kind = "motor") {
        if (nerve = "median")
            key := "medianAPB"
        else if (nerve = "ulnar")
            key := RegExMatch(t, "\b(fdi|first dorsal|1st dorsal|interos\w*)\b") ? "ulnarFDI" : "ulnarADM"
        else if (nerve = "peroneal" || nerve = "superficialPeroneal") {
            nerve := "peroneal"
            key := RegExMatch(t, "\b(ta|tib ant|tibialis anterior|anterior tibialis|tibialis ant)\b") ? "peronealTA" : "peronealEDB"
        } else if (nerve = "tibial")
            key := "tibialAH"
        else if (nerve = "radial")
            key := "radialEIP"
        else
            key := nerve
        ; motor recording muscle, e.g. "(FDI)" or "- APB"
        if RegExMatch(sp.name, "Oi)[\-\(]\s*([A-Za-z][A-Za-z \.]{1,30}?)\s*\)?\s*(motor)?\s*$", mm)
            rec := Util_Trim(mm.Value(1))
    } else {
        key := nerve
    }
    return {side: side, nerve: nerve, key: key, rec: rec, label: Util_Trim(raw)}
}

; Display name in the house style ("right median sensory nerve",
; "right peroneal motor nerve at the EDB").
Anat_NerveDisplay(st) {
    global CFG
    sideWord := (st.side = "R") ? "right " : (st.side = "L") ? "left " : (st.side = "B") ? "bilateral " : ""
    per := CFG.PeronealTerm
    k := st.key
    if (st.kind = "sensory") {
        names := {median: "median sensory nerve", medianD3: "median sensory nerve", medianPalm: "median palmar sensory nerve", medianPalmMixed: "median palmar mixed nerve"
            , medianD4: "median sensory nerve to digit IV", medianD1: "median sensory nerve to the thumb"
            , ulnar: "ulnar sensory nerve", ulnarD4: "ulnar sensory nerve to digit IV", ulnarPalm: "ulnar palmar mixed nerve"
            , radial: "radial sensory nerve", radialD1: "radial sensory nerve to the thumb", sural: "sural nerve"
            , superficialPeroneal: "superficial " . per . " nerve", saphenous: "saphenous nerve"
            , labc: "lateral antebrachial cutaneous nerve", mabc: "medial antebrachial cutaneous nerve", duc: "dorsal ulnar cutaneous nerve"
            , medialPlantar: "medial plantar nerve", lateralPlantar: "lateral plantar nerve"}
        if (k != "" && names.HasKey(k))
            return sideWord . names[k]
        return sideWord . (st.nerve != "" ? st.nerve . " sensory nerve" : Util_Lower(st.label))
    }
    if (st.kind = "motor") {
        names := {medianAPB: "median motor nerve", ulnarADM: "ulnar motor nerve at the ADM", ulnarFDI: "ulnar motor nerve at the FDI"
            , peronealEDB: per . " motor nerve at the EDB", peronealTA: per . " motor nerve at the TA", tibialAH: "tibial motor nerve"
            , radialEIP: "radial motor nerve"}
        if (k != "" && names.HasKey(k))
            return sideWord . names[k]
        if (st.nerve != "")
            return sideWord . st.nerve . " motor nerve" . (st.rec != "" ? " at the " . st.rec : "")
        return sideWord . Util_Lower(st.label)
    }
    nm := (st.nerve = "peroneal") ? per : st.nerve
    return sideWord . (nm != "" ? nm : Util_Lower(st.label))
}

Anat_SideWord(side) {
    return (side = "R") ? "right" : (side = "L") ? "left" : (side = "B") ? "bilateral" : ""
}

; -----------------------------------------------------------------------------
; Stimulation sites and motor segments.
; -----------------------------------------------------------------------------
Anat_CanonSite(s) {
    t := " " . Util_Normalize(s) . " "
    if RegExMatch(t, "\b(b|below|bel|bl)\s*(elbow|elb)\b") || RegExMatch(t, "\bbe\b") || InStr(t, "b elbow") || InStr(t, "belbow")
        return "belbow"
    if RegExMatch(t, "\b(a|above|abv|ab)\s*(elbow|elb)\b") || RegExMatch(t, "\bae\b") || InStr(t, "aelbow")
        return "aelbow"
    if RegExMatch(t, "\b(b|below|bel)\s*(fib|fibular|fh)") || RegExMatch(t, "\bbfh\b") || InStr(t, "bfib")
        return "bfh"
    if RegExMatch(t, "\b(a|above|abv)\s*(fib|fibular|fh)") || RegExMatch(t, "\bafh\b") || InStr(t, "afib")
        return "afh"
    if RegExMatch(t, "\b(fib|fibular)\s*head\b")
        return "bfh"
    if RegExMatch(t, "\b(pop|popliteal|knee|pf)\b")
        return "knee"
    if RegExMatch(t, "\b(spiral|sg)\b")
        return InStr(t, "below") ? "bsg" : InStr(t, "above") ? "asg" : "sg"
    if RegExMatch(t, "\baxill\w*")
        return "axilla"
    if RegExMatch(t, "\berb\w*")
        return "erb"
    if RegExMatch(t, "\belbow\b")
        return "elbow"
    if RegExMatch(t, "\bwrist\b")
        return "wrist"
    if RegExMatch(t, "\bpalm\b")
        return "palm"
    if RegExMatch(t, "\bforearm\b")
        return "forearm"
    if RegExMatch(t, "\bankle\b")
        return "ankle"
    if RegExMatch(t, "\bcalf\b")
        return "calf"
    if RegExMatch(t, "\b(thigh|groin|inguinal)\b")
        return "thigh"
    return Util_Trim(Util_Normalize(s))
}

; Classifies a motor segment and returns {type, region} where region is the
; phrase used in the summary ("across the elbow", "below the fibular head").
Anat_SegmentInfo(nerveKey, distal, proximal) {
    d := Anat_CanonSite(distal), p := Anat_CanonSite(proximal)
    if InStr(nerveKey, "ulnar") {
        if (d = "wrist" && (p = "belbow" || p = "elbow"))
            return {type: "forearm", region: "below the elbow"}
        if ((d = "belbow" || d = "elbow") && p = "aelbow")
            return {type: "acrossElbow", region: "across the elbow"}
        if ((d = "aelbow" || d = "elbow") && p = "axilla")
            return {type: "aboveElbow", region: "above the elbow"}
        if (d = "axilla" && p = "erb")
            return {type: "axilla", region: "between the axilla and Erb's point"}
        if (d = "palm" || p = "palm")
            return {type: "generic", region: "across the wrist"}
    }
    if InStr(nerveKey, "median") {
        if (d = "wrist" && (p = "elbow" || p = "aelbow" || p = "belbow"))
            return {type: "forearm", region: "in the forearm"}
        if ((d = "elbow" || d = "aelbow") && p = "axilla")
            return {type: "aboveElbow", region: "above the elbow"}
        if (d = "axilla" && p = "erb")
            return {type: "axilla", region: "between the axilla and Erb's point"}
        if (d = "palm" || p = "palm")
            return {type: "generic", region: "across the wrist"}
    }
    if InStr(nerveKey, "peroneal") {
        if ((d = "ankle") && (p = "bfh"))
            return {type: "leg", region: "below the fibular head"}
        if (d = "bfh" && (p = "afh" || p = "knee"))
            return {type: "acrossFH", region: "across the fibular head"}
        if (d = "afh" && p = "knee")
            return {type: "aboveFH", region: "above the fibular head"}
        if (d = "ankle" && (p = "knee" || p = "afh"))
            return {type: "leg", region: "below the knee"}
    }
    if InStr(nerveKey, "tibial") {
        if (d = "ankle" && (p = "knee"))
            return {type: "knee", region: "below the popliteal fossa"}
    }
    if InStr(nerveKey, "radial") {
        if (d = "forearm" && p = "elbow")
            return {type: "forearm", region: "below the elbow"}
        if (d = "elbow" && (p = "bsg" || p = "sg" || p = "asg"))
            return {type: "aboveElbow", region: "above the elbow"}
        if ((d = "bsg" || d = "sg") && (p = "asg" || p = "axilla"))
            return {type: "generic", region: "across the spiral groove"}
    }
    return {type: "generic", region: "between the " . Util_Lower(Util_Trim(proximal)) . " and " . Util_Lower(Util_Trim(distal))}
}

; Root list helpers ------------------------------------------------------------
Anat_RootIndex(r) {
    global ROOT_ORDER
    return Util_ArrHas(ROOT_ORDER, r)
}

Anat_SortRoots(roots) {
    global ROOT_ORDER
    out := []
    for i, r in ROOT_ORDER
        if Util_ArrHas(roots, r)
            out.Push(r)
    return out
}

; "the L5 myotome" / "the L5 and S1 myotomes"
Anat_MyotomePhrase(roots) {
    roots := Anat_SortRoots(roots)
    return "the " . Util_JoinList(roots) . " myotome" . (roots.Length() > 1 ? "s" : "")
}

Anat_RootRegion(roots) {
    hasC := false, hasL := false, hasS := false, hasT := false, hasL5S := false
    for i, r in roots {
        c := SubStr(r, 1, 1)
        if (c = "C")
            hasC := true
        else if (c = "T")
            hasT := true
        else if (c = "L") {
            hasL := true
            if (r = "L5")
                hasL5S := true
        } else if (c = "S")
            hasS := true, hasL5S := true
    }
    if (hasC)
        return "cervical"
    if (hasL5S)
        return "lumbosacral"
    if (hasL)
        return "lumbar"
    if (hasT)
        return "thoracic"
    return "spinal"
}

Anat_NerveName(elem) {
    global CFG
    per := CFG.PeronealTerm
    names := {median: "median", medianWrist: "median", AIN: "anterior interosseous", ulnar: "ulnar", ulnarDeep: "ulnar"
        , radial: "radial", radialSG: "radial", PIN: "posterior interosseous", musculocutaneous: "musculocutaneous"
        , axillary: "axillary", suprascapular: "suprascapular", dorsalScapular: "dorsal scapular", longThoracic: "long thoracic"
        , thoracodorsal: "thoracodorsal", pectoral: "pectoral", lowerSubscapular: "lower subscapular", accessory: "spinal accessory"
        , sciatic: "sciatic", commonPeroneal: "common " . per, deepPeroneal: "deep " . per, superficialPeroneal: "superficial " . per
        , tibial: "tibial", medialPlantar: "medial plantar", lateralPlantar: "lateral plantar", femoral: "femoral"
        , obturator: "obturator", superiorGluteal: "superior gluteal", inferiorGluteal: "inferior gluteal"
        , hypoglossal: "hypoglossal", trigeminal: "trigeminal", facial: "facial"}
    return names.HasKey(elem) ? names[elem] : elem
}

; Location phrase for an EMG-defined mononeuropathy element.
Anat_NerveLocation(elem) {
    loc := {medianWrist: "at the wrist", ulnarDeep: "at or distal to the wrist", radialSG: "at or above the spiral groove"
        , commonPeroneal: "at or above the fibular head", tibial: "at or above the knee", sciatic: "at the level of the sciatic nerve"
        , median: "proximal to the wrist", ulnar: "at or above the elbow", radial: "at or above the axilla"}
    return loc.HasKey(elem) ? loc[elem] : ""
}

Anat_PlexusName(elem) {
    names := {UT: "upper trunk brachial plexopathy", MT: "middle trunk brachial plexopathy", LT: "lower trunk brachial plexopathy"
        , LC: "lateral cord brachial plexopathy", PC: "posterior cord brachial plexopathy", MC: "medial cord brachial plexopathy"
        , LP: "lumbar plexopathy", SP: "lumbosacral plexopathy"}
    return names[elem]
}

; Sensory studies that test each element's sensory territory (postganglionic).
Anat_PlexusSensory(elem) {
    m := {UT: ["labc", "radial", "medianD1", "radialD1"], MT: ["median", "medianD3", "radial"], LT: ["ulnar", "mabc", "duc", "ulnarD4"]
        , LC: ["labc", "median", "medianD1", "medianD3"], PC: ["radial", "radialD1"], MC: ["ulnar", "mabc", "duc"]
        , LP: ["saphenous"], SP: ["sural", "superficialPeroneal"]}
    return m.HasKey(elem) ? m[elem] : []
}

Anat_NerveSensory(elem) {
    m := {median: ["median", "medianD3", "medianD1", "medianD4", "medianPalm"], medianWrist: ["median", "medianD3", "medianD1", "medianD4", "medianPalm"]
        , ulnar: ["ulnar", "ulnarD4", "duc", "ulnarPalm"], ulnarDeep: [], radial: ["radial", "radialD1"], radialSG: ["radial", "radialD1"], PIN: []
        , musculocutaneous: ["labc"], sciatic: ["sural", "superficialPeroneal"], commonPeroneal: ["superficialPeroneal"]
        , superficialPeroneal: ["superficialPeroneal"], deepPeroneal: [], tibial: ["sural", "medialPlantar", "lateralPlantar"], femoral: ["saphenous"]}
    return m.HasKey(elem) ? m[elem] : []
}
