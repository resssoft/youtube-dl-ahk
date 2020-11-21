#SingleInstance, Force
#NoEnv

#Include, AutoXYWH.ahk

SetBatchLines, -1
version = "3.1.03"
ontop := false
shortWin := false
listMode := 0
ALLfiles := Object()
videoPath := A_ScriptDir
historyFileName := "history.txt"
SplashImage := ""

settingsFileName := "settings.ini"
settingsPath = %A_ScriptDir%\%settingsFileName%
languagesDir := "languages"
language := "en"
specialParams := ""
imagesFolder := "images"
downloadsDirName := "downloads"

bitness := A_PtrSize*8
libWebpPath := A_ScriptDir . "\libwebp" . bitness . ".dll"

libwebp32Url := "https://s3.amazonaws.com/resizer-dynamic-downloads/webp/0.5.2/x86/libwebp.dll"
libwebp64Url := "https://s3.amazonaws.com/resizer-dynamic-downloads/webp/0.5.2/x86_64/libwebp.dll"
lib := A_ScriptDir . "\libwebp" . bitness . ".dll"
if !FileExist(libWebpPath)
   URLDownloadToFile, % libwebp%bitness%Url, % libWebpPath

fileHeadPattenrs := {"webp": {"HEX": "57:45:42:50", "POS": 8, "SIZE": 4}}
; info: https://developers.google.com/speed/webp/docs/riff_container#webp_file_header

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

disableInTheScheduleMode := getTranslatedString("disableInTheScheduleMode", "disable In The Schedule Mode")
doneMsg := getTranslatedString("doneMsg", "Done")
historyEmpty := getTranslatedString("historyEmpty", "History is empty")

MessageMoved := getTranslatedString("Moved", "Moved")
MessageFilesAfterCount := getTranslatedString("Files", "Files")

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

