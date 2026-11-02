@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Totient.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: n >= 1.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 1
if not "!REPLY!"=="1" (
  echo FAIL totient fixture 1: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 9
if not "!REPLY!"=="6" (
  echo FAIL totient fixture 2: expected 6, got !REPLY! 1>&2
  exit /b 1
)
call :compute 12
if not "!REPLY!"=="4" (
  echo FAIL totient fixture 3: expected 4, got !REPLY! 1>&2
  exit /b 1
)
call :compute 97
if not "!REPLY!"=="96" (
  echo FAIL totient fixture 4: expected 96, got !REPLY! 1>&2
  exit /b 1
)
echo totient: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "v_result=v_n" >nul
set /a "v_prime=2" >nul
set /a "v_remaining=v_n" >nul
:branch_1
set /a "condition_left=v_prime" >nul
set /a "condition_right=(v_remaining / v_prime)" >nul
if !condition_left! gtr !condition_right! goto :branch_2
set /a "condition_left=(v_remaining %% v_prime)" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_3
:branch_5
set /a "condition_left=(v_remaining %% v_prime)" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_6
set /a "v_remaining=(v_remaining / v_prime)" >nul
goto :branch_5
:branch_6
set /a "v_result=(v_result - (v_result / v_prime))" >nul
goto :branch_4
:branch_3
:branch_4
set /a "v_prime=(v_prime + 1)" >nul
goto :branch_1
:branch_2
set /a "condition_left=v_remaining" >nul
set /a "condition_right=1" >nul
if !condition_left! leq !condition_right! goto :branch_7
set /a "v_result=(v_result - (v_result / v_remaining))" >nul
goto :branch_8
:branch_7
:branch_8
set /a "computed=v_result" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
