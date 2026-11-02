@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Digital root.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="0" (
  echo FAIL digital_root fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 999
if not "!REPLY!"=="9" (
  echo FAIL digital_root fixture 2: expected 9, got !REPLY! 1>&2
  exit /b 1
)
call :compute 12345
if not "!REPLY!"=="6" (
  echo FAIL digital_root fixture 3: expected 6, got !REPLY! 1>&2
  exit /b 1
)
call :compute 8
if not "!REPLY!"=="8" (
  echo FAIL digital_root fixture 4: expected 8, got !REPLY! 1>&2
  exit /b 1
)
echo digital_root: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
:branch_1
set /a "condition_left=v_n" >nul
set /a "condition_right=10" >nul
if !condition_left! lss !condition_right! goto :branch_2
set /a "v_total=0" >nul
:branch_3
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_4
set /a "v_total=(v_total + (v_n %% 10))" >nul
set /a "v_n=(v_n / 10)" >nul
goto :branch_3
:branch_4
set /a "v_n=v_total" >nul
goto :branch_1
:branch_2
set /a "computed=v_n" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
