#SingleInstance, Force
#NoEnv

#Include, AutoXYWH.ahk

SetBatchLines, -1
version = "3.0.31"
ontop := false
shortWin := false
ALLfiles := Object()
videoPath := A_ScriptDir
historyFileName := "history.txt"

settingsFileName := "settings.ini"
settingsPath = %A_ScriptDir%\%settingsFileName%
languagesDir := "languages"
language := "en"
specialParams := ""
imagesFolder := "images"
downloadsDirName := "downloads"

video_provider := "youtube-dl.exe"
providerLinkForDownload := "http://46j.ru/files/youtube-dl.exe"
video_providerLink := "https://ytdl-org.github.io/youtube-dl/download.html"

;languages settings
IfExist, %settingsPath%
{
	;IniRead, OutputVar, Filename [, Section, Key, Default]
	IniRead, language, %settingsPath% , main, language, en
	IniRead, specialParams, %settingsPath% , main, specialParams, #
	if (specialParams = "#")
		specialParams := ""
} else 
{
	;IniWrite, Value, Filename, Section [, Key] 
	IniWrite, %language%, %settingsPath%, main , language
}
IfNotExist, %A_ScriptDir%\%languagesDir%
{
  FileCreateDir, %A_ScriptDir%\%languagesDir%
}

doneMsg := getTranslatedString("doneMsg", "Done")
historyEmpty := getTranslatedString("historyEmpty", "History is empty")

video_providerNotice := "We cant find " . video_provider . " But it needle for programm work.`nDownload it from: " . video_providerLink
providerQuestionDownload := getTranslatedString("providerQuestionDownload", "Would you like to download it? (press Yes or No)")

getTranslatedString(valueName, defaultValue)
{
	global language
	global languagesDir
	IniRead, OutputVar, %A_ScriptDir%\%languagesDir%\%language%.ini , main, %valueName%, =
	if (OutputVar = "=") {
		IniWrite, %defaultValue%, %A_ScriptDir%\%languagesDir%\%language%.ini, main , %valueName%
		return defaultValue
	}
	return OutputVar
}

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

AddMenu(menuType, menuName, menuSub, menuIcon, isSeparator = 0)
{
	global imagesFolder
	if (isSeparator = 1) {
		Menu, %menuType%, Add
		return
	}
	asd := menuType . RegExReplace(menuName,"\x20{1,}","_")
	translatedName := getTranslatedString(menuType . RegExReplace(menuName,"\x20{1,}","_"), menuName)
	Menu, %menuType%, Add, %translatedName%, %menuSub%
	IfExist, %A_ScriptDir%\%imagesFolder%\%menuIcon%.png
		Menu, %menuType%, Icon, %translatedName%, %A_ScriptDir%\%imagesFolder%\%menuIcon%.png,, 0
	return
}

IfExist, %A_ScriptDir%\%imagesFolder%\youtube_dl.ico
	Menu, Tray, Icon, %A_ScriptDir%\%imagesFolder%\youtube_dl.ico,, 0

;GUI translates
DriveSpaceFree, driveSpaceFreeMB, %videoPath%
folderMsg := getTranslatedString("folderMsg", "Folder")
showImagesMsg := getTranslatedString("showImagesMsg", "+images")
BufferMsg := getTranslatedString("BufferMsg", "Buffer")
DloadMsg := getTranslatedString("DloadMsg", "Download")
SettingsMsg := getTranslatedString("SettingsMsg", "Settings")
ListViewColFileSize := getTranslatedString("ListViewColFileSize", "File Size")
ListViewColName := getTranslatedString("ListViewColName", "File Size")
MainWinTitle := getTranslatedString("MainWinTitle", "Video dloader (youtube and etc)")

Gui, Add, Edit, x6 y5 w320 h20 vPath,
Gui, Add, Button, x336 y5 w70 gFromClipBoard vFromClipBoard, %BufferMsg%
Gui, Add, Checkbox, Checked x6 y46 vCheckThumbnails , %showImagesMsg%
Gui, Add, ComboBox, x70 y40 vVideoFormat AltSubmit ,Best||View variants|3gp 176x144|webm 640x360|mp4 640x360|mp4 hd720|webm audio 1|webm audio 2|m4a audio 3|webm audio 4|webm audio 5|webm 256x144|mp4 256x144|webm 1280x720|mp4 1280x720|webm 1920x1080|mp4 1920x1080
Gui, Add, Button, x195 y40 w60 gGoFolder vGoFolder, %folderMsg%
Gui, Add, Button, x265 y40 w60 gGoLoad vGoLoad, %DloadMsg%
Gui, Add, Button, x335 y40 w70 vSettingsButton gSettings, %SettingsMsg%
Gui, Add, ListView, x6 r25 w400 +Grid vTLV AltSubmit gResultTable, №  |%ListViewColFileSize% |%ListViewColName%
Gui, Add, StatusBar, vStatusBar,
Gui, Font, s22 cFFFFFF Bold, Verdana ; If desired, use a line like this to set a new default font for the window.
GuiControl, Font, TextArea
Gui, Color, FFFFFF
Gui +Resize

