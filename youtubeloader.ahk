#SingleInstance, Force
#NoEnv
SetBatchLines, -1
videoPath := A_ScriptDir
ALLfiles := Object()
shortWin := false
downloadsDirName := "downloads"
historyFileName := "history.txt"
specialParams := ""

video_provider := "youtube-dl.exe"
video_providerLink := "https://ytdl-org.github.io/youtube-dl/download.html"
video_providerNotice := "We cant find " . video_provider . " But it needle for programm work.`nDownload it from: " . video_providerLink

Menu, Tray, Icon, %A_ScriptDir%\system\youtube_dl.ico,, 0

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
  global shortWin
  global videoPath
  lastFileName := ""
  extensions := "mp4,mkv,mka,webm,weba,mp3,mpa,MP4,MKV,MKA,WEBM,WEBA,MP3,MPA"
  Loop * {
    if A_LoopFileExt in %extensions%
    {
	    if (NOTexistFile(A_LoopFileName)) {
	      addnewrow(A_LoopFileSizeMB . " MB", A_LoopFileName, "0x000000", "0xfdaabd")
	    }
	    ALLfiles.Insert(A_LoopFileName)
	    lastFileName := A_LoopFileName
    }
  }
  UpdateStatusBar()
  if (shortWin) {
		DriveSpaceFree, driveSpaceFreeMB, %videoPath%
		SB_SetText("Drive[" . driveSpaceFreeMB . "MB] " . lastFileName)
  }
}

UpdateStatusBar()
{
	global videoPath
	DriveSpaceFree, driveSpaceFreeMB, %videoPath%
	SB_SetText("[" . driveSpaceFreeMB . "MB free] folder: " . videoPath)
}

GuiControlShowHide(controls,showhide="Hide"){
	Loop,Parse,controls,|
	GuiControl, %showhide%,%A_LoopField%
}

DriveSpaceFree, driveSpaceFreeMB, %videoPath%

Gui, Add, Edit, x6 y5 w320 h20 vPath,
Gui, Add, Button, x336 y5 w70 gFromClipBoard , Buffer
Gui, Add, Checkbox, Checked x6 y46 vCheckThumbnails , +images
Gui, Add, ComboBox, x70 y40 vVideoFormat AltSubmit ,Best||View variants|3gp 176x144|webm 640x360|mp4 640x360|mp4 hd720|webm audio 1|webm audio 2|m4a audio 3|webm audio 4|webm audio 5|webm 256x144|mp4 256x144|webm 1280x720|mp4 1280x720|webm 1920x1080|mp4 1920x1080
Gui, Add, Button, x195 y40 w60 gGoFolder, Folder
Gui, Add, Button, x265 y40 w60 gGoLoad, Dload
Gui, Add, Button, x335 y40 w60 vSettingsButton gSettings, Settings
Gui, Add, ListView, x6 r25 w400 +Grid vTLV AltSubmit gResultTable, №  |File Size |Name
Gui, Add, StatusBar, vStatusBar,
Gui, Font, s22 cFFFFFF Bold, Verdana ; If desired, use a line like this to set a new default font for the window.
GuiControl, Font, TextArea
Gui, Color, FFFFFF
Gui +Resize


Menu, MoveToMenu, Add, Choice folder, FileMoveTo
Menu, MoveToMenu, Icon, Choice folder, %A_ScriptDir%\system\folder_text.png,, 0

Menu, MoveToMenu, Add, Create new dir, FileMoveNewDir
Menu, MoveToMenu, Icon, Create new dir, %A_ScriptDir%\system\folder_add.png,, 0

IfExist, %A_ScriptDir%\%downloadsDirName%
{
    Loop, %A_ScriptDir%\%downloadsDirName%\*.*, 2
    {
  		Menu, MoveToMenu, Add, %A_LoopFileName%, FileMoveTo
  		Menu, MoveToMenu, Icon, %A_LoopFileName%, %A_ScriptDir%\system\folder.png,, 0
    }
} else {
  FileCreateDir, %A_ScriptDir%\%downloadsDirName%
}

Menu, MyContextMenu, Add, Open file (or double-click in table), MenuOpen
Menu, MyContextMenu, Icon, Open file (or double-click in table), %A_ScriptDir%\system\document.png,, 0

Menu, MyContextMenu, Add, Move to, :MoveToMenu
Menu, MyContextMenu, Icon, Move to, %A_ScriptDir%\system\move.png,, 0

Menu, MyContextMenu, Add

Menu, MyContextMenu, Add, Change path for files, VPath
Menu, MyContextMenu, Icon, Change path for files, %A_ScriptDir%\system\smart_folder.png,, 0

Menu, MyContextMenu, Add, Short-Full window trigger, ShortVersion
Menu, MyContextMenu, Icon, Short-Full window trigger, %A_ScriptDir%\system\crop.png,, 0

