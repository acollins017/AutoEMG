; =============================================================================
; Output.ahk - review window, and insertion of the draft text into the report.
;
; Insertion keeps the report structure intact: the summary is placed on the
; (blank) line directly under "Summary:" and the impression under "Impression:".
;  * Microsoft Word: done through COM, with no keystrokes.
;  * Any other editor: arrow-key navigation. Every candidate line is read back and
;    checked before anything is pasted, so wrapped lines and tables cannot cause a
;    paste in the wrong place.
; =============================================================================

global AEMG_GUI := {}

Out_Preview(res, canInsert := true) {
    global AEMG_GUI
    AEMG_GUI := {action: "", copied: false}
    rep := res.rep
    Gui, AEMG:New, +HwndhGui +LabelAEMG_On +AlwaysOnTop, AutoEMG - Draft summary and impression
    Gui, AEMG:Margin, 12, 10
    Gui, AEMG:Font, s9, Segoe UI
    nWarn := rep.warnings.Length()
    head := AutoEMG_PatientLine(rep)
    Gui, AEMG:Add, Text, w900 cGray, %head%
    Gui, AEMG:Add, Tab3, w900 h500 hwndhTab, % "Draft|Measured values (" . res.checks.Length() . ")|Notes" . (nWarn ? " (" . nWarn . " warning" . (nWarn > 1 ? "s" : "") . ")" : "")
    Gui, AEMG:Tab, 1
    Gui, AEMG:Font, s9 Bold
    Gui, AEMG:Add, Text, , Summary
    Gui, AEMG:Font, s10 Norm, Segoe UI
    sum := res.summary
    Gui, AEMG:Add, Edit, w870 h190 +Wrap +Multi +WantReturn hwndhSum, %sum%
    Gui, AEMG:Font, s9 Bold
    Gui, AEMG:Add, Text, , Impression (draft - review before signing)
    Gui, AEMG:Font, s10 Norm, Segoe UI
    imp := res.impression
    Gui, AEMG:Add, Edit, w870 h200 +Wrap +Multi +WantReturn hwndhImp, %imp%
    Gui, AEMG:Tab, 2
    Gui, AEMG:Font, s9 Norm, Segoe UI
    Gui, AEMG:Add, ListView, w870 h455 Grid -Multi hwndhLV, Result|Study|Measure|Value|Limit|Source|Note
    Gui, AEMG:Default
    for i, c in res.checks {
        L := AutoEMG_CheckLine(c)
        LV_Add("", L.result, L.study, L.label, L.value, L.limit, L.src, L.note)
    }
    LV_ModifyCol(1, 85), LV_ModifyCol(2, 230), LV_ModifyCol(3, 190), LV_ModifyCol(4, 70), LV_ModifyCol(5, 80), LV_ModifyCol(6, 110), LV_ModifyCol(7, 300)
    Gui, AEMG:Tab, 3
    notes := AutoEMG_NotesText(res)
    Gui, AEMG:Font, s9, Consolas
    Gui, AEMG:Add, Edit, w870 h455 ReadOnly +Multi hwndhNotes, %notes%
    Gui, AEMG:Font, s9, Segoe UI
    Gui, AEMG:Tab
    if (canInsert)
        Gui, AEMG:Add, Button, xm w170 h30 Default gAEMG_BtnInsert, &Insert into report
    else
        Gui, AEMG:Add, Button, xm w170 h30 Default gAEMG_BtnCopyBoth, &Copy both
    Gui, AEMG:Add, Button, x+8 w130 h30 gAEMG_BtnCopySum, Copy &summary
    Gui, AEMG:Add, Button, x+8 w130 h30 gAEMG_BtnCopyImp, Copy i&mpression
    if (canInsert)
        Gui, AEMG:Add, Button, x+8 w110 h30 gAEMG_BtnCopyBoth, Copy &both
    Gui, AEMG:Add, Button, x+8 w130 h30 gAEMG_BtnCopyData, Copy &data table
    Gui, AEMG:Add, Button, x+8 w90 h30 gAEMG_OnClose, Cancel
    AEMG_GUI.hGui := hGui, AEMG_GUI.hSum := hSum, AEMG_GUI.hImp := hImp, AEMG_GUI.res := res
    Gui, AEMG:Show, AutoSize Center
    WinWaitClose, ahk_id %hGui%
    return {action: AEMG_GUI.action, summary: AEMG_GUI.summary, impression: AEMG_GUI.impression, copied: AEMG_GUI.copied}
}

