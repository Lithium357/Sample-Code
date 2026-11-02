@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Power.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0 0
if not "!REPLY!"=="1" (
  echo FAIL power fixture 1: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 2 10
if not "!REPLY!"=="1024" (
  echo FAIL power fixture 2: expected 1024, got !REPLY! 1>&2
  exit /b 1
)
call :compute 3 5
if not "!REPLY!"=="243" (
  echo FAIL power fixture 3: expected 243, got !REPLY! 1>&2
  exit /b 1
)
call :compute 7 1
if not "!REPLY!"=="7" (
  echo FAIL power fixture 4: expected 7, got !REPLY! 1>&2
  exit /b 1
)
echo power: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_base=%~1"
set "v_exponent=%~2"
set /a "v_result=1" >nul
:branch_1
set /a "condition_left=v_exponent" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_2
set /a "condition_left=(v_exponent %% 2)" >nul
set /a "condition_right=1" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "v_result=(v_result * v_base)" >nul
goto :branch_4
:branch_3
:branch_4
set /a "v_exponent=(v_exponent / 2)" >nul
set /a "condition_left=v_exponent" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_5
set /a "v_base=(v_base * v_base)" >nul
goto :branch_6
:branch_5
:branch_6
goto :branch_1
:branch_2
set /a "computed=v_result" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