checkFileFormat(filePath, format) {
    global fileHeadPattenrs

    oFile := FileOpen(filePath, "r")
    oFile.Pos := fileHeadPattenrs[format]["POS"]
    Loop, % fileHeadPattenrs[format]["SIZE"]
    {
        vNum := oFile.ReadUChar() ;reads data, advances pointer
        vOutputHex .= (A_Index=1?"":":") Format("{:02X}", vNum)
    }
    if (vOutputHex = fileHeadPattenrs[format]["HEX"]) {
        return true
    } else {
        return false
    }
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

UpdateFileList(withClear=0)
{
  Gui, ListView, TLV
  global ALLfiles
  global shortWin
  global videoPath
  if (withClear=1) {
        ALLfiles:=[]
        LV_Delete()
  }
  lastFileName := ""
  extensions := "mp4,mkv,mka,webm,weba,mp3,mpa,m4a,MP4,MKV,MKA,WEBM,WEBA,MP3,MPA,M4A"
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
  LV_ModifyCol()
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
	sbText := "[" . driveSpaceFreeMB . "MB free] folder: " . videoPath
	if (listMode = 1) {
	    sbText := "[S] " . sbText
	}
	SB_SetText(sbText)
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
	translatedName := getTranslatedString(menuType . RegExReplace(menuName,"\x20{1,}","_"), menuName)
	Menu, %menuType%, Add, %translatedName%, %menuSub%
	IfExist, %A_ScriptDir%\%imagesFolder%\%menuIcon%.png
		Menu, %menuType%, Icon, %translatedName%, %A_ScriptDir%\%imagesFolder%\%menuIcon%.png,, 0
	return
}

SplashImageGUI(Picture, X, Y, Duration, Transparent = false, width = 100)
{
    global libWebpPath
    ;TODO: use X, Y, W, H
    if (checkFileFormat(Picture, "webp") = true) {
        hBitmap := HBitmapFromWebP(libWebpPath, Picture, width, height)
        SB_SetText("webp " . Picture)
    } else {
        hBitmap := LoadPicture(Picture)
        SB_SetText("jpg " . Picture)
    }
    GuiControl,, IMGV, HBITMAP:%hBitmap%
}

flagInvert(flag)
{
    if (flag = 1)
    {
        flag = 0
    } else {
        flag = 1
    }
    return flag
}

SaveToIni(iniName)
{
    Gui +LastFound
    rowNumber := 0
    columnCount := LV_GetCount("Column")
    rowCount := LV_GetCount()
    Loop %rowCount%
    {
        rowNumber := A_Index
        Loop %columnCount%
        {
            columnNumber := A_Index
            LV_GetText(itemValue, rowNumber, columnNumber)
            IniWrite, %itemValue%, %A_ScriptDir%\%iniName%, row-%rowNumber%, col-%columnNumber%
        }
    }
}

LoadFromIni(iniName, rowCount = 0)
{
    Gui +LastFound
    columnCount := LV_GetCount("Column")
    rowCount := LV_GetCount()
    LV_Delete()
    rowCountClear := LV_GetCount()
    IfNotExist, %A_ScriptDir%\%iniName%
        return
    Loop
    {
        rowNumber := A_Index
        IniRead, itemValue, %A_ScriptDir%\%iniName%, row-%rowNumber%, col-1
        itemLength := StrLen(itemValue)
        if (itemLength = 0 OR itemValue = "ERROR") {
            break
        }
        LV_Add("icon1", "")
        Loop
        {
            columnNumber := A_Index
            LV_GetText(itemValue, rowNumber, columnNumber)
            IniRead, itemValue, %A_ScriptDir%\%iniName%, row-%rowNumber%, col-%columnNumber%
            itemLength := StrLen(itemValue)
            if (itemLength = 0 OR itemValue = "ERROR") {
                break
            }
            LV_Modify(rowNumber, "col" . columnNumber, itemValue)
        }
    }
}

ScheduleMode() {
    Gui +LastFound
    global listMode
    global ScheduleMsg
    global BufferMsg
    global StartMsg
    global folderMsg
    listMode := flagInvert(listMode)
    if (listMode = 1) {
        GuiControl ,, FromClipBoard, %ScheduleMsg%
        GuiControl ,, GoFolder, %StartMsg%

        SaveToIni("filenamesTemp.ini")
        LoadFromIni("ScheduledTemp.ini")
    } else {
        GuiControl ,, FromClipBoard, %BufferMsg%
        GuiControl ,, GoFolder, %folderMsg%
        SaveToIni("ScheduledTemp.ini")
        LoadFromIni("filenamesTemp.ini")
        FileDelete, %A_ScriptDir%\filenamesTemp.ini
    }
    UpdateStatusBar()
}

HBitmapFromWebP(libwebp, WebpFilePath, ByRef width, ByRef height) {
   file := FileOpen(WebpFilePath, "r")
   len := file.RawRead(buff, file.Length)
   file.Close()
   if !len
      throw Exception("Failed to read the image file")
   
   if !hLib := DllCall("LoadLibrary", Str, libwebp, Ptr)
      throw Exception("Failed to load library. Error:" . A_LastError)
   
   if !pBits := DllCall(libwebp . "\WebPDecodeRGBA", Ptr, &buff, Ptr, len, IntP, width, IntP, height) {
      DllCall("FreeLibrary", Ptr, hLib)
      throw Exception("Failed to decode the image file")
   }
   
   oGDIp := new GDIp
   pBitmap := oGDIp.CreateBitmapFromScan0(width, height, pBits)
   hBitmap := oGDIp.CreateHBITMAPFromBitmap(pBitmap)
   DllCall(libwebp . "\WebPFree", Ptr, pBits)
   oGDIp.DisposeImage(pBitmap)
   DllCall("FreeLibrary", Ptr, hLib)
   Return hBitmap
}

class GDIp   {
   __New() {
      if !DllCall("GetModuleHandle", Str, "gdiplus", Ptr)
         DllCall("LoadLibrary", Str, "gdiplus")
      VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
      DllCall("gdiplus\GdiplusStartup", UPtrP, pToken, Ptr, &si, Ptr, 0)
      this.token := pToken
   }
   
   __Delete()  {
      DllCall("gdiplus\GdiplusShutdown", Ptr, this.token)
      if hModule := DllCall("GetModuleHandle", Str, "gdiplus", Ptr)
         DllCall("FreeLibrary", Ptr, hModule)
   }
   
   CreateBitmapFromScan0(Width, Height, pBits, PixelFormat := 0x26200A, Stride := "") {
      if !Stride {
         bpp := (PixelFormat & 0xFF00) >> 8
         Stride := ((Width * bpp + 31) & ~31) >> 3
      }
      DllCall("gdiplus\GdipCreateBitmapFromScan0", Int, Width, Int, Height
                                                 , Int, Stride, Int, PixelFormat
                                                 , Ptr, pBits, PtrP, pBitmap)
      Return pBitmap
   }
   
   CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff) {
      DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", Ptr, pBitmap, PtrP, hbm, Int, Background)
      return hbm
   }
   
   DisposeImage(pBitmap) {
      return DllCall("gdiplus\GdipDisposeImage", Ptr, pBitmap)
   }
}


