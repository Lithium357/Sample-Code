@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Integer log.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: n >= 1; base >= 2; returns floor(log_base(n)).
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 1 2
if not "!REPLY!"=="0" (
  echo FAIL integer_log fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 8 2
if not "!REPLY!"=="3" (
  echo FAIL integer_log fixture 2: expected 3, got !REPLY! 1>&2
  exit /b 1
)
call :compute 99 10
if not "!REPLY!"=="1" (
  echo FAIL integer_log fixture 3: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 100 10
if not "!REPLY!"=="2" (
  echo FAIL integer_log fixture 4: expected 2, got !REPLY! 1>&2
  exit /b 1
)
echo integer_log: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set "v_base=%~2"
set /a "v_exponent=0" >nul
:branch_1
set /a "condition_left=v_n" >nul
set /a "condition_right=v_base" >nul
if !condition_left! lss !condition_right! goto :branch_2
set /a "v_n=(v_n / v_base)" >nul
set /a "v_exponent=(v_exponent + 1)" >nul
goto :branch_1
:branch_2
set /a "computed=v_exponent" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
