@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Ceil div.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: numerator >= 0; denominator > 0.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0 3
if not "!REPLY!"=="0" (
  echo FAIL ceil_div fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 10 3
if not "!REPLY!"=="4" (
  echo FAIL ceil_div fixture 2: expected 4, got !REPLY! 1>&2
  exit /b 1
)
call :compute 12 3
if not "!REPLY!"=="4" (
  echo FAIL ceil_div fixture 3: expected 4, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1 9
if not "!REPLY!"=="1" (
  echo FAIL ceil_div fixture 4: expected 1, got !REPLY! 1>&2
  exit /b 1
)
echo ceil_div: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_numerator=%~1"
set "v_denominator=%~2"
set /a "v_quotient=(v_numerator / v_denominator)" >nul
set /a "condition_left=(v_numerator %% v_denominator)" >nul
set /a "condition_right=0" >nul
if !condition_left! equ !condition_right! goto :branch_1
set /a "v_quotient=(v_quotient + 1)" >nul
goto :branch_2
:branch_1
:branch_2
set /a "computed=v_quotient" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