AEMG_ReadEdits() {
    global AEMG_GUI
    ControlGetText, s, , % "ahk_id " . AEMG_GUI.hSum
    ControlGetText, i, , % "ahk_id " . AEMG_GUI.hImp
    AEMG_GUI.summary := s
    AEMG_GUI.impression := i
}

AEMG_BtnInsert(a := "", b := "", c := "", d := "") {
    global AEMG_GUI
    AEMG_ReadEdits()
    AEMG_GUI.action := "insert"
    Gui, AEMG:Destroy
}

AEMG_BtnCopySum(a := "", b := "", c := "", d := "") {
    global AEMG_GUI
    AEMG_ReadEdits()
    Out_SetClipboard(AEMG_GUI.summary)
    AEMG_GUI.copied := true
    ToolTip, Summary copied
    SetTimer, Out_ClearTip, -1200
}

AEMG_BtnCopyImp(a := "", b := "", c := "", d := "") {
    global AEMG_GUI
    AEMG_ReadEdits()
    Out_SetClipboard(AEMG_GUI.impression)
    AEMG_GUI.copied := true
    ToolTip, Impression copied
    SetTimer, Out_ClearTip, -1200
}

AEMG_BtnCopyBoth(a := "", b := "", c := "", d := "") {
    global AEMG_GUI
    AEMG_ReadEdits()
    Out_SetClipboard("Summary:`r`n" . AEMG_GUI.summary . "`r`n`r`nImpression:`r`n" . AEMG_GUI.impression)
    AEMG_GUI.copied := true
    ToolTip, Summary and impression copied
    SetTimer, Out_ClearTip, -1200
}

AEMG_BtnCopyData(a := "", b := "", c := "", d := "") {
    global AEMG_GUI
    Out_SetClipboard(AutoEMG_FormatResult(AEMG_GUI.res))
    AEMG_GUI.copied := true
    ToolTip, Data table copied
    SetTimer, Out_ClearTip, -1200
}

AEMG_OnClose(a := "", b := "", c := "", d := "") {
    global AEMG_GUI
    if (AEMG_GUI.action = "")
        AEMG_GUI.action := "cancel"
    Gui, AEMG:Destroy
}

AEMG_OnEscape(a := "") {
    AEMG_OnClose()
}

Out_ClearTip() {
    ToolTip
}

Out_SetClipboard(text) {
    Clipboard := ""
    Clipboard := text
    ClipWait, 1
}

; ---------------------------------------------------------------------------
; Insertion
; ---------------------------------------------------------------------------
Out_IsWord(hwnd) {
    WinGet, proc, ProcessName, ahk_id %hwnd%
    return (proc = "WINWORD.EXE")
}

; Returns {summary: bool, impression: bool, method}
Out_Insert(hwnd, summary, impression, lay) {
    global CFG
    WinActivate, ahk_id %hwnd%
    WinWaitActive, ahk_id %hwnd%, , 2
    method := CFG.InsertMethod
    if (method = "auto")
        method := Out_IsWord(hwnd) ? "word" : "keys"
    if (method = "word") {
        r := Out_WordInsert(summary, impression)
        if (r.summary)
            return r
        method := "keys"
    }
    if (method = "clipboard") {
        Out_SetClipboard(summary . "`r`n`r`n" . impression)
        return {summary: false, impression: false, method: "clipboard"}
    }
    return Out_KeysInsert(summary, impression, lay)
}

