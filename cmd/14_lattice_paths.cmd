@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Lattice paths.
rem Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic
rem Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.

call :compute 0 0
if not "!REPLY!"=="1" (
  echo FAIL lattice_paths fixture 1: expected 1, got !REPLY! 1>&2
  exit /b 1
)
call :compute 2 2
if not "!REPLY!"=="6" (
  echo FAIL lattice_paths fixture 2: expected 6, got !REPLY! 1>&2
  exit /b 1
)
call :compute 3 2
if not "!REPLY!"=="10" (
  echo FAIL lattice_paths fixture 3: expected 10, got !REPLY! 1>&2
  exit /b 1
)
call :compute 4 4
if not "!REPLY!"=="70" (
  echo FAIL lattice_paths fixture 4: expected 70, got !REPLY! 1>&2
  exit /b 1
)
echo lattice_paths: 4 fixtures passed
exit /b 0

:compute
setlocal EnableDelayedExpansion
set "v_width=%~1"
set "v_height=%~2"
set /a "v_steps=(v_width + v_height)" >nul
set /a "v_result=1" >nul
set /a "v_index=1" >nul
:branch_1
set /a "condition_left=v_index" >nul
set /a "condition_right=v_width" >nul
if !condition_left! gtr !condition_right! goto :branch_2
set /a "v_result=((v_result * ((v_steps - v_width) + v_index)) / v_index)" >nul
set /a "v_index=(v_index + 1)" >nul
goto :branch_1
:branch_2
set /a "computed=v_result" >nul
endlocal & set "REPLY=%computed%" & exit /b 0