IfExist, %A_ScriptDir%\%imagesFolder%\youtube_dl.ico
	Menu, Tray, Icon, %A_ScriptDir%\%imagesFolder%\youtube_dl.ico,, 0

;GUI translates
DriveSpaceFree, driveSpaceFreeMB, %videoPath%
folderMsg := getTranslatedString("folderMsg", "Folder")
showImagesMsg := getTranslatedString("showImagesMsg", "+images")
BufferMsg := getTranslatedString("BufferMsg", "Buffer")
ScheduleMsg := getTranslatedString("ScheduleMsg", "Schedule")
StartMsg := getTranslatedString("StartMsg", "Start")
DloadMsg := getTranslatedString("DloadMsg", "Download")
SettingsMsg := getTranslatedString("SettingsMsg", "Settings")
ListViewColFileSize := getTranslatedString("ListViewColFileSize", "File Size")
ListViewColName := getTranslatedString("ListViewColName", "File Size")
MainWinTitle := getTranslatedString("MainWinTitle", "Video dloader (youtube and etc)")

Gui, Add, Edit, x6 y5 w320 h20 vPath,
Gui, Add, Button, x336 y5 w70 gFromClipBoard vFromClipBoard, %BufferMsg%
Gui, Add, Checkbox, Checked x6 y46 vCheckThumbnails , %showImagesMsg%
Gui, Add, ComboBox, x70 y40 vVideoFormat AltSubmit ,Best||View variants|3gp 176x144|webm 640x360|mp4 640x360|mp4 hd720|webm audio 1|webm audio 2|m4a audio 3|webm audio 4|webm audio 5|webm 256x144|mp4 256x144|webm 1280x720|mp4 1280x720|webm 1920x1080|mp4 1920x1080|bestmp4
Gui, Add, Button, x195 y40 w60 gGoFolder vGoFolder, %folderMsg%
Gui, Add, Button, x265 y40 w60 gGoLoad vGoLoad, %DloadMsg%
Gui, Add, Button, x335 y40 w70 vSettingsButton gSettings, %SettingsMsg%
Gui, Add, ListView, x6 r20 w400 +Grid vTLV AltSubmit gResultTable, №  |%ListViewColFileSize% |%ListViewColName%
Gui, Add, Picture, w100 h-1 vIMGV,

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
AddMenu("MyContextMenu", "Change path for files", "VPath", "smart_folder")
AddMenu("MyContextMenu", "Short-Full window trigger", "ShortVersion", "crop")
AddMenu("MyContextMenu", "Update list", "UpdateList", "refresh")
AddMenu("MyContextMenu", "Open files folder", "GoFolder", "opened_folder")
AddMenu("MyContextMenu", "on top on-off", "SetOnTop", "terminal")
AddMenu("MyContextMenu", "Schedule mode On", "Schedule", "terminal")

AddMenu("SystemMenu", "Set language to", ":LanguageMenu", "language")
AddMenu("SystemMenu", "Set spec params", "SetSpecialParams", "terminal")
AddMenu("SystemMenu", "history", "OpenHistoryFile", "list")
AddMenu("SystemMenu", "About", "About", "info")
AddMenu("SystemMenu", "Update downloader", "UpdateDownloader", "info")
AddMenu("SystemMenu", "Reload", "Reload", "restart")
AddMenu("MyContextMenu", "System", ":SystemMenu", "terminal")

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

;CTRL+SHIFT+0
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


;CTRL+SHIFT+R
^+R::
Reload:
	Reload
Return

;CTRL+SHIFT+9
^+9::
Schedule:
    ScheduleMode()
return

;CTRL+SHIFT+ALT+0
^+!0::
	Gui, Show
	Sleep, 400
	Goto, FromClipBoard
return

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

UpdateDownloader:
	updatePath := video_provider " -U"
	Run %updatePath%
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
if (listMode = 1) {
    downloadAndUpdate("", "")
} else {
    ; A_ScriptDir A_WorkingDir
    ;explorerpath:= "explorer /select," A_ScriptDir
    explorerpath := videoPath
    Run, %explorerpath%
}
return

