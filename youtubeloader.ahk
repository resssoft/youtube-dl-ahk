#SingleInstance, Force
#NoEnv
SetBatchLines, -1
videoPath := A_ScriptDir
ALLfiles := Object()

NOTexistFile(currentVal)
{
  global ALLfiles
  for index, element in ALLfiles ; Recommended approach in most cases.
  {
    if (currentVal = element)
      return false
  }
  return true
}

addnewrow(textvar2,textvar3,textcolor:="0x000000",bgcolor="0xFFFFFF")
{
	Gui, ListView, TLV
	Last_A_Index := LV_GetCount() + 1
	LV_Add("icon1",Last_A_Index,textvar2,textvar3)
	LastRow := LV_GetNext() - 1
	LV_Modify(LastRow, "Focus")
	LastRowQ := LV_GetCount()-1
	LV_ModifyCol("Hdr")
}

UpdateFileList()
{
  Gui, ListView, TLV
  global ALLfiles
  extensions := "mp4,mkv,mka,webm,weba,mp3,mpa,MP4,MKV,MKA,WEBM,WEBA,MP3,MPA"
  Loop * {
    ;LV_Add("",A_Index,A_LoopFileSizeMB,A_LoopFileName)
    if A_LoopFileExt in %extensions%
    if (NOTexistFile(A_LoopFileName)) {
      addnewrow(A_LoopFileSizeMB . " MB", A_LoopFileName, "0x000000", "0xfdaabd")
    }
    ALLfiles.Insert(A_LoopFileName)
  }
}

Gui, Add, Edit, x6 y5 w320 h20 vPath,
Gui, Add, Button, x336 y5 w70 gFromClipBoard , Buffer
Gui, Add, Checkbox, Checked x6 y46 vCheckThumbnails , +images
Gui, Add, ComboBox, x70 y40 vVideoFormat AltSubmit ,Best||View variants|3gp 176x144|webm 640x360|mp4 640x360|mp4 hd720|webm audio 1|webm audio 2|m4a audio 3|webm audio 4|webm audio 5|webm 256x144|mp4 256x144|webm 1280x720|mp4 1280x720|webm 1920x1080|mp4 1920x1080
Gui, Add, Button, x195 y40 w60 gGoFolder, Folder
Gui, Add, Button, x265 y40 w60 gGoLoad, Dload
Gui, Add, Button, x335 y40 w20 gVPath, ...
Gui, Add, Button, x365 y40 w20 gUpdateList, 🔃

Gui, Add, ListView, x6 r25 w400 +Grid vTLV AltSubmit gResultTable, №  |File Size |Name
Gui, Add, StatusBar,,
SB_SetText("files folder: " . videoPath)
Gui, Font, s22 cFFFFFF Bold, Verdana ; If desired, use a line like this to set a new default font for the window.
GuiControl, Font, TextArea
Gui, Color, FFFFFF

; Create a popup menu to be used as the context menu:
Menu, MyContextMenu, Add, Open, ContextOpenFile
Menu, MyContextMenu, Add, Open, ContextMoveFileTo
Menu, MyContextMenu, Default, Open  ; Make "Open" a bold font to indicate that double-click does the same thing.

Menu, Tray, Add , &Reload, Reload

Gui, Show, w420 h550, Video dloader (youtube and etc) v 2.8
UpdateFileList()
Return

^+0::
Gui, Show
return

Reload:
Reload
Return

GoFolder:
; A_ScriptDir A_WorkingDir
explorerpath:= "explorer /select," A_ScriptDir
Run, %explorerpath%
return

UpdateList:
UpdateFileList()
return

VPath:
;videoPath := ""
msgbox, %videoPath%
FileSelectFolder, videoPath, %videoPath%, 3, Select folder for files
SB_SetText("files folder: " . videoPath)
return