;translate menu 

AddMenu("MoveToMenu", "Choice folder", "FileMoveTo", "folder_text")
AddMenu("MoveToMenu", "Create new dir", "FileMoveNewDir", "folder_add")
IfExist, %A_ScriptDir%\%downloadsDirName%
{
    Loop, %A_ScriptDir%\%downloadsDirName%\*.*, 2
    {
		AddMenu("MoveToMenu", A_LoopFileName, "FileMoveTo", "folder")
    }
} else {
  FileCreateDir, %A_ScriptDir%\%downloadsDirName%
}

AddMenu("LanguageMenu", "Add new language", "AddLanguage", "language")
IfExist, %A_ScriptDir%\%languagesDir%
{
    Loop, %A_ScriptDir%\%languagesDir%\*.ini
    {
    	SplitPath, A_LoopFileName , OutFileName, OutDir, OutExtension, OutNameNoExt
		AddMenu("LanguageMenu", OutNameNoExt, "SetLanguageTo", "language")
    }
}

AddMenu("MyContextMenu", "Open file (or double-click in table)", "MenuOpen", "document")
AddMenu("MyContextMenu", "Move to", ":MoveToMenu", "move")
AddMenu("MyContextMenu", "", "", "", 1)
AddMenu("MyContextMenu", "Set language to", ":LanguageMenu", "language")
AddMenu("MyContextMenu", "Change path for files", "VPath", "smart_folder")
AddMenu("MyContextMenu", "Short-Full window trigger", "ShortVersion", "crop")
AddMenu("MyContextMenu", "Update list", "UpdateList", "refresh")
AddMenu("MyContextMenu", "Open files folder", "GoFolder", "opened_folder")
AddMenu("MyContextMenu", "history", "OpenHistoryFile", "list")
AddMenu("MyContextMenu", "Set spec params", "SetSpecialParams", "terminal")
AddMenu("MyContextMenu", "on top on-off", "SetOnTop", "terminal")
AddMenu("MyContextMenu", "Reload", "Reload", "restart")
AddMenu("MyContextMenu", "About", "About", "info")

Menu, Tray, Add , &Reload, Reload

Gui, Show, w420 h550, %MainWinTitle% v%version%
UpdateFileList()

IfNotExist, %A_ScriptDir%\%video_provider%
{
	;msgbox, %video_providerNotice%
	MsgBox, 36,, %video_providerNotice% `n
	IfMsgBox Yes
	{
	    UrlDownloadToFile, %providerLinkForDownload%, %A_ScriptDir%\%video_provider%
	    MsgBox %doneMsg%
	}
}

Return

; NEED
; Short version - last DL file name and hotkey/button for DL
; ContextMoveFileTo and ContextOpenFile

^+0::
	Gui, Show
return

GuiSize:
	If (A_EventInfo = 1) ; The window has been minimized.
		Return
	AutoXYWH("wh", "TLV")
	AutoXYWH("w", "Path")
	AutoXYWH("w", "VideoFormat")

	AutoXYWH("x", "FromClipBoard")
	AutoXYWH("x", "GoFolder")
	AutoXYWH("x", "GoLoad")
	AutoXYWH("x", "SettingsButton")
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

SetOnTop:
	Gui +LastFound
	if (ontop) {
		Gui, -AlwaysOnTop
		ontop := false
	} else {
		Gui, +AlwaysOnTop
		ontop := true
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
	IniWrite, %specialParams%, %settingsPath%, main , specialParams
return


FileMoveNewDir:
	InputBox, newDirName , Enter new dir name
	if (newDirName = "")  {
		return
	}
	FileCreateDir, %A_ScriptDir%\%downloadsDirName%\%newDirName%
	Menu, MoveToMenu, Add, %newDirName%, FileMoveTo
	Menu, MoveToMenu, Icon, %newDirName%, %A_ScriptDir%\%imagesFolder%\opened_folder.png,, 0
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
		msgbox, %historyEmpty%
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
		msgbox, %Contents%
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

SetLanguageTo:
	IniWrite, %A_ThisMenuItem%, %settingsPath%, main , language
	Reload
return

AddLanguage:
return

FileMoveTo:
	Array := Object()
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

	    Array.Insert(FileName)
		SplitPath, FileName , OutFileName, OutDir, OutExtension, OutNameNoExt

	    IfExist, %A_ScriptDir%\%OutNameNoExt%.jpg
	    {
	    	;FileMove, %A_ScriptDir%\%OutNameNoExt%.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%.png
	    {
	    	;FileMove, %A_ScriptDir%\%OutNameNoExt%.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	}
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

^+!0::
	Gui, Show
	Sleep, 400
	GuiControl,, Path, %clipboard%
	Goto, GoLoad
return

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