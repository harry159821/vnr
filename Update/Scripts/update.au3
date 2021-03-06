; update.au3
; 4/6/2013 jichi

#include <Constants.au3>
#include <GuiConstants.au3>
#Include <GuiEdit.au3>
#include <ProgressConstants.au3>
#include <ScrollBarConstants.au3>
#include <WinAPI.au3>

; The current directory is supposed to be ScriptDir instead of WorkingDir
; http://www.autoitscript.com/forum/topic/121929-howto-get-current-directory-a-script-was-started-from/
;Global $PWD = @WorkingDir
;Global $PWD = @ScriptDir

; Main
Global $RC_ICON = @ScriptDir & "\update.ico"
Global $RC_CMD = @ScriptDir & "\safeupdate.cmd"
Global $CODEPAGE = 932

Global $PROGRESS_COUNT = 80

;Global $ERROR_MESSAGE = "======================================================================"
Global $ERROR_MESSAGE = ""

Exit Main()

Func Main() ; @return  int
  If Not FileExists($RC_CMD) Then
    Local $msg = "Cannot find update script:"
    $msg = $msg & @CRLF & @CRLF & $RC_CMD
    $msg = $msg & @CRLF & @CRLF & "Please redownload VNR updater or complain to me at:"
    $msg = $msg & @CRLF & @TAB & "annotcloud@gmail.com"
    MsgBox(16,"VNR Error", $msg)
    Return 1
  EndIf

  If Prompt() Then EventLoop()
  Return 0
EndFunc

; @param  string; Message boxes
Func Alert($msg)
  MsgBox(0, "Alert", $msg)
EndFunc


; @param lpwstr; @return lpwstr
;Func CleanText($text)
;  Local $a = StringSplit($text, "") ; http://stackoverflow.com/questions/4597006/how-can-i-access-a-string-like-an-array-in-autoit-im-porting-code-from-c-to
;  Local $r = ""
;  For $i = 1 to $a[0]
;    $r = $r & $a[$i]
;  Next
;  Return $r
;EndFunc

; @param lpwstr; @return lpwstr
Func Transcode($text)
  Local $ws = _WinAPI_MultiByteToWideChar($text, $CODEPAGE)
  Local $mb = _WinAPI_WideCharToMultiByte($ws)
  Return $mb
EndFunc

; @param lpwstr; @return lpwstr
Func RenderText($text)
  ;Local $r = Transcode($text)
  Local $r = $text
  If Not $r Then $r = $text
  ;$r = StringRegExpReplace($r, "[\x10-\x1F\x21-\x2F\x3A-\x40\x5B-\x60\x80-\xFF]", "")
  $r = StringReplace($r, "210.175.52.140", "sakuradite.org")
  Return $r
EndFunc

; @return  bool
Func Prompt()
  Local $title = "Software Update"

  Local $msg = "Do you want to update VNR? (Internet access is needed)"
  $msg = $msg & @CRLF & "VNRを更新しますか？（インターネット接続が必要です）"
  $msg = $msg & @CRLF & "要現在更新VNR嗎？（需要網絡連接）"
  $msg = $msg & @CRLF & "要现在更新VNR吗？（需要网络连接）"

  ; Magic numbers generated by AutoIt3/Examples/GUI/Advanced/msgboxwizard.au3
  $sel = MsgBox(292, $title, $msg)
  Return $sel = 6 ; yes
EndFunc


; @return  bool
Func ConfirmAbort()
  Local $title = "Abort"

  Local $msg = "Do you want to abort the update?"
  $msg = $msg & @CRLF & "更新を中止しますか？"

  ; Magic numbers generated by AutoIt3/Examples/GUI/Advanced/msgboxwizard.au3
  $sel = MsgBox(292, $title, $msg)
  Return $sel = 6 ; yes
EndFunc

; Event loop

Func AbortGui()
  GuiDelete()
  Exit
EndFunc

