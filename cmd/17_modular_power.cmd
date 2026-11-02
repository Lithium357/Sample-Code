@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Modular power.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 2 10 1000
if not "!REPLY!"=="24" (
  echo FAIL modular_power fixture 1: expected 24, got !REPLY! 1>&2
  exit /b 1
)
call :compute 7 0 1
if not "!REPLY!"=="0" (
  echo FAIL modular_power fixture 2: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 3 4 7
if not "!REPLY!"=="4" (
  echo FAIL modular_power fixture 3: expected 4, got !REPLY! 1>&2
  exit /b 1
)
call :compute 5 3 13
if not "!REPLY!"=="8" (
  echo FAIL modular_power fixture 4: expected 8, got !REPLY! 1>&2
  exit /b 1
)
echo modular_power: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_base=%~1"
set "v_exponent=%~2"
set "v_modulus=%~3"
set /a "v_result=(1 %% v_modulus)" >nul
set /a "v_base=(v_base %% v_modulus)" >nul
:branch_1
set /a "condition_left=v_exponent" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_2
set /a "condition_left=(v_exponent %% 2)" >nul
set /a "condition_right=1" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "v_result=((v_result * v_base) %% v_modulus)" >nul
goto :branch_4
:branch_3
:branch_4
set /a "v_exponent=(v_exponent / 2)" >nul
set /a "v_base=((v_base * v_base) %% v_modulus)" >nul
goto :branch_1
:branch_2
set /a "computed=v_result" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
