@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem Windows cmd.exe, local-drive working directory; ASCII fixture contents.
rem cmd /d /v:off /c literal_expansion.cmd
rem CALL reparses its argument text: pass paths through variables, not CALL args.
rem Delayed expansion is disabled whenever filenames containing bangs are read.
rem Only this newly created fixture directory and its exact files are removed.
set "LEAF=cmd-literal-%RANDOM%-%RANDOM%"
set "ROOT=%CD%\%LEAF%"
if exist "%ROOT%" exit /b 1
md "%ROOT%"
if errorlevel 1 exit /b 1
set "lit=EXPANDED_SENTINEL"
set "NAME1=bang !lit! percent %%PATH%% [data].txt"
set "COUNT=0"
set "SAW_LITERAL=0"
set "SAW_PLAIN=0"
set "FAILED=0"
>"%ROOT%\%NAME1%" echo alpha
if errorlevel 1 goto fail
>"%ROOT%\plain.txt" echo beta
if errorlevel 1 goto fail
>"%ROOT%\skip.tmp" echo excluded
if errorlevel 1 goto fail
for %%F in ("%ROOT%\*.txt") do (
  set "ITEM=%%~fF"
  rem No data on this CALL line means percent signs in ITEM are not reparsed.
  call :inspect
  if errorlevel 1 goto fail
)
if not "%COUNT%"=="2" goto fail
if not "%SAW_LITERAL%"=="1" goto fail
if not "%SAW_PLAIN%"=="1" goto fail
call :numeric_scope
if errorlevel 1 goto fail
rem ENDLOCAL in numeric_scope must restore literal-bang handling here.
if not exist "%ROOT%\%NAME1%" goto fail
set "ITEM=%ROOT%\missing.txt"
call :inspect
rem This is a fresh parse line, outside the FOR block: capture the actual status.
set "RC=%ERRORLEVEL%"
if not "%RC%"=="7" goto fail
>"%ROOT%\%NAME1%" echo corrupt
set "ITEM=%ROOT%\%NAME1%"
call :inspect
set "RC=%ERRORLEVEL%"
if not "%RC%"=="8" goto fail
if not "%COUNT%"=="2" goto fail
rem Guard unmatched wildcard results explicitly rather than treating a pattern
rem string as an existing file. This remains zero without any .absent fixtures.
set "EMPTY_COUNT=0"
for %%F in ("%ROOT%\*.absent") do if exist "%%~fF" set /a "EMPTY_COUNT+=1" >nul
if not "%EMPTY_COUNT%"=="0" goto fail
goto cleanup

:inspect
if not exist "%ITEM%" exit /b 7
set "CONTENT="
set /p "CONTENT=" < "%ITEM%"
if "%ITEM%"=="%ROOT%\%NAME1%" (
  if not "%CONTENT%"=="alpha" exit /b 8
  set "SAW_LITERAL=1"
) else if "%ITEM%"=="%ROOT%\plain.txt" (
  if not "%CONTENT%"=="beta" exit /b 8
  set "SAW_PLAIN=1"
) else (
  exit /b 8
)
set /a "COUNT+=1" >nul
exit /b 0

:numeric_scope
setlocal EnableDelayedExpansion
set "SUM=0"
for /l %%I in (1,1,4) do set /a "SUM+=%%I" >nul
if not "!SUM!"=="10" (
  endlocal
  exit /b 1
)
endlocal
exit /b 0

:fail
set "FAILED=1"
echo CMD literal expansion fixture failed 1>&2
:cleanup
for %%D in ("%ROOT%") do set "RESOLVED=%%~fD"
if not "%RESOLVED%"=="%CD%\%LEAF%" exit /b 1
if exist "%ROOT%\%NAME1%" del /q "%ROOT%\%NAME1%"
if exist "%ROOT%\plain.txt" del /q "%ROOT%\plain.txt"
if exist "%ROOT%\skip.tmp" del /q "%ROOT%\skip.tmp"
rem Nonrecursive RD fails if an unexpected file remains; do not delete broadly.
rd "%ROOT%"
if exist "%ROOT%" set "FAILED=1"
if "%FAILED%"=="0" echo CMD: literal percent/bang paths, scoped expansion, fresh status and empty wildcard checks passed
endlocal & exit /b %FAILED%
