@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Discrete log.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 2 1 7
if not "!REPLY!"=="0" (
  echo FAIL discrete_log fixture 1: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 2 4 7
if not "!REPLY!"=="2" (
  echo FAIL discrete_log fixture 2: expected 2, got !REPLY! 1>&2
  exit /b 1
)
call :compute 2 3 7
if not "!REPLY!"=="-1" (
  echo FAIL discrete_log fixture 3: expected -1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 3 5 7
if not "!REPLY!"=="5" (
  echo FAIL discrete_log fixture 4: expected 5, got !REPLY! 1>&2
  exit /b 1
)
echo discrete_log: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_base=%~1"
set "v_target=%~2"
set "v_modulus=%~3"
set /a "v_value=(1 %% v_modulus)" >nul
set /a "v_exponent=0" >nul
:branch_1
set /a "condition_left=v_exponent" >nul
set /a "condition_right=v_modulus" >nul
if !condition_left! geq !condition_right! goto :branch_2
set /a "condition_left=v_value" >nul
set /a "condition_right=v_target" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "computed=v_exponent" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_4
:branch_3
:branch_4
set /a "v_value=((v_value * v_base) %% v_modulus)" >nul
set /a "v_exponent=(v_exponent + 1)" >nul
goto :branch_1
:branch_2
set /a "computed=(-1)" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
