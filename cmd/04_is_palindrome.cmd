@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Is palindrome.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="1" (
  echo FAIL is_palindrome fixture 1: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1221
if not "!REPLY!"=="1" (
  echo FAIL is_palindrome fixture 2: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 123
if not "!REPLY!"=="0" (
  echo FAIL is_palindrome fixture 3: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 101
if not "!REPLY!"=="1" (
  echo FAIL is_palindrome fixture 4: expected 1, got !REPLY! 1>&2
  exit /b 1
)
echo is_palindrome: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "v_original=v_n" >nul
set /a "v_reversed_value=0" >nul
:branch_1
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_2
set /a "v_reversed_value=((v_reversed_value * 10) + (v_n %% 10))" >nul
set /a "v_n=(v_n / 10)" >nul
goto :branch_1
:branch_2
set /a "condition_left=v_reversed_value" >nul
set /a "condition_right=v_original" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "computed=1" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_4
:branch_3
:branch_4
set /a "computed=0" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
