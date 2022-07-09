@echo off
::-----PermCheck----------------------------------

:check_Permissions
echo Detecting permissions...

net session >nul 2>&1
if %errorLevel% == 0 (
    cls
    goto Prompt
) else (
     cls
     echo Please run as administrator!
     pause
     exit
)

::------------------------------------------------

setlocal
:PROMPT
SET /P AREYOUSURE=Do you want to add SaveGameBackerUpper to the Context Menu? (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

:Context
set mypath=%~dp0

REG ADD HKCR\Directory\Background\shell\SaveGamerBackerUpper\command

REG ADD HKCR\Directory\Background\shell\SaveGamerBackerUpper\command /ve /d %mypath%SaveGameBackerUpper.bat /f
cls
echo SaveGameBackerUpper has been added to the Context Menu!


:END
endlocal

pause