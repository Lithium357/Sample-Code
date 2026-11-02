@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Gcd.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: a,b >= 0; gcd(0,0) is defined as 0.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 48 18
if not "!REPLY!"=="6" (
  echo FAIL gcd fixture 1: expected 6, got !REPLY! 1>&2
  exit /b 1
)
call :compute 0 7
if not "!REPLY!"=="7" (
  echo FAIL gcd fixture 2: expected 7, got !REPLY! 1>&2
  exit /b 1
)
call :compute 7 0
if not "!REPLY!"=="7" (
  echo FAIL gcd fixture 3: expected 7, got !REPLY! 1>&2
  exit /b 1
)
call :compute 0 0
if not "!REPLY!"=="0" (
  echo FAIL gcd fixture 4: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 35 64
if not "!REPLY!"=="1" (
  echo FAIL gcd fixture 5: expected 1, got !REPLY! 1>&2
  exit /b 1
)
echo gcd: 5 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_a=%~1"
set "v_b=%~2"
:branch_1
set /a "condition_left=v_b" >nul
set /a "condition_right=0" >nul
if !condition_left! equ !condition_right! goto :branch_2
set /a "v_remainder=(v_a %% v_b)" >nul
set /a "v_a=v_b" >nul
set /a "v_b=v_remainder" >nul
goto :branch_1
:branch_2
set /a "computed=v_a" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
