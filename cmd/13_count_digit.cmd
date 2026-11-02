@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Count digit.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0 0
if not "!REPLY!"=="1" (
  echo FAIL count_digit fixture 1: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 0 1
if not "!REPLY!"=="0" (
  echo FAIL count_digit fixture 2: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1001 0
if not "!REPLY!"=="2" (
  echo FAIL count_digit fixture 3: expected 2, got !REPLY! 1>&2
  exit /b 1
)
call :compute 777 7
if not "!REPLY!"=="3" (
  echo FAIL count_digit fixture 4: expected 3, got !REPLY! 1>&2
  exit /b 1
)
echo count_digit: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set "v_target=%~2"
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_1
set /a "condition_left=v_target" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_3
set /a "computed=1" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_4
:branch_3
:branch_4
set /a "computed=0" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_2
:branch_1
:branch_2
set /a "v_count=0" >nul
:branch_5
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! leq !condition_right! goto :branch_6
set /a "condition_left=(v_n %% 10)" >nul
set /a "condition_right=v_target" >nul
if !condition_left! neq !condition_right! goto :branch_7
set /a "v_count=(v_count + 1)" >nul
goto :branch_8
:branch_7
:branch_8
set /a "v_n=(v_n / 10)" >nul
goto :branch_5
:branch_6
set /a "computed=v_count" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
