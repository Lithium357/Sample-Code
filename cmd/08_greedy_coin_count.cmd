@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Greedy coin count.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="0" (
  echo FAIL greedy_coin_count fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 30
if not "!REPLY!"=="2" (
  echo FAIL greedy_coin_count fixture 2: expected 2, got !REPLY! 1>&2
  exit /b 1
)
call :compute 41
if not "!REPLY!"=="4" (
  echo FAIL greedy_coin_count fixture 3: expected 4, got !REPLY! 1>&2
  exit /b 1
)
call :compute 99
if not "!REPLY!"=="9" (
  echo FAIL greedy_coin_count fixture 4: expected 9, got !REPLY! 1>&2
  exit /b 1
)
echo greedy_coin_count: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_amount=%~1"
set /a "v_count=(v_amount / 25)" >nul
set /a "v_amount=(v_amount %% 25)" >nul
set /a "v_count=(v_count + (v_amount / 10))" >nul
set /a "v_amount=(v_amount %% 10)" >nul
set /a "v_count=(v_count + (v_amount / 5))" >nul
set /a "v_amount=(v_amount %% 5)" >nul
set /a "computed=(v_count + v_amount)" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
