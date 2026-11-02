@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Is happy.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 1
if not "!REPLY!"=="1" (
  echo FAIL is_happy fixture 1: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 19
if not "!REPLY!"=="1" (
  echo FAIL is_happy fixture 2: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 2
if not "!REPLY!"=="0" (
  echo FAIL is_happy fixture 3: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 0
if not "!REPLY!"=="0" (
  echo FAIL is_happy fixture 4: expected 0, got !REPLY! 1>&2
  exit /b 1
)
echo is_happy: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "v_steps=0" >nul
:branch_1
set /a "condition_left=v_steps" >nul
set /a "condition_right=100" >nul
if !condition_left! geq !condition_right! goto :branch_2
set /a "condition_left=v_n" >nul
set /a "condition_right=1" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "computed=1" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_4
:branch_3
:branch_4
set /a "v_total=0" >nul
:branch_5
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_6
set /a "v_digit=(v_n %% 10)" >nul
set /a "v_total=(v_total + (v_digit * v_digit))" >nul
set /a "v_n=(v_n / 10)" >nul
goto :branch_5
:branch_6
set /a "v_n=v_total" >nul
set /a "v_steps=(v_steps + 1)" >nul
goto :branch_1
:branch_2
set /a "computed=0" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
