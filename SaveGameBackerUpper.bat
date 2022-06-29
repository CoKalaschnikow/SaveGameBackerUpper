@echo off
TITLE SaveGameBackerUpper

goto check_Permissions
if %errorLevel% == 0 goto warning

::-----Setup-------------------------------------
::-----Check if program has ran before-----------

:begin


if not exist version.txt goto setup
if exist version.txt goto mover

::-----

:mover
     set /p FirstRun=<version.txt

     if %FirstRun%==1.0 (goto ChooseOption) else (goto setup)
::------------------------------------------------ 


::-----Setup--------------------------------------

:setup
     cls
	echo "Setup"
setlocal

set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Select where Backups will be stored',0,0).self.path""

for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "folder=%%I"

setlocal enabledelayedexpansion
endlocal
echo %folder%> config.cfg
echo 1.0> version.txt
set /p y=<version.txt 
if not exist %folder%\GameList.bat copy NUL %folder%\GameList.bat

SCHTASKS /CREATE /SC DAILY /TN "Daily-SaveGame-Backups" /TR "%folder%\GameList.bat" /ST 16:00 /f  

::------------------------------------------------


::-----PermCheck----------------------------------

:check_Permissions
echo Administrative permissions required. Detecting permissions...

net session >nul 2>&1
if %errorLevel% == 0 (
    cls
    echo Do not run random things as administrator! Please run this without administrator rights.
    TIMEOUT 10
    exit
) else (
     cls
     goto begin
)

::------------------------------------------------

 
::-----SelectionMenu------------------------------

:ChooseOption:
CLS
call :echo-align center "***************************************"
call :echo-align center "SaveGameBackerUpper by Costa"
call :echo-align center "***************************************"
ECHO 1.Backup now
ECHO 2.Add a Game to the List
ECHO 3.Delete GameList(No Game will be backed up anymore)
ECHO 4.Reset to default(Will not delete SaveGames)
ECHO 5.Move Backup Folder
ECHO 6.Delete a Game from the List
ECHO 7.Exit
::ECHO 8.Debug
ECHO.

CHOICE /C 12345678 /N /M "Enter your choice:"

IF ERRORLEVEL 8 GOTO Debug
IF ERRORLEVEL 7 GOTO Shutdown
IF ERRORLEVEL 6 GOTO RemoveSingle
IF ERRORLEVEL 5 GOTO MoveBackup
IF ERRORLEVEL 4 GOTO DeleteAll
IF ERRORLEVEL 3 GOTO DeleteSave
IF ERRORLEVEL 2 GOTO AddingGame
IF ERRORLEVEL 1 GOTO InstantBackup

::------------------------------------------------


::-----CallBackup---------------------------------

:InstantBackup  
set /p BackupFolder=<config.cfg
cd %BackupFolder%
call GameList.bat
cd..
goto ChooseOption

::------------------------------------------------


::-----AddGame------------------------------------

:AddingGame
     cls
     set /p BackupFolder=<config.cfg
     if not exist %BackupFolder%\ mkdir %BackupFolder%\
     if not exist %BackupFolder%\GameList.bat copy NUL %BackupFolder%\GameList.bat
     cls
     echo "Input the Name of the Game"
     set /p GameName=" "
     echo ::%GameName%::>> %BackupFolder%\GameList.bat
     set GameName=%GameName: =%
setlocal

set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Select Location of the Save Games',0,0).self.path""

for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "GameLocation=%%I"

setlocal enabledelayedexpansion
endlocal
echo robocopy %GameLocation% %BackupFolder%\%GameName%>> %BackupFolder%\GameList.bat /E
goto ChooseOption

::------------------------------------------------


::-----DeleteSave---------------------------------

:DeleteSave
SET /P AREYOUSURE=Do you want to delete the Game List? (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO ChooseOption
set /p BackupFolder=<config.cfg
cd %BackupFolder%
del GameList.bat
CLS
echo Game List has been deleted.
timeout 2 /nobreak > NUL
cd..
goto ChooseOption

::------------------------------------------------


::-----FactoryReset-------------------------------

:DeleteAll
CLS
:PROMPT
SET /P AREYOUSURE=Do you want to completly reset the program? (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO ChooseOption
set /p BackupFolder=<config.cfg
del config.cfg
del version.txt
rmdir %BackupFolder% /s /q
SCHTASKS /DELETE /TN "Daily-SaveGame-Backups" /f
goto Shutdown

::------------------------------------------------


::-----MoveBackup---------------------------------

:MoveBackup
set /p BackupFolder=<config.cfg
setlocal

set "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Select new Location of the Backup Folder',0,0).self.path""

for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "NewBackup=%%I"
set NewBackup=%NewBackup: =%
echo %NewBackup%
del config.cfg
echo %NewBackup%> config.cfg
robocopy %BackupFolder% %NewBackup% /e /move
SCHTASKS /DELETE /TN "Daily-SaveGame-Backups" /f
SCHTASKS /CREATE /SC DAILY /TN "Daily-SaveGame-Backups" /TR "%NewBackup%\GameList.bat" /ST 16:00
cd %NewBackup%
    setlocal enableextensions disabledelayedexpansion

    set "search=%BackupFolder%"
    set "replace=%NewBackup%"

    set "textFile=GameList.bat"

    for /f "delims=" %%i in ('type "%textFile%" ^& break ^> "%textFile%" ') do (
        set "line=%%i"
        setlocal enabledelayedexpansion
        >>"%textFile%" echo(!line:%search%=%replace%!
        endlocal
    )
cd..
goto ChooseOption

::------------------------------------------------


::-----RemoveSingle-------------------------------

:RemoveSingle
CLS
set /p BackupFolder=<config.cfg
cd %BackupFolder%
echo Delete the Line "::GAMENAME::" and the Line beneath it.
start /WAIT notepad "GameList.bat"
cd..
goto ChooseOption

::------------------------------------------------


::-----Shutdown/Debug-----------------------------

:Shutdown
exit

:Debug
set /p BackupFolder=<config.cfg
echo ------------------------------------------------
echo Debug Menu
echo Current Backup Folder
echo %BackupFolder%
echo .
echo .
echo .
echo Program Files
dir /s /b /o:gn
pause
goto ChooseOption

::------------------------------------------------


::-----AlignText---------------------------------

:echo-align <align> <text>
	setlocal EnableDelayedExpansion
	(set^ tmp=%~2)
	if defined tmp (
		set "len=1"
		for %%p in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
			if "!tmp:~%%p,1!" neq "" (
				set /a "len+=%%p"
				set "tmp=!tmp:~%%p!"
			)
		)
	) else (
		set len=0
	)

	for /f "skip=4 tokens=2 delims=:" %%i in ('mode con') do (
		set /a cols=%%i
		goto loop_end
	)
	:loop_end

	if /i "%1" equ "center" (
		set /a offsetnum=^(%cols% / 2^) - ^(%len% / 2^)
		set "offset="
		for /l %%i in (1 1 !offsetnum!) do set "offset=!offset! "
	) else if /i "%1" equ "right" (
		set /a offsetnum=^(%cols% - %len%^)
		set "offset="
		for /l %%i in (1 1 !offsetnum!) do set "offset=!offset! "
	)

	echo %offset%%~2
	endlocal

	exit /b

::------------------------------------------------
     

pause