GoLoad:
Gui, Submit, NoHide
params := ""
lastparams := ""
video_provider := "youtube-dl.exe"
nodownload := 0
if (CheckGetQualityList = 1) {
	params := %params% . " -F"
	nodownload := 1
}
if (nodownload = 0) {
	if (CheckThumbnails = 1) {
		params := params " --write-all-thumbnails"
	}
;Best 1||Show variants 2|3gp 176x144 3|webm 640x360 4|mp4 640x360 5|mp4 hd720 6|webm audio 1 7|webm audio 2 8|m4a audio 3 9|webm audio 4 10|webm audio 5 11 |webm 256x144 12|mp4 256x144 13|webm 1280x720 14|mp4 1280x720 15|webm 1920x1080 16|mp4 1920x1080 17
	if (VideoFormat = 2) {
		params := params " -F"
		lastparams := %lastparams% . " > formats.txt"
	}
	if (VideoFormat = 3) {
		params := params " -f 17"
	}
	if (VideoFormat = 4) {
		params := params " -f 43"
	}
	if (VideoFormat = 5) {
		params := params " -f 18"
	}
	if (VideoFormat = 6) {
		params := params " -f 22"
	}
	if (VideoFormat = 7) {
		params := params " -f 249"
	}
	if (VideoFormat = 9) {
		params := params " -f 140"
	}
	if (VideoFormat = 11) {
		params := params " -f 171"
	}
	if (VideoFormat = "15") {
		params := params " -f 136"
	}
	if (VideoFormat = "16") {
		params := params " -f 248"
	}
	if (VideoFormat = "17") {
		params := params " -f 137"
	}
	if (VideoFormat != "1" && params = " --write-all-thumbnails") {
		params := params " -f " VideoFormat
	}
}

quotes = `"
if (InStr(Path,"http")) {
	params := params " " quotes Path quotes
} else {
	params := params " " quotes "http://www.youtube.com/watch?v=" Path quotes
}

fullPath := video_provider " " params

RunWait %fullPath%

if (VideoFormat = 2) {
	FileRead, Contents, formats.txt
	if not ErrorLevel {
		msgbox, Contents
	}
}
UpdateFileList()

;Write to log
FileAppend, % fullPath "`n", history.txt
Return

ContextOpenFile:
	MsgBox in develop
return

ContextMoveFileTo:
	MsgBox in develop
return

ResultTable:
if (A_GuiEvent = "DoubleClick")
{
    ;LV_GetText(RowText, A_EventInfo)  ; Get the text from the row's first field.
    ;ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"
    LV_GetText(FileName, A_EventInfo, 3)  ; Get the text of the second field.
    Run %A_ScriptDir%\%FileName%,, UseErrorLevel
    if ErrorLevel
        MsgBox Could not open "%A_ScriptDir%\%FileName%".
}
if (A_GuiEvent = "RightClick")
{
	MouseGetPos, xpos, ypos 
    Menu, MyContextMenu, Show, %xpos%, %ypos%
}
Return

GuiClose:
Gui, Hide
return

GuiDropFiles:
GuiControl,, Path, %a_guievent%
Return

FromClipBoard:
GuiControl,, Path, %clipboard%
Goto, GoLoad
Return


;-x, --extract-audio              Convert video files to audio-only files
;                                     (requires ffmpeg or avconv and ffprobe or
;                                     avprobe)
;    --audio-format FORMAT            Specify audio format: "best", "aac",
;                                     "vorbis", "mp3", "m4a", "opus", or "wav";
;                                     "best" by default
;    --audio-quality QUALITY          Specify ffmpeg/avconv audio quality, insert
;                                     a value between 0 (better) and 9 (worse)
;                                     for VBR or a specific bitrate like 128K
;                                     (default 5)
;--write-all-thumbnails


;--write-description
;--write-info-json
;--write-annotations

; =============== Features
; Update!
; templates
;--config-location A_ScriptDir

; =============== Changes
; v 2.5 check links and dload from other sites (not only youtube)
; v 2.7 = add reload to tray and add to list *.mp4, *.mkv, *.mka, *.webm, *.weba, *.mp3
; v 2.8 Remove color rows (func LV_ColorChange) - it is not work