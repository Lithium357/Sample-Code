@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Trailing zero bits.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0
if not "!REPLY!"=="-1" (
  echo FAIL trailing_zero_bits fixture 1: expected -1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 1
if not "!REPLY!"=="0" (
  echo FAIL trailing_zero_bits fixture 2: expected 0, got !REPLY! 1>&2
  exit /b 1
)
call :compute 40
if not "!REPLY!"=="3" (
  echo FAIL trailing_zero_bits fixture 3: expected 3, got !REPLY! 1>&2
  exit /b 1
)
call :compute 64
if not "!REPLY!"=="6" (
  echo FAIL trailing_zero_bits fixture 4: expected 6, got !REPLY! 1>&2
  exit /b 1
)
echo trailing_zero_bits: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_n=%~1"
set /a "condition_left=v_n" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_1
set /a "computed=(-1)" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
goto :branch_2
:branch_1
:branch_2
set /a "v_count=0" >nul
:branch_3
set /a "condition_left=(v_n %% 2)" >nul
set /a "condition_right=0" >nul
if !condition_left! neq !condition_right! goto :branch_4
set /a "v_count=(v_count + 1)" >nul
set /a "v_n=(v_n / 2)" >nul
goto :branch_3
:branch_4
set /a "computed=v_count" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