Menu, MyContextMenu, Add, Update list, UpdateList
Menu, MyContextMenu, Icon, Update list, %A_ScriptDir%\system\refresh.png,, 0

Menu, MyContextMenu, Add, Open files folder, GoFolder
Menu, MyContextMenu, Icon, Open files folder, %A_ScriptDir%\system\opened_folder.png,, 0

Menu, MyContextMenu, Add, history, OpenHistoryFile
Menu, MyContextMenu, Icon, history, %A_ScriptDir%\system\list.png,, 0

Menu, MyContextMenu, Add, set spec params, SetSpecialParams
Menu, MyContextMenu, Icon, set spec params, %A_ScriptDir%\system\terminal.png,, 0

Menu, MyContextMenu, Add, Reload, Reload
Menu, MyContextMenu, Icon, Reload, %A_ScriptDir%\system\restart.png,, 0

Menu, MyContextMenu, Add, About, About
Menu, MyContextMenu, Icon, About, %A_ScriptDir%\system\info.png,, 0

Menu, Tray, Add , &Reload, Reload

Gui, Show, w420 h550, Video dloader (youtube and etc) v 2.9
UpdateFileList()

IfNotExist, %A_ScriptDir%\%video_provider%
{
	msgbox, %video_providerNotice%
}

Return

; NEED
; Short version - last DL file name and hotkey/button for DL
; ContextMoveFileTo and ContextOpenFile

^+0::
	Gui, Show
return

Reload:
	Reload
Return

ShortVersion:
Gui +LastFound
if (shortWin) {
	Gui, Show, w420 h550
	GuiControlShowHide("TLV","show")

	shortWin := false
} else {
	Gui, Show, w420 h88
	GuiControlShowHide("TLV","hide")
	shortWin := true
}
Return

GoFolder:
; A_ScriptDir A_WorkingDir
;explorerpath:= "explorer /select," A_ScriptDir
explorerpath := videoPath
Run, %explorerpath%
return

UpdateList:
UpdateFileList()
return

Settings:
GuiControlGet, SettingsButtonPos , Pos, SettingsButton
Menu, MyContextMenu, Show, %SettingsButtonPosX%, %SettingsButtonPosY%
return

SetSpecialParams:
	InputBox, NewSpecialParams , Enter SpecialParams, , , , , , , , , %specialParams%
	if (NewSpecialParams = "")  {
		return
	}
	specialParams := NewSpecialParams
return


FileMoveNewDir:
	InputBox, newDirName , Enter new dir name
	if (newDirName = "")  {
		return
	}
	FileCreateDir, %A_ScriptDir%\%downloadsDirName%\%newDirName%
	Menu, MoveToMenu, Add, %newDirName%, FileMoveTo
	Menu, MoveToMenu, Icon, %newDirName%, %A_ScriptDir%\system\opened_folder.png,, 0
return

VPath:
FileSelectFolder, newVideoPath, %videoPath%, 3, Select folder for files
if (newVideoPath = "")  {
	return
}
videoPath := newVideoPath
UpdateStatusBar()
return

OpenHistoryFile:
	IfNotExist, %A_ScriptDir%\%historyFileName%
	{
		msgbox, History is empty
		return
	} else {
		Run %A_ScriptDir%\%historyFileName%
	}
return

GoLoad:
IfNotExist, %A_ScriptDir%\%video_provider%
{
	msgbox, %video_providerNotice%
	return
}
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

fullPath := video_provider " " params " " specialParams

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

FileMoveTo:
	Loop % LV_GetCount("S")
	{
		RowNumber := LV_GetNext(RowNumber)
		if not RowNumber  ; The above returned zero, so there are no more selected rows.
	        break
	    LV_GetText(FileName, RowNumber, 3)
	    FileMove, %A_ScriptDir%\%FileName%, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    if ErrorLevel
	    {
	        MsgBox Could not move "%A_ScriptDir%\%FileName%" to %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\
	        Continue
	    } else 
	    {
	    	LV_Delete(RowNumber)
	    }

		SplitPath, FileName , OutFileName, OutDir, OutExtension, OutNameNoExt
	    IfExist, %A_ScriptDir%\%OutNameNoExt%.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%.png
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	}
Sleep, 1000
UpdateFileList()
return

MenuOpen:
Gui +LastFound
RowNumber = 0
Loop % LV_GetCount("S")
{
	RowNumber := LV_GetNext(RowNumber)
	if not RowNumber  ; The above returned zero, so there are no more selected rows.
        break
    LV_GetText(FileName, RowNumber, 3)
    Run %A_ScriptDir%\%FileName%,, UseErrorLevel
    if ErrorLevel
        MsgBox Could not open "%A_ScriptDir%\%FileName%".
}
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

About:
FileRead, readme, README.md
msgbox, %readme%
Return
msgbox, Download files from yotube`
		and others sites`nMore info: https://github.com/ytdl-org/youtube-dl/blob/master/README.md#readme
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