Func EventLoop()
  Local $icon = @ScriptDir & "\update.ico"

  Local $width = 480
  Local $margin = 9
  Local $contentWidth = $width - $margin - $margin

  Local $buttonWidth = 150
  Local $buttonHeight = 30

  ;Local $labelHeight = 20
  ;Local $labelWidth = $contentWidth * 0.8

  Local $editHeight = 200
  Local $progressHeight = 20

  Local $height = $editHeight + $progressHeight + $buttonHeight + $margin *4

  ; The order is important
  $gui = GuiCreate("Software Update", $width, $height)
  GUISetIcon($icon)

  $edit = GUICtrlCreateEdit("Waiting ...", $margin, $margin, $contentWidth, $editHeight)
  $progress = GUICtrlCreateProgress($margin, $editHeight+$progressHeight, $contentWidth, $progressHeight, $PBS_SMOOTH)
  $exitButton = GuiCtrlCreateButton("Cancel (キャンセル)", ($contentWidth-$buttonWidth)/2-$margin, $editHeight+$progressHeight+$margin*3, $buttonWidth, $buttonHeight)
  ;$label = GuiCtrlCreateLabel("Updating ...", $margin * 2, $editHeight + $margin * 3, $labelWidth, $labelHeight)

  $hiddenEdit = GUICtrlCreateEdit("", -1000, -1000, 0, 0) ; Used for filtering text

  GuiSetState(@SW_SHOW) ;Make the GUI visible

  ; http://stackoverflow.com/questions/11945625/autoit-command-line-how-to-run-command-without-opening-new-shell
  Local $cmd = $RC_CMD
  $cmd = '"' & $cmd & '"'
  $cmd = @ComSpec & " /c " & $cmd
  Local $pid = Run($cmd, @ScriptDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)

  ; Process the command
  Local $progressTotal = $PROGRESS_COUNT
  Local $progressCount = 0
  Local $eolCount = 0
  Local $outText = "" ; GUICtrlRead($edit)
  Local $errText = ""
  While True
    Local $guimsg = GuiGetMsg() ;Get GUI Messages and store it in the variable $guimsg
    Select ;Select statment to distinguish what to do when a GUI Message occurs
    Case $guimsg = $GUI_EVENT_CLOSE
      If ConfirmAbort() Then AbortGui()
    Case $guimsg = $exitButton
      If ConfirmAbort() Then AbortGui()
    EndSelect

    Local $out = @CRLF & StdoutRead($pid)
    Local $err = @CRLF & StderrRead($pid)
    If @Error Then ExitLoop

    If $err And $err <> @CRLF Then
      ; Remove illegal characters
      GUICtrlSetData($hiddenEdit, $err)
      $err = GUICtrlRead($hiddenEdit)

      $errText = $errText & $err
    EndIf

    If $out = @CRLF Then
      $eolCount = $eolCount + 1
      ;if $eolCount > 10 Then ExitLoop
    Else
      $eolCount = 0
      $progressCount = $progressCount + 1

      ; Remove illegal characters
      GUICtrlSetData($hiddenEdit, $out)
      $out = GUICtrlRead($hiddenEdit)

      $outText = $outText & $out

      Local $t
      If Not $errText Then
        $t = RenderText($outText)
      Else
        $t = RenderText($outText) & @CRLF & $ERROR_MESSAGE & @CRLF & RenderText($errText)
      EndIf
      GUICtrlSetData($edit, $t)
      _GUICtrlEdit_Scroll($edit, $SB_SCROLLCARET)

      If $progressTotal < $progressCount Then $progressTotal = $progressTotal + 5
      GUICtrlSetData($progress, $progressCount * 100 / $progressTotal)

      ;Local $progress = StringFormat("%.1f", $progressCount / $progressTotal * 100)
      ;Local $msg = "Updating ... "
      ;$msg = $msg & $progress & "% |"
      ;Local $i
      ;For $i = 1 To $progressCount
      ;  ;Local $count = Mod($loopCount, 10)
      ;  $msg = $msg & "="
      ;Next
      ;$msg = $msg & "=>"
      ;GUICtrlSetData($label, $msg)
    EndIf
  WEnd

  ; Exit
  GUICtrlSetData($progress, 100)
  GUICtrlSetData($exitButton, "Quit (終了)")
  ;GUICtrlSetData($label, "Update finished!")

  While True
    Local $guimsg = GuiGetMsg() ;Get GUI Messages and store it in the variable $guimsg
    Select ;Select statment to distinguish what to do when a GUI Message occurs
    Case $guimsg = $GUI_EVENT_CLOSE
      ExitLoop
    Case $guimsg = $exitButton
      ExitLoop
    EndSelect
  WEnd
  GuiDelete()
EndFunc

; EOF
