@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Is perfect.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="0" (
  echo FAIL is_perfect fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1
if not "!REPLY!"=="0" (
  echo FAIL is_perfect fixture 2: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 6
if not "!REPLY!"=="1" (
  echo FAIL is_perfect fixture 3: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 28
if not "!REPLY!"=="1" (
  echo FAIL is_perfect fixture 4: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 12
if not "!REPLY!"=="0" (
  echo FAIL is_perfect fixture 5: expected 0, got !REPLY! 1>&2
  exit /b 1
)
echo is_perfect: 5 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "v_total=0" >nul
set /a "v_divisor=1" >nul
:branch_1
set /a "condition_left=v_divisor" >nul
set /a "condition_right=v_n" >nul
if !condition_left! geq !condition_right! goto :branch_2
set /a "condition_left=(v_n %% v_divisor)" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "v_total=(v_total + v_divisor)" >nul
goto :branch_4
:branch_3
:branch_4
set /a "v_divisor=(v_divisor + 1)" >nul
goto :branch_1
:branch_2
set /a "condition_left=v_total" >nul
set /a "condition_right=v_n" >nul
if !condition_left! neq !condition_right! goto :branch_5
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_7
set /a "computed=1" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_8
:branch_7
:branch_8
goto :branch_6
:branch_5
:branch_6
set /a "computed=0" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
