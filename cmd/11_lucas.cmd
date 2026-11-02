@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Lucas.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="2" (
  echo FAIL lucas fixture 1: expected 2, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1
if not "!REPLY!"=="1" (
  echo FAIL lucas fixture 2: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 5
if not "!REPLY!"=="11" (
  echo FAIL lucas fixture 3: expected 11, got !REPLY! 1>&2
  exit /b 1
)
call :compute 10
if not "!REPLY!"=="123" (
  echo FAIL lucas fixture 4: expected 123, got !REPLY! 1>&2
  exit /b 1
)
echo lucas: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "v_previous=2" >nul
set /a "v_current=1" >nul
set /a "v_index=0" >nul
:branch_1
set /a "condition_left=v_index" >nul
set /a "condition_right=v_n" >nul
if !condition_left! geq !condition_right! goto :branch_2
set /a "v_following=(v_previous + v_current)" >nul
set /a "v_previous=v_current" >nul
set /a "v_current=v_following" >nul
set /a "v_index=(v_index + 1)" >nul
goto :branch_1
:branch_2
set /a "computed=v_previous" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
