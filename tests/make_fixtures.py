#!/usr/bin/env python3
"""Generates synthetic NCS/EMG reports (Natus-style plain text, tab-separated
tables) used as regression fixtures. Each case targets one diagnostic pattern.

    python3 tests/make_fixtures.py
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "fixtures")
LE, GE = "\u2264", "\u2265"


def header(age, sex, history):
    return [
        "  ", "Ascension Seton Neurology", "1600 W. 38th Street, Ste 308", "Austin, Texas 78731", "512.324.3540", "",
        "EMG Report", "", "  ",
        f"Full Name:\tTest Patient\tGender:\t{sex}", "MR #:\t000000\tDate of Birth:\t1/1/1960",
        "Visit Date:\t1/2/2026 9:00 AM", f"Age:\t{age} Years",
        "Examining Physician:\tAndrew Collins", "Referring Physician:\tAndrew Collins",
        f"History and Exam: {history}", " ", "Summary: ", "", "Impression: ", "", "",
        "__________________________________", "Andrew Collins, M.D.", "", " ", "  ",
    ]


def motor_table(studies, temp="32.5"):
    out = ["Motor Nerve Conduction Study ", "  ",
           "Nerve / Sites\tMuscle\tLat\tRef.\tAmp\tRef.\tRel Amp\tDur.\tSegments\tDistance\tLat Diff\tCV\tRef.\tTemp.",
           "\t\tms\tms\tmV\tmV\t%\tms\t\tmm\tms\tm/s\tm/s\t\u00b0C"]
    for head, muscle, rows in studies:
        out.append(head)
        prev = None
        for i, (site, lat, amp, dur, seg, dist, cv) in enumerate(rows):
            rel = "" if prev is None or amp == "NR" else f"{float(amp) / float(prev) * 100:.1f}"
            latref = f"{LE}4.4" if i == 0 else ""
            ampref = f"{GE}4.0" if i == 0 else ""
            cvref = f"{GE}49" if cv else ""
            latdiff = ""
            out.append(f"   {site}\t{muscle}\t{lat}\t{latref}\t{amp}\t{ampref}\t{rel}\t{dur}\t{seg}\t{dist}\t{latdiff}\t{cv}\t{cvref}\t{temp}")
            prev = amp if amp != "NR" else prev
    out.append("  ")
    return out


def sensory_table(studies, temp="32.5"):
    out = ["Sensory Nerve Conduction Study ", "  ",
           "Nerve / Sites\tRec. Site\tPeak Lat\tRef.\tAmp\tRef.\tSegments\tDistance\tCV\tRef.\tTemp.",
           "\t\tms\tms\t\u00b5V\t\u00b5V\t\tmm\tm/s\tm/s\t\u00b0C"]
    for head, rows in studies:
        out.append(head)
        for (site, rec, lat, amp, seg, dist, cv) in rows:
            out.append(f"   {site}\t{rec}\t{lat}\t{LE}3.5\t{amp}\t{GE}10\t{seg}\t{dist}\t{cv}\t{GE}48\t{temp}")
    out.append("  ")
    return out


def emg_table(muscles):
    out = ["EMG Summary Table\t", "\tInsert\tSpontaneous\tVol Act\tMUAP",
           "Muscle\tAct\tFib\tPSW\tFasc\tOther\tEffort\tRecruit\tAmp\tDur.\tPPP"]
    for m in muscles:
        out.append("\t".join(m))
    out.append("  ")
    return out


N = ["Norm", "None", "None", "None", "None", "Max", "Nml", "Norm", "Norm", "Norm"]


def nl(name):
    return [name] + N


def mus(name, ia="Norm", fib="None", psw="None", fasc="None", other="None", eff="Max", rec="Nml", amp="Norm", dur="Norm", ppp="Norm"):
    return [name, ia, fib, psw, fasc, other, eff, rec, amp, dur, ppp]


def ps(name, ia="Norm", fib="None", psw="None"):
    return [name, ia, fib, psw, "None", "None", "", "", "", "", ""]


MED_S = lambda s, lat, amp, cv: (f"{s} Median - Dig II (Antidromic)", [("Wrist", "Index", lat, amp, "Wrist - Index", "130", cv)])
ULN_S = lambda s, lat, amp, cv: (f"{s} Ulnar - Dig V (Antidromic)", [("Wrist", "Dig V", lat, amp, "Wrist - Dig V", "110", cv)])
RAD_S = lambda s, lat, amp, cv: (f"{s} Radial - Superficial (Antidromic)", [("Forearm", "Wrist", lat, amp, "Forearm - Wrist", "100", cv)])
SUR_S = lambda s, lat, amp, cv: (f"{s} Sural - (Antidromic)", [("Calf", "Ankle", lat, amp, "Calf - Ankle", "140", cv)])
SP_S = lambda s, lat, amp, cv: (f"{s} Superficial peroneal - Ankle", [("Lat leg", "Ankle", lat, amp, "Lat leg - Ankle", "140", cv)])
LABC_S = lambda s, lat, amp, cv: (f"{s} Lat Antebrach Cutaneous (Antidromic)", [("Elbow", "Forearm", lat, amp, "Elbow - Forearm", "100", cv)])


def MED_M(s, dl, amp, ecv, eamp=None):
    return (f"{s} Median - APB", "APB", [("Wrist", dl, amp, "6.5", "Wrist - APB", "70", ""),
                                          ("Elbow", f"{float(dl) + 4.2:.1f}", eamp or f"{float(amp) * 0.95:.1f}", "6.8", "Elbow - Wrist", "220", ecv)])


def ULN_M(s, dl, amp, fcv, xcv, be_amp=None, ae_amp=None):
    return (f"{s} Ulnar - ADM", "ADM", [("Wrist", dl, amp, "6.2", "Wrist - ADM", "70", ""),
                                         ("B.Elbow", f"{float(dl) + 3.6:.1f}", be_amp or f"{float(amp) * 0.95:.1f}", "6.4", "B.Elbow - Wrist", "200", fcv),
                                         ("A.Elbow", f"{float(dl) + 5.4:.1f}", ae_amp or f"{float(amp) * 0.93:.1f}", "6.5", "A.Elbow - B.Elbow", "100", xcv)])


def PER_M(s, dl, amp, lcv, xcv, bfh_amp=None, afh_amp=None):
    return (f"{s} Peroneal - EDB", "EDB", [("Ankle", dl, amp, "6.1", "Ankle - EDB", "80", ""),
                                            ("B. Fib Head", f"{float(dl) + 7.0:.1f}", bfh_amp or f"{float(amp) * 0.95:.1f}", "6.3", "B. Fib Head - Ankle", "330", lcv),
                                            ("A. Fib Head", f"{float(dl) + 8.9:.1f}", afh_amp or f"{float(amp) * 0.93:.1f}", "6.4", "A. Fib Head - B. Fib Head", "80", xcv)])


def TIB_M(s, dl, amp):
    return (f"{s} Tibial - AH", "AH", [("Ankle", dl, amp, "5.0", "Ankle - AH", "80", "")])


def write(name, lines):
    with open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(lines) + "\n")


cases = {}

cases["04_cts_bilateral.txt"] = (
    header(52, "Female", "Ms. Test is a 52 year old woman with bilateral hand numbness. EDX is performed for evaluation of carpal tunnel syndrome.")
    + motor_table([MED_M("R", "5.2", "6.8", "52"), MED_M("L", "6.4", "2.1", "50"), ULN_M("R", "2.8", "10.1", "60", "58"), ULN_M("L", "2.9", "9.8", "61", "57")])
    + sensory_table([MED_S("R", "4.6", "15.2", "36"), MED_S("L", "NR", "NR", "NR"), ULN_S("R", "2.8", "24", "55"), ULN_S("L", "2.9", "22", "54")])
    + emg_table([nl("R. Abductor pollicis brevis"), mus("L. Abductor pollicis brevis", ia="Incr", fib="2+", psw="2+", rec="Decr", amp="1+", dur="1+"),
                 nl("L. First dorsal interosseous"), nl("L. Pronator teres"), nl("L. Triceps")]))

cases["05_ulnar_elbow.txt"] = (
    header(61, "Male", "Mr. Test is a 61 year old man with left hand numbness in the 4th and 5th digits. EDX is performed for evaluation of ulnar neuropathy.")
    + motor_table([MED_M("L", "3.6", "8.1", "54"), ULN_M("L", "3.1", "8.5", "57", "32", be_amp="8.1", ae_amp="5.9")])
    + sensory_table([MED_S("L", "3.3", "25", "52"), ULN_S("L", "3.0", "3.8", "50")])
    + emg_table([nl("L. First dorsal interosseous"), nl("L. Flexor carpi ulnaris"), nl("L. Abductor pollicis brevis"), nl("L. Extensor indicis")]))

cases["06_cervical_c7.txt"] = (
    header(55, "Male", "Mr. Test is a 55 year old man with neck pain radiating into the right arm. EDX is performed for evaluation of cervical radiculopathy.")
    + motor_table([MED_M("R", "3.7", "8.9", "55"), ULN_M("R", "2.8", "10.2", "60", "58")])
    + sensory_table([MED_S("R", "3.2", "30", "52"), ULN_S("R", "2.7", "26", "56"), RAD_S("R", "2.2", "24", "60")])
    + emg_table([nl("R. Deltoid"), nl("R. Biceps brachii"), mus("R. Triceps brachii", ia="Incr", fib="2+", psw="2+", rec="Decr", amp="1+", dur="1+", ppp="1+"),
                 mus("R. Flexor carpi radialis", fib="1+", psw="1+", rec="Decr"), mus("R. Pronator teres", amp="1+", dur="1+"),
                 mus("R. Extensor digitorum communis", amp="1+", dur="1+", rec="Decr"), nl("R. First dorsal interosseous"), nl("R. Abductor pollicis brevis"),
                 ps("R. Cervical paraspinals (mid)", fib="1+", psw="1+")]))

cases["07_polyneuropathy.txt"] = (
    header(68, "Male", "Mr. Test is a 68 year old man with diabetes and numbness and tingling in both feet. EDX is performed for evaluation of polyneuropathy.")
    + motor_table([PER_M("R", "6.0", "0.4", "36", "37"), TIB_M("R", "6.4", "0.9"), PER_M("L", "5.9", "0.5", "37", "38")])
    + sensory_table([SUR_S("R", "NR", "NR", "NR"), SUR_S("L", "NR", "NR", "NR"), SP_S("R", "NR", "NR", "NR"), MED_S("R", "3.5", "12", "46"), ULN_S("R", "3.0", "9", "47")])
    + ["F Wave Studies", "  ", "Nerve\tM-Lat\tF-Lat\tRef.\tPersist", "R Tibial - AH\t6.4\t60.2\t" + LE + "56\t70"]
    + ["  "]
    + emg_table([mus("R. Tibialis anterior", amp="1+", dur="1+"), mus("R. Gastrocnemius (Medial head)", fib="1+", amp="1+", dur="1+"),
                 mus("R. Abductor hallucis", fib="2+", psw="2+", rec="Decr", amp="2+", dur="2+"), nl("R. Vastus lateralis"),
                 mus("L. Tibialis anterior", amp="1+", dur="1+"), mus("L. Abductor hallucis", fib="1+", amp="1+", dur="1+"), nl("L. Vastus lateralis")]))

cases["08_myopathy.txt"] = (
    header(58, "Female", "Ms. Test is a 58 year old woman with proximal weakness and an elevated CK. EDX is performed for evaluation of myopathy.")
    + motor_table([MED_M("R", "3.6", "8.0", "55"), PER_M("R", "4.8", "3.9", "45", "46"), TIB_M("R", "4.5", "9.0")])
    + sensory_table([MED_S("R", "3.1", "35", "53"), SUR_S("R", "3.8", "12", "45")])
    + emg_table([mus("R. Deltoid", ia="Incr", fib="2+", psw="2+", rec="Early", amp="Decr", dur="Decr", ppp="2+"),
                 mus("R. Biceps brachii", fib="1+", psw="1+", rec="Early", amp="Decr", dur="Decr"),
                 mus("R. Vastus lateralis", rec="Early", amp="Decr", dur="Decr", ppp="1+"),
                 mus("R. Iliopsoas", fib="1+", rec="Early", amp="Decr", dur="Decr"),
                 nl("R. First dorsal interosseous"), nl("R. Tibialis anterior"), ps("R. Thoracic paraspinals", fib="2+", psw="2+")]))

cases["09_motor_neuron.txt"] = (
    header(66, "Male", "Mr. Test is a 66 year old man with progressive painless weakness and cramps. EDX is performed for evaluation of motor neuron disease.")
    + motor_table([MED_M("R", "3.9", "3.0", "50"), ULN_M("R", "3.0", "8.2", "56", "55"), PER_M("R", "5.1", "0.8", "41", "43"), TIB_M("R", "5.0", "6.1")])
    + sensory_table([MED_S("R", "3.3", "22", "51"), ULN_S("R", "2.9", "18", "53"), SUR_S("R", "4.0", "9", "44")])
    + emg_table([mus("L. Genioglossus", fib="1+", fasc="1+", amp="1+", dur="1+"),
                 mus("R. First dorsal interosseous", ia="Incr", fib="2+", psw="2+", fasc="1+", rec="Decr", amp="2+", dur="2+"),
                 mus("R. Biceps brachii", fib="1+", psw="1+", rec="Decr", amp="1+", dur="1+"),
                 mus("R. Triceps brachii", fasc="1+", rec="Decr", amp="1+", dur="1+"),
                 ps("R. Thoracic paraspinals", fib="2+", psw="2+"),
                 mus("R. Tibialis anterior", fib="2+", psw="2+", rec="Decr", amp="2+", dur="2+"),
                 mus("R. Vastus lateralis", fib="1+", rec="Decr", amp="1+", dur="1+"),
                 mus("R. Gastrocnemius (Medial head)", fib="1+", amp="1+", dur="1+")]))

cases["10_upper_trunk.txt"] = (
    header(35, "Male", "Mr. Test is a 35 year old man with right shoulder weakness after a fall. EDX is performed for evaluation of brachial plexopathy.")
    + motor_table([MED_M("R", "3.5", "9.1", "56"), ULN_M("R", "2.7", "11.0", "61", "60")])
    + sensory_table([MED_S("R", "3.1", "31", "54"), ULN_S("R", "2.7", "25", "56"), RAD_S("R", "2.3", "5.0", "58"), LABC_S("R", "2.2", "3.0", "58"), LABC_S("L", "2.1", "12", "60")])
    + emg_table([mus("R. Deltoid", fib="2+", psw="2+", rec="Decr", amp="1+", dur="1+"), mus("R. Biceps brachii", fib="2+", psw="2+", rec="Decr", amp="1+", dur="1+"),
                 mus("R. Infraspinatus", fib="1+", psw="1+", rec="Decr"), mus("R. Brachioradialis", fib="1+", amp="1+", dur="1+"),
                 nl("R. Rhomboid major"), nl("R. Serratus anterior"), nl("R. Triceps"), nl("R. Pronator teres"), nl("R. First dorsal interosseous"),
                 ps("R. Cervical paraspinals")]))

cases["11_peroneal_fibular_head.txt"] = (
    header(45, "Male", "Mr. Test is a 45 year old man with left foot drop after crossing his legs. EDX is performed for evaluation of foot drop.")
    + motor_table([PER_M("L", "5.0", "3.0", "45", "30", bfh_amp="2.8", afh_amp="1.2"), TIB_M("L", "4.6", "8.2")])
    + sensory_table([SP_S("L", "3.9", "3.0", "45"), SUR_S("L", "3.6", "11", "46")])
    + emg_table([mus("L. Tibialis anterior", fib="2+", psw="2+", rec="Decr"), mus("L. Peroneus longus", fib="1+", psw="1+", rec="Decr"),
                 nl("L. Biceps femoris (short head)"), nl("L. Tibialis posterior"), nl("L. Gluteus medius"), nl("L. Gastrocnemius (Medial head)"),
                 ps("L. Lumbar paraspinals (low)")]))

alt = (header(50, "Female", "Ms. Test is a 50 year old woman with left buttock and calf pain. EDX is performed for evaluation of S1 radiculopathy.")
       + ["Sensory Nerve Conduction Study", "  ",
          "Nerve / Sites\tRec. Site\tOnset Lat\tPeak Lat\tNP Amp\tDistance\tPeak Diff\tVelocity\tTemp.",
          "\t\tms\tms\t\u00b5V\tcm\tms\tm/s\t\u00b0C",
          "Left Sural Sensory", "   Calf\tAnkle\t3.1\t3.9\t9.5\t14\t\t45\t32.0",
          "Right Sural Sensory", "   Calf\tAnkle\t3.0\t3.8\t10.1\t14\t\t47\t32.0", "  "]
       + motor_table([PER_M("L", "4.9", "4.2", "45", "47"), TIB_M("L", "4.8", "7.5")])
       + ["F Wave Studies", "  ", "Nerve\tM-Lat\tF-Lat\tRef.\tPersist",
          "R Tibial - AH\t4.9\t52.1\t" + LE + "56\t80", "L Tibial - AH\t4.8\t58.0\t" + LE + "56\t75", "R Peroneal - EDB\t5.2\tNR\t" + LE + "56\t0", "  ",
          "H Reflex Studies", "  ", "Nerve\tM-Lat\tH-Lat\tRef.",
          "R Tibial (Gastroc)\t5.1\t30.2\t" + LE + "34", "L Tibial (Gastroc)\t5.0\t33.9\t" + LE + "34", "  "]
       + emg_table([mus("Lt. Gastrocnemious", fib="1+", psw="1+"), mus("Lt Glut. Max.", fib="1+", amp="1+", dur="1+", rec="Decr"),
                    nl("Lt. Tib. Ant."), nl("Lt Tibialis Post"), nl("L Vast. Lat."), ps("Lt. L5-S1 paraspinals", fib="1+", psw="1+"),
                    nl("Rt. Gastrocnemius"), nl("Rt Tib. Ant.")]))
cases["12_alt_format_s1_late_responses.txt"] = alt

os.makedirs(OUT, exist_ok=True)
for name, lines in cases.items():
    write(name, lines)
print(f"wrote {len(cases)} fixtures to {OUT}")
