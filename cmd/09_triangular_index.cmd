@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Triangular index.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="0" (
  echo FAIL triangular_index fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1
if not "!REPLY!"=="1" (
  echo FAIL triangular_index fixture 2: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 15
if not "!REPLY!"=="5" (
  echo FAIL triangular_index fixture 3: expected 5, got !REPLY! 1>&2
  exit /b 1
)
call :compute 14
if not "!REPLY!"=="-1" (
  echo FAIL triangular_index fixture 4: expected -1, got !REPLY! 1>&2
  exit /b 1
)
echo triangular_index: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "v_total=0" >nul
set /a "v_index=0" >nul
:branch_1
set /a "condition_left=v_total" >nul
set /a "condition_right=v_n" >nul
if !condition_left! geq !condition_right! goto :branch_2
set /a "v_index=(v_index + 1)" >nul
set /a "v_total=(v_total + v_index)" >nul
goto :branch_1
:branch_2
set /a "condition_left=v_total" >nul
set /a "condition_right=v_n" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "computed=v_index" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_4
:branch_3
:branch_4
set /a "computed=(-1)" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
