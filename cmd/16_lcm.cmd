@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Lcm.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: a,b >= 0; zero arguments produce 0.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 12 18
if not "!REPLY!"=="36" (
  echo FAIL lcm fixture 1: expected 36, got !REPLY! 1>&2
  exit /b 1
)
call :compute 0 7
if not "!REPLY!"=="0" (
  echo FAIL lcm fixture 2: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 7 0
if not "!REPLY!"=="0" (
  echo FAIL lcm fixture 3: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 5 7
if not "!REPLY!"=="35" (
  echo FAIL lcm fixture 4: expected 35, got !REPLY! 1>&2
  exit /b 1
)
call :compute 9 9
if not "!REPLY!"=="9" (
  echo FAIL lcm fixture 5: expected 9, got !REPLY! 1>&2
  exit /b 1
)
echo lcm: 5 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_a=%~1"
set "v_b=%~2"
set /a "condition_left=v_a" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_1
set /a "computed=0" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_2
:branch_1
:branch_2
set /a "condition_left=v_b" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "computed=0" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_4
:branch_3
:branch_4
set /a "v_x=v_a" >nul
set /a "v_y=v_b" >nul
:branch_5
set /a "condition_left=v_y" >nul
set /a "condition_right=0" >nul
if !condition_left! equ !condition_right! goto :branch_6
set /a "v_remainder=(v_x %% v_y)" >nul
set /a "v_x=v_y" >nul
set /a "v_y=v_remainder" >nul
goto :branch_5
:branch_6
set /a "computed=((v_a / v_x) * v_b)" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
