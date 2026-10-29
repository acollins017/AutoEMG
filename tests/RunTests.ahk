; =============================================================================
; RunTests.ahk - headless regression tests.
; For every tests\fixtures\*.txt report: runs the analysis engine, writes the
; result to tests\output\<name>.out.txt and compares it with
; tests\expected\<name>.out.txt (when present). Prints PASS/FAIL to stdout and
; exits with the number of failures.
;   AutoHotkeyU64.exe /ErrorStdOut tests\RunTests.ahk [--update]
; =============================================================================
#NoEnv
#Warn UseUnsetLocal, Off
SetBatchLines, -1
StringCaseSense, Off

#Include %A_ScriptDir%\..\Settings.ahk
#Include %A_ScriptDir%\..\lib\Util.ahk
#Include %A_ScriptDir%\..\lib\Normals.ahk
#Include %A_ScriptDir%\..\lib\Anatomy.ahk
#Include %A_ScriptDir%\..\lib\Parser.ahk
#Include %A_ScriptDir%\..\lib\Assess.ahk
#Include %A_ScriptDir%\..\lib\Impression.ahk
#Include %A_ScriptDir%\..\lib\Engine.ahk

Settings_Load()
Anat_Init()
update := false
for i, a in A_Args
    if (a = "--update")
        update := true

outDir := A_ScriptDir . "\output"
expDir := A_ScriptDir . "\expected"
FileCreateDir, %outDir%
pass := 0, fail := 0, fresh := 0, log := ""
Loop, Files, %A_ScriptDir%\fixtures\*.txt
{
    name := RegExReplace(A_LoopFileName, "\.txt$")
    text := Util_ReadFile(A_LoopFileFullPath)
    try
        res := AutoEMG_Analyze(text)
    catch e {
        fail++
        log .= "ERROR  " . name . ": " . e.Message . " (" . e.What . " line " . e.Line . ")`n"
        continue
    }
    out := AutoEMG_FormatResult(res)
    Util_WriteFile(outDir . "\" . name . ".out.txt", out)
    expPath := expDir . "\" . name . ".out.txt"
    if (update) {
        Util_WriteFile(expPath, out)
        fresh++
        log .= "UPDATED " . name . "`n"
    } else if FileExist(expPath) {
        exp := Util_ReadFile(expPath)
        if (StrReplace(exp, "`r", "") == StrReplace(out, "`r", "")) {
            pass++
            log .= "PASS   " . name . "`n"
        } else {
            fail++
            log .= "FAIL   " . name . "  (diff tests/expected vs tests/output)`n"
        }
    } else {
        fresh++
        log .= "NEW    " . name . " (no expected output yet; run with --update)`n"
    }
}
; Fuzzy muscle-name matching checks
cases := [["R. Gastrocnemius (Medial head)", "MG"], ["Gastrocnemious", "MG"], ["Vast. Lat.", "VL"], ["Tib. Ant.", "TA"]
    , ["Abd. Poll. Brev.", "APB"], ["1st Dorsal Interosseus", "FDI"], ["Medial head gastroc", "MG"], ["Lumbar paraspinals (low)", "LPS"]
    , ["L5 paraspinals", "LPS"], ["Ext Indicis Proprius", "EIP"], ["Triceps (lateral head)", "TRI"], ["Biceps Femoris (SH)", "BFSH"]
    , ["Short head of biceps femoris", "BFSH"], ["Tibialis Posterior", "TP"], ["Glut. Med.", "GMED"], ["Pronator teres", "PT"]
    , ["Deltoid (middle)", "DEL"], ["Flexor Carpi Ulnaris", "FCU"], ["Abductor digiti minimi", "ADM"], ["Extensor Digitorum Brevis", "EDB"]
    , ["Cervical Paraspinals C6", "CPS"], ["Peroneus Longus", "PL"], ["Fibularis longus", "PL"], ["Iliopsoas", "ILIO"]
    , ["Abductor Hallucis", "AH"], ["Semimembranosus", "SM"], ["Genioglossus", "GG"], ["Rectus Abdominus", "RA"]
    , ["Vastus Medialis", "VM"], ["Infraspinatus", "INFRA"], ["Brachioradialis", "BR"], ["FDP 4,5", "FDP45"], ["Anterior Tibialis", "TA"]]
for i, c in cases {
    sp := Anat_SplitSide(c[1])
    m := Anat_MatchMuscle(sp.name)
    if (m.key = c[2])
        pass++
    else {
        fail++
        log .= "FAIL   muscle match """ . c[1] . """ -> " . (m.key = "" ? "(none)" : m.key) . ", expected " . c[2] . "`n"
    }
}
log .= "`n" . pass . " passed, " . fail . " failed, " . fresh . " new/updated`n"
FileAppend, %log%, *
ExitApp, %fail%