Out_WordInsert(summary, impression) {
    global CFG
    res := {summary: false, impression: false, method: "word"}
    try {
        word := ComObjActive("Word.Application")
        doc := word.ActiveDocument
    } catch e {
        return res
    }
    if (CFG.InsertImpression && impression != "")
        res.impression := Out_WordAfterHeading(doc, "i)^(Impression|Diagnostic Interpretation|Interpretation)\s*:\s*$", impression)
    res.summary := Out_WordAfterHeading(doc, "i)^Summary\s*:\s*$", summary)
    return res
}

Out_WordParaText(p) {
    try t := p.Range.Text
    catch
        return ""
    return Util_Trim(RegExReplace(t, "[\r\n\x07\x0B\x0C]", ""))
}

Out_WordAfterHeading(doc, regex, text) {
    text := StrReplace(text, "`r`n", "`r")
    try {
        for p in doc.Paragraphs {
            if !RegExMatch(Out_WordParaText(p), regex)
                continue
            nxt := ""
            try nxt := p.Next()
            if (IsObject(nxt) && Out_WordParaText(nxt) = "") {
                r := nxt.Range
            } else {
                p.Range.InsertParagraphAfter()
                r := p.Next().Range
            }
            r.MoveEnd(1, -1)
            r.Text := text
            r.Font.Reset()
            return true
        }
    } catch e {
        return false
    }
    return false
}

Out_KeysInsert(summary, impression, lay) {
    global CFG
    res := {summary: false, impression: false, method: "keys"}
    ; Impression first: it sits below the summary, so inserting it does not move
    ; the summary heading.
    if (CFG.InsertImpression && impression != "" && lay.impression > 0) {
        re := "i)^(Impression|Diagnostic Interpretation|Interpretation)\s*:\s*$"
        if Out_KeysGotoHeading(re, lay.impression)
            res.impression := Out_KeysPasteBelow(impression, re)
    }
    if (lay.summary > 0) {
        re := "i)^Summary\s*:\s*$"
        if Out_KeysGotoHeading(re, lay.summary)
            res.summary := Out_KeysPasteBelow(summary, re)
    }
    return res
}

Out_KeysReadLine() {
    Clipboard := ""
    Send, {Home}+{End}
    Send, ^c
    ClipWait, 0.35
    t := ErrorLevel ? "" : Clipboard
    Send, {Home}
    return Util_Trim(t)
}

Out_KeysGotoHeading(regex, approx) {
    global CFG
    Send, ^{Home}
    Sleep, % CFG.KeyDelayMs
    n := approx - 1 - CFG.NavBacktrack
    if (n > 0) {
        Send, {Down %n%}
        Sleep, % CFG.KeyDelayMs
    }
    Loop, % CFG.NavMaxSteps {
        if RegExMatch(Out_KeysReadLine(), regex)
            return true
        Send, {Down}
        Sleep, % CFG.KeyDelayMs // 2
    }
    ; Second pass from the top of the document.
    Send, ^{Home}
    Sleep, % CFG.KeyDelayMs
    Loop, % approx + CFG.NavMaxSteps {
        if RegExMatch(Out_KeysReadLine(), regex)
            return true
        Send, {Down}
        Sleep, % CFG.KeyDelayMs // 2
    }
    return false
}

Out_KeysPasteBelow(text, headingRegex) {
    global CFG
    Send, {End}{Down}
    Sleep, % CFG.KeyDelayMs
    t := Out_KeysReadLine()
    if RegExMatch(t, headingRegex) {
        ; heading is the last line of the document
        Send, {End}{Enter}
        Out_Paste(text)
    } else if (t = "")
        Out_Paste(text)
    else
        Out_Paste(text . "`r`n")
    return true
}

Out_Paste(text) {
    Out_SetClipboard(text)
    Send, ^v
    Sleep, 350
}
