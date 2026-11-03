@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem Windows cmd.exe. Test-owned paths include spaces and literal exclamation.
rem Delayed expansion is disabled while handling those paths and file content.
set "owned=%TEMP%\morderca paths %RANDOM%-%RANDOM%"
if exist "%owned%" exit /b 10
mkdir "%owned%"
if errorlevel 1 exit /b 11
set "fixture=%owned%\bang! file.txt"
>"%fixture%" echo alpha
>>"%fixture%" echo beta
>>"%fixture%" echo.
>>"%fixture%" echo ;ignored comment
call :count_nonempty "%fixture%"
set "status=%ERRORLEVEL%"
if not "%status%"=="0" goto :failed
if not "%COUNT%"=="2" goto :failed
call :count_nonempty "%owned%\missing file.txt"
set "status=%ERRORLEVEL%"
if not "%status%"=="3" goto :failed
call :deliberate_failure
set "saved=%ERRORLEVEL%"
ver >nul
if not "%saved%"=="7" goto :failed
if errorlevel 1 goto :failed
del "%fixture%"
if exist "%fixture%" goto :failed
rmdir "%owned%"
if errorlevel 1 exit /b 12
echo Paths/status: quoted exclamation paths, subroutine results and captured ERRORLEVEL passed
exit /b 0
:failed
if exist "%fixture%" del "%fixture%"
rmdir "%owned%"
echo Fixture assertion failed 1>&2
exit /b 1
:count_nonempty
setlocal DisableDelayedExpansion
if not exist "%~1" exit /b 3
set "count=0"
rem FOR /F intentionally counts nonempty, non-comment records, not all lines.
for /f "usebackq delims=" %%L in ("%~1") do set /a "count+=1" >nul
endlocal & set "COUNT=%count%" & exit /b 0
:deliberate_failure
exit /b 7
