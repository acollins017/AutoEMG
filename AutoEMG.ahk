; =============================================================================
; AutoEMG - drafts the Summary and Impression of an NCS/EMG report.
;
; Usage: open the report, press Ctrl+Q. The report text is copied, parsed and
; compared with age-adjusted AANEM reference values; a review window shows the
; draft Summary and Impression (both editable) plus every measured value against
; its limit. "Insert into report" places the text under the "Summary:" and
; "Impression:" headings without touching the rest of the report.
;
; Requires AutoHotkey v1.1.33+ (Unicode). Settings live in Settings.ahk.
; =============================================================================
#Requires AutoHotkey v1.1.33+
#NoEnv
#SingleInstance Force
#Warn UseUnsetLocal, Off
SetBatchLines, -1
SendMode, Input
SetWorkingDir, %A_ScriptDir%
StringCaseSense, Off
FileEncoding, UTF-8

#Include %A_ScriptDir%\Settings.ahk
#Include %A_ScriptDir%\lib\Util.ahk
#Include %A_ScriptDir%\lib\Normals.ahk
#Include %A_ScriptDir%\lib\Anatomy.ahk
#Include %A_ScriptDir%\lib\Parser.ahk
#Include %A_ScriptDir%\lib\Assess.ahk
#Include %A_ScriptDir%\lib\Impression.ahk
#Include %A_ScriptDir%\lib\Engine.ahk
#Include %A_ScriptDir%\lib\Output.ahk

AutoEMG_Init()
return
; ------------------------------ end of auto-execute ---------------------------

AutoEMG_Init() {
    global CFG
    Settings_Load()
    Anat_Init()
    try {
        Hotkey, % CFG.HotkeyRun, AutoEMG_RunFromEditor
        Hotkey, % CFG.HotkeyClipboard, AutoEMG_RunFromClipboard
        Hotkey, % CFG.HotkeyReload, AutoEMG_Reload
    } catch e {
        MsgBox, 48, AutoEMG, % "A hotkey in Settings.ahk could not be registered:`n" . e.Message
    }
    Menu, Tray, Tip, % "AutoEMG - press " . AutoEMG_HotkeyName(CFG.HotkeyRun) . " in an open report"
    Menu, Tray, Add
    Menu, Tray, Add, Analyze text on the clipboard, AutoEMG_RunFromClipboard
    Menu, Tray, Add, Edit settings, AutoEMG_EditSettings
    Menu, Tray, Add, Open README, AutoEMG_OpenReadme
}

AutoEMG_HotkeyName(hk) {
    out := ""
    Loop, Parse, hk
    {
        c := A_LoopField
        if (c = "^")
            out .= "Ctrl+"
        else if (c = "+")
            out .= "Shift+"
        else if (c = "!")
            out .= "Alt+"
        else if (c = "#")
            out .= "Win+"
        else
            out .= Util_Upper(c)
    }
    return out
}

; Hotkey: copy the open report, analyze, review, insert.
AutoEMG_RunFromEditor(a := "", b := "", c := "") {
    global CFG
    static busy := false
    if (busy)
        return
    busy := true
    KeyWait, Control
    KeyWait, Shift
    KeyWait, Alt
    KeyWait, LWin
    hwnd := WinExist("A")
    saved := ClipboardAll
    Clipboard := ""
    Send, ^a
    Sleep, 80
    Send, ^c
    ClipWait, 2
    if (ErrorLevel || Util_Trim(Clipboard) = "") {
        Send, ^{Home}
        Clipboard := saved
        busy := false
        MsgBox, 48, AutoEMG, Could not copy the report text.`n`nClick inside the report body and try again, or copy the whole report yourself and use Ctrl+Shift+Q.
        return
    }
    text := Clipboard
    Send, ^{Home}
    AutoEMG_Process(text, hwnd, saved, true)
    busy := false
}

; Hotkey/tray: analyze text that is already on the clipboard (no keystrokes sent).
AutoEMG_RunFromClipboard(a := "", b := "", c := "") {
    text := Clipboard
    if (Util_Trim(text) = "") {
        MsgBox, 48, AutoEMG, The clipboard is empty. Copy the whole report first.
        return
    }
    AutoEMG_Process(text, WinExist("A"), "", false)
}

AutoEMG_Process(text, hwnd, saved, canInsert) {
    global CFG
    try
        res := AutoEMG_Analyze(text)
    catch e {
        MsgBox, 16, AutoEMG, % "The report could not be analyzed:`n" . e.Message . "`n(" . e.What . ", line " . e.Line . ")"
        if (canInsert)
            Clipboard := saved
        return
    }
    rep := res.rep
    if (rep.sensory.Length() + rep.motor.Length() + rep.emg.Length() + rep.fwave.Length() + rep.hreflex.Length() = 0) {
        MsgBox, 48, AutoEMG, No nerve conduction or EMG tables were found in this document.
        if (canInsert)
            Clipboard := saved
        return
    }
    summary := res.summary, impression := res.impression, action := "insert", copied := false
    if (CFG.ShowPreview) {
        out := Out_Preview(res, canInsert && rep.layout.summary > 0)
        action := out.action, summary := out.summary, impression := out.impression, copied := out.copied
    } else if (!canInsert || !rep.layout.summary)
        action := "copy"
    if (action = "insert") {
        r := Out_Insert(hwnd, summary, impression, rep.layout)
        if (r.method = "clipboard")
            copied := true
        else {
            msg := ""
            if (!r.summary)
                msg .= "The ""Summary:"" heading could not be located; the summary was not inserted.`n"
            if (CFG.InsertImpression && impression != "" && !r.impression)
                msg .= "The ""Impression:"" heading could not be located; the impression was not inserted.`n"
            if (msg != "") {
                Out_SetClipboard("Summary:`r`n" . summary . "`r`n`r`nImpression:`r`n" . impression)
                MsgBox, 48, AutoEMG, % msg . "`nBoth sections have been copied to the clipboard so you can paste them manually."
                return
            }
        }
    } else if (action = "copy") {
        Out_SetClipboard("Summary:`r`n" . summary . "`r`n`r`nImpression:`r`n" . impression)
        copied := true
    }
    if (canInsert && !copied && CFG.RestoreClipboard) {
        Sleep, 300
        Clipboard := saved
    }
}

AutoEMG_Reload(a := "", b := "", c := "") {
    Reload
}

AutoEMG_EditSettings(a := "", b := "", c := "") {
    Run, notepad.exe "%A_ScriptDir%\Settings.ahk"
}

AutoEMG_OpenReadme(a := "", b := "", c := "") {
    Run, notepad.exe "%A_ScriptDir%\README.md"
}

; Hotstrings must come after the auto-execute section.
#Include %A_ScriptDir%\lib\DotPhrases.ahk
