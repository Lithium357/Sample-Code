@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Digit sum.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="0" (
  echo FAIL digit_sum fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 12345
if not "!REPLY!"=="15" (
  echo FAIL digit_sum fixture 2: expected 15, got !REPLY! 1>&2
  exit /b 1
)
call :compute 909
if not "!REPLY!"=="18" (
  echo FAIL digit_sum fixture 3: expected 18, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1000
if not "!REPLY!"=="1" (
  echo FAIL digit_sum fixture 4: expected 1, got !REPLY! 1>&2
  exit /b 1
)
echo digit_sum: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "v_total=0" >nul
:branch_1
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_2
set /a "v_total=(v_total + (v_n %% 10))" >nul
set /a "v_n=(v_n / 10)" >nul
goto :branch_1
:branch_2
set /a "computed=v_total" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