UpdateList:
if (listMode = 1) {
    msgbox, %disableInTheScheduleMode%
} else {
    UpdateFileList(1)
}
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
    Gui, Submit, NoHide
    return
    prepareLinkAndDownload(Path, VideoFormat, CheckThumbnails, CheckGetQualityList)
Return

prepareLinkAndDownload(Path, VideoFormat, CheckThumbnails, CheckGetQualityList)
{
    global listMode
    global video_provider
    global video_providerNotice

    IfNotExist, %A_ScriptDir%\%video_provider%
    {
        msgbox, %video_providerNotice%
        return
    }
    params := ""
    lastparams := ""
    nodownload := 0
    if (CheckGetQualityList = 1) {
        params := %params% . " -F"
        nodownload := 1
    }
    if (nodownload = 0) {
        if (CheckThumbnails = 1) {
            params := params " --write-all-thumbnails"
        }

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
        if (VideoFormat = "18") {
            params := params " -f bestvideo[ext=mp4]+bestaudio[ext=m4a]"
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

    if (listMode = 1) {
        scheduled(fullPath, Path)
    } else {
        downloadAndUpdate(fullPath, Path)
    }

    if (VideoFormat = 2) {
        sleep, 500
        FileRead, Contents, formats.txt
        if not ErrorLevel {
            msgbox, %Contents%
        }
    } else {
        if (listMode = false) {
            UpdateFileList()
        }
    }
}

downloadAndUpdate(fullPath, Path)
{
    global listMode
    if (fullPath != "") {
        RunWait %fullPath%,,Hide
        FileAppend, % fullPath "`n", history.txt
        FileAppend, % Path "`n", historyURL.txt
        TrayTip, Download item, %Path%, 17
     }
    if (listMode = 1) {
        Gui +LastFound
        rowCount := LV_GetCount()
        Loop %rowCount%
        {
            rowNumber := A_Index
            LV_GetText(newPath, rowNumber, 2)
            LV_GetText(newFullPath, rowNumber, 3)
            LV_Delete(rowNumber)
            SaveToIni("ScheduledTemp.ini")
            downloadAndUpdate(newFullPath, newPath)
            break
        }
        if (rowCount = 0) {
            ScheduleMode()
            FileDelete, %A_ScriptDir%\ScheduledTemp.ini
            UpdateFileList()
        }
    }
    return
}

scheduled(fullPath, Path)
{
    addnewrow(Path, fullPath)
}

SetLanguageTo:
	IniWrite, %A_ThisMenuItem%, %settingsPath%, main , language
	Reload
return

AddLanguage:
return

FileMoveTo:
    Gui +LastFound
	filesForMove := Object()
	RowNumber := 0
	Loop % LV_GetCount("Selected")
	{
		RowNumber := LV_GetNext(RowNumber)
		if not RowNumber  ; The above returned zero, so there are no more selected rows.
	        break
	    LV_GetText(FileName, RowNumber, 3)
	    filesForMove.Insert(FileName)
	}

	filesMovedCount := 0
	for filesMovedIndex, filesMovedItem in filesForMove
	{
	    FileMove, %A_ScriptDir%\%filesMovedItem%, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
        if ErrorLevel
        {
            MsgBox Could not move "%A_ScriptDir%\%filesMovedItem%" to %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ `n %A_LastError%
            Continue
        }
		SplitPath, filesMovedItem , OutFileName, OutDir, OutExtension, OutNameNoExt

	    IfExist, %A_ScriptDir%\%OutNameNoExt%.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
        IfExist, %A_ScriptDir%\%OutNameNoExt%_0.jpg
        {
            FileMove, %A_ScriptDir%\%OutNameNoExt%_0.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
        }
        IfExist, %A_ScriptDir%\%OutNameNoExt%_1.jpg
        {
            FileMove, %A_ScriptDir%\%OutNameNoExt%_1.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
        }
        IfExist, %A_ScriptDir%\%OutNameNoExt%_2.jpg
        {
            FileMove, %A_ScriptDir%\%OutNameNoExt%_2.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
        }
        IfExist, %A_ScriptDir%\%OutNameNoExt%_3.jpg
        {
            FileMove, %A_ScriptDir%\%OutNameNoExt%_3.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
        }
        IfExist, %A_ScriptDir%\%OutNameNoExt%_4.jpg
        {
            FileMove, %A_ScriptDir%\%OutNameNoExt%_4.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
        }


	    IfExist, %A_ScriptDir%\%OutNameNoExt%_640.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%_640.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%_960.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%_960.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%_1280.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%_1280.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%_base.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%_base.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%_medium.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%_medium.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%_small.jpg
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%_small.jpg, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }

	    IfExist, %A_ScriptDir%\%OutNameNoExt%.png
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%.png, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    IfExist, %A_ScriptDir%\%OutNameNoExt%.description
	    {
	    	FileMove, %A_ScriptDir%\%OutNameNoExt%.description, %A_ScriptDir%\%downloadsDirName%\%A_ThisMenuItem%\ , 0
	    }
	    filesMovedCount += 1

	    for fileListIndex, fileListItem in ALLfiles
	    {
	        if (fileListItem = filesMovedItem)
	        {
	            ALLfiles.remove(fileListIndex)
	            break
	        }
	    }
	}
    ;filesForMoveCount := filesForMove.MaxIndex()
    TrayTip, %MessageMoved%, %MessageMoved% %filesMovedCount% %MessageFilesAfterCount%, 17
	UpdateFileList(1)
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
	if (A_GuiEvent = "Normal")
    {
         image := ""
         LV_GetText(FileName, A_EventInfo, 3)
         SplitPath, FileName , OutFileName, OutDir, OutExtension, OutNameNoExt
	     IfExist, %A_ScriptDir%\%OutNameNoExt%.jpg
	     {
	    	image=%A_ScriptDir%\%OutNameNoExt%.jpg
	     }
	     IfExist, %A_ScriptDir%\%OutNameNoExt%.png
	     {
	     	image=%A_ScriptDir%\%OutNameNoExt%.png
	     }
	     IfExist, %A_ScriptDir%\%OutNameNoExt%_640.jpg
	     {
	     	image=%A_ScriptDir%\%OutNameNoExt%_640.jpg
	     }
         IfExist, %A_ScriptDir%\%OutNameNoExt%_medium.jpg
         {
            image=%A_ScriptDir%\%OutNameNoExt%_medium.jpg
         }
         IfExist, %A_ScriptDir%\%OutNameNoExt%_0.jpg
         {
            image=%A_ScriptDir%\%OutNameNoExt%_0.jpg
         }
         IfExist, %A_ScriptDir%\%OutNameNoExt%_4.jpg
         {
            image=%A_ScriptDir%\%OutNameNoExt%_4.jpg
         }

        ;msgbox, %A_ScriptDir%\%OutNameNoExt%`n%image%

         if (image != "") {
             SplashImageGUI(image, "Center", "Center", 1500, true)
         }
         image := ""
    }
Return

GuiClose:
	Gui, Hide
return

GuiDropFiles:
	GuiControl,, Path, %a_guievent%
Return

FromClipBoard:
    Gui, Submit, NoHide
    if (listMode = 1) {
        ;if (InStr(Path,"http"))
        Loop, parse, clipboard, `n, `r
        {
            prepareLinkAndDownload(A_LoopField, VideoFormat, CheckThumbnails, CheckGetQualityList)
            sleep, 100
        }
    } else {
        GuiControl,, Path, %clipboard%
        Gui, Submit, NoHide
        prepareLinkAndDownload(Path, VideoFormat, CheckThumbnails, CheckGetQualityList)
	}
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
; CHECKER - hide or not yt-dl win AND show with pause (new bat file)
; Update downloader - Done
; templates
; --config-location A_ScriptDir
; history in the table = history mode
; check before load by history (option)
; queue for myltyloads
; custom converts
; custom file work with some apps
; view downloads folders items (update list)
; add folder for download for eny item in the schedules
; SHOW "NOW DOWNLOAD..."
; MULTYLOADER
; SHOW TITLE ON LOAD PROCESS
; MORE PARAMS
; -o "/home/user/videos/%(title)s-%(id)s.%(ext)s"
; https://github.com/ytdl-org/youtube-dl/blob/master/README.md#options
; =============== Changes
; v 2.5 check links and dload from other sites (not only youtube)
; v 2.7 = add reload to tray and add to list *.mp4, *.mkv, *.mka, *.webm, *.weba, *.mp3
; v 2.8 Remove color rows (func LV_ColorChange) - it is not work
; v 3.0.34 move menu in "system submenu", add update douwloader func
; v 3.0.35 add formates (m4a), add image templates for move, some fix
; v 3.0.36 ctrl+shift+R hot key for reload
; v 3.1.01 add schedules
; v 3.1.01 3.1.03 add support for webp images and set preview to win (remove splashimage)