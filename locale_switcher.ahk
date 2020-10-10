#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

RAlt & Delete::SwitchKeysLocale()
RControl & Delete::SwitchRegistr()

SwitchKeysLocale()
{
   SelText := GetWord(TempClipboard) 
   Clipboard := ConvertText(SelText, Layout)
   SendInput, ^{vk56}   ; Ctrl + V
   Sleep, 50
   SwitchLocale(Layout)
   Sleep, 50
   Clipboard := TempClipboard
}

SwitchRegistr()
{
   SelText := GetWord(TempClipboard)
   Clipboard := ConvertRegistr(SelText) 
   SendInput, ^{vk56}   ; Ctrl + V 
   Sleep, 200 
   Clipboard := TempClipboard
}

GetWord(ByRef TempClipboard)
{
   SetBatchLines, -1
   SetKeyDelay, 0
   
   TempClipboard := ClipboardAll
   Clipboard =
   SendInput, ^{vk43}
   Sleep, 100
   if (Clipboard != "")
      Return Clipboard
   
   While A_Index < 10
   {
      SendInput, ^+{Left}^{vk43}
      ClipWait, 1
      if ErrorLevel
         Return

      if RegExMatch(Clipboard, "P)([ \t])", Found) && A_Index != 1
      {
         SendInput, ^+{Right}
         Return SubStr(Clipboard, FoundPos1 + 1)
      }

      PrevClipboard := Clipboard
      Clipboard =
      SendInput, +{Left}^{vk43}
      ClipWait, 1
      if ErrorLevel
         Return

      if (StrLen(Clipboard) = StrLen(PrevClipboard))
      {
         Clipboard =
         SendInput, +{Left}^{vk43}
         ClipWait, 1
         if ErrorLevel
            Return

         if (StrLen(Clipboard) = StrLen(PrevClipboard))
            Return Clipboard
         Else
         {
            SendInput, +{Right 2}
            Return PrevClipboard
         }
      }

      SendInput, +{Right}

      s := SubStr(Clipboard, 1, 1)
      if s in %A_Space%,%A_Tab%,`n,`r
      {
         Clipboard =
         SendInput, +{Left}^{vk43}
         ClipWait, 1
         if ErrorLevel
            Return

         Return Clipboard
      }
      Clipboard =
   }
}

ConvertText(Text, ByRef OppositeLayout)
{  
   Static Cyr := "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ/ёйцукенгшщзхъфывапролджэячсмитьбю,.""№;?:"
        , Lat := "~QWERTYUIOP{}ASDFGHJKL:""ZXCVBNM<>|``qwertyuiop[]asdfghjkl;'zxcvbnm,.?/@#$&^"

   RegExReplace(Text, "i)[A-Z@#\$\^&\[\]'`\{}]", "", LatCount)
   RegExReplace(Text, "i)[А-ЯЁ№]", "", CyrCount)
   
   if (LatCount != CyrCount)  {
      CurrentLayout := LatCount > CyrCount ? "Lat" : "Cyr"
      OppositeLayout := LatCount > CyrCount ? "Cyr" : "Lat"
   }
   else  {
      threadId := DllCall("GetWindowThreadProcessId", Ptr, WinExist("A"), UInt, 0, Ptr)
      landId := DllCall("GetKeyboardLayout", Ptr, threadId, Ptr) & 0xFFFF
      if (landId = 0x409)
         CurrentLayout := "Lat", OppositeLayout := "Cyr"
      else
         CurrentLayout := "Cyr", OppositeLayout := "Lat"
   }
   Loop, parse, Text
      NewText .= (found := InStr(%CurrentLayout%, A_LoopField, 1)) 
         ? SubStr(%OppositeLayout%, found, 1) : A_LoopField
   Return NewText
}

SwitchLocale(Layout)
{
   SetFormat, IntegerFast, H
   VarSetCapacity(List, A_PtrSize*2)
   DllCall("GetKeyboardLayoutList", Int, 2, Ptr, &List)
   Locale1 := NumGet(List)
   b := SubStr(Locale2 := NumGet(List, A_PtrSize), -3) = 0409
   En := b ? Locale2 : Locale1
   Ru := b ? Locale1 : Locale2

   ControlGetFocus, CtrlFocus, A
   PostMessage, WM_INPUTLANGCHANGEREQUEST := 0x50,, Layout = "Lat" ? En : Ru, %CtrlFocus%, A
}

ConvertRegistr(Text)
{
   static Chars := "ёйцукенгшщзхъфывапролджэячсмитьбюqwertyuiopasdfghjklzxcvbnm"
                 . "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮQWERTYUIOPASDFGHJKLZXCVBNM" 

   Loop, parse, Text
      NewText .= (found := InStr(Chars, A_LoopField, 1)) 
         ? SubStr(Chars, found - 59, 1) : A_LoopField
   Return NewText
}