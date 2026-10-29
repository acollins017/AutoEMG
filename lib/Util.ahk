; =============================================================================
; Util.ahk - small, dependency-free helpers shared by every AutoEMG module.
; =============================================================================

Util_Trim(s) {
    return Trim(s, " `t`r`n" . Chr(160) . Chr(0x2002) . Chr(0x2003) . Chr(0x2009))
}

; First number found in a cell ("4.2", "?3.9", ">=48", "<0.5 ms") or "" if none.
Util_Num(s) {
    s := StrReplace(s, ",", ".")
    if RegExMatch(s, "O)(-?\d+(?:\.\d+)?|-?\.\d+)", m)
        return m.Value(1) + 0
    return ""
}

Util_IsNum(v) {
    if (v = "")
        return false
    return RegExMatch(v, "^\s*-?(\d+(\.\d*)?|\.\d+)\s*$") ? true : false
}

; True when a cell explicitly reports an absent response.
Util_IsNR(s) {
    s := Util_Trim(s)
    if (s = "")
        return false
    return RegExMatch(s, "i)^(NR|N\.R\.?|N/R|NR\*|absent|abs|no\s*resp\w*|no\s*response|not\s*recordable|unobtainable|NP)$") ? true : false
}

Util_Round(v, n := 1) {
    if (v = "")
        return ""
    return Format("{:." . n . "f}", v)
}

; Drops trailing zeros: 3.70 -> 3.7, 48.0 -> 48
Util_Fmt(v) {
    if (v = "")
        return ""
    s := Format("{:.2f}", v)
    s := RegExReplace(s, "0+$")
    s := RegExReplace(s, "\.$")
    return s
}

Util_CapFirst(s) {
    first := SubStr(s, 1, 1)
    StringUpper, first, first
    return first . SubStr(s, 2)
}

Util_LowerFirst(s) {
    ; Keep acronyms/root names (e.g. "L5", "EDX") intact.
    if RegExMatch(s, "^[A-Z]{2}") || RegExMatch(s, "^[A-Z]\d")
        return s
    first := SubStr(s, 1, 1)
    StringLower, first, first
    return first . SubStr(s, 2)
}

Util_Lower(s) {
    StringLower, s, s
    return s
}

Util_Upper(s) {
    StringUpper, s, s
    return s
}

; ["a"] -> "a"; ["a","b"] -> "a and b"; ["a","b","c"] -> "a, b, and c"
Util_JoinList(arr, conj := "and") {
    n := arr.Length()
    if (n = 0)
        return ""
    if (n = 1)
        return arr[1]
    if (n = 2)
        return arr[1] . " " . conj . " " . arr[2]
    out := ""
    for i, v in arr {
        if (i < n)
            out .= v . ", "
        else
            out .= conj . " " . v
    }
    return out
}

Util_Join(arr, sep := ", ") {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") . v
    return out
}

Util_ArrHas(arr, val) {
    for i, v in arr
        if (v = val)
            return i
    return 0
}

Util_ArrPushUnique(arr, val) {
    if !Util_ArrHas(arr, val)
        arr.Push(val)
    return arr
}

Util_Split(s, sep := ",") {
    out := []
    if (s = "")
        return out
    for i, v in StrSplit(s, sep) {
        v := Util_Trim(v)
        if (v != "")
            out.Push(v)
    }
    return out
}

Util_Keys(obj) {
    out := []
    for k in obj
        out.Push(k)
    return out
}

Util_Count(obj) {
    n := 0
    for k in obj
        n++
    return n
}

; Case-folded, punctuation-free, single-spaced version of a label.
Util_Normalize(s) {
    s := Util_Lower(s)
    s := StrReplace(s, Chr(0xB4), "")
    s := RegExReplace(s, "[\.\,\(\)\[\]\{\}\-_/\\:;'""\*#\+&]", " ")
    s := RegExReplace(s, "\s+", " ")
    return Util_Trim(s)
}

Util_Levenshtein(a, b) {
    la := StrLen(a), lb := StrLen(b)
    if (la = 0)
        return lb
    if (lb = 0)
        return la
    prev := []
    Loop, % lb + 1
        prev[A_Index - 1] := A_Index - 1
    Loop, % la {
        i := A_Index
        cur := []
        cur[0] := i
        ca := SubStr(a, i, 1)
        Loop, % lb {
            j := A_Index
            cost := (ca == SubStr(b, j, 1)) ? 0 : 1
            cur[j] := Min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
        }
        prev := cur
    }
    return prev[lb]
}

Util_Similarity(a, b) {
    m := Max(StrLen(a), StrLen(b))
    if (m = 0)
        return 1
    return 1 - Util_Levenshtein(a, b) / m
}

Util_Repeat(s, n) {
    out := ""
    Loop, % n
        out .= s
    return out
}

Util_PadRight(s, n) {
    s := s . ""
    while (StrLen(s) < n)
        s .= " "
    return s
}

; Reads a text file regardless of whether it was saved as UTF-8, UTF-16 or ANSI.
Util_ReadFile(path) {
    f := FileOpen(path, "r")
    if !IsObject(f)
        return ""
    txt := f.Read()
    f.Close()
    return txt
}

Util_WriteFile(path, text) {
    f := FileOpen(path, "w", "UTF-8")
    if !IsObject(f)
        return false
    f.Write(text)
    f.Close()
    return true
}
