@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Levenshtein distance with insert/delete/substitute and recursive oracle.
rem cmd /d /c edit_distance.cmd
rem Demonstration alphabet: lowercase ASCII letters. Strings <= 30 characters.
rem Delayed expansion makes this interface unsuitable for arbitrary shell text.
call :case kitten sitting 3
if errorlevel 1 exit /b 1
call :case saturday sunday 3
if errorlevel 1 exit /b 1
call :case abc abc 0
if errorlevel 1 exit /b 1
call :case "" abc 3
if errorlevel 1 exit /b 1
call :case abc "" 3
if errorlevel 1 exit /b 1
call :case "" "" 0
if errorlevel 1 exit /b 1
rem Exhaustive small-language checks against direct recursive search.
for %%A in ("" "a" "b" "aa" "ab" "ba" "bb") do (
    for %%B in ("" "a" "b" "aa" "ab" "ba" "bb") do (
        set "a=%%~A"
        set "b=%%~B"
        call :distance
        set "answer=!result!"
        call :recursive "%%~A" "%%~B"
        if not "!answer!"=="!result!" (
            echo Recursive oracle mismatch 1>&2
            exit /b 1
        )
    )
)
echo Edit distance: known examples, empty strings and 49 recursive-oracle comparisons passed
exit /b 0

:case
set "a=%~1"
set "b=%~2"
call :distance
if not "!result!"=="%~3" exit /b 1
exit /b 0

:length
setlocal
set "text=%~1"
set "size=0"
:length_loop
if not defined text goto :length_done
set "text=!text:~1!"
set /a "size=size+1" >nul
goto :length_loop
:length_done
endlocal & set "result=%size%" & exit /b 0

:distance
call :length "!a!"
set "n=!result!"
call :length "!b!"
set "m=!result!"
for /l %%I in (0,1,!n!) do set "dp[%%I,0]=%%I"
for /l %%J in (0,1,!m!) do set "dp[0,%%J]=%%J"
for /l %%I in (1,1,!n!) do (
    set /a "pi=%%I-1" >nul
    for /l %%J in (1,1,!m!) do (
        set /a "pj=%%J-1" >nul
        for %%P in (!pi!) do for %%Q in (!pj!) do (
            set "ac=!a:~%%P,1!"
            set "bc=!b:~%%Q,1!"
            set "penalty=1"
            if "!ac!"=="!bc!" set "penalty=0"
            set /a "best=!dp[%%P,%%Q]!+penalty" >nul
            set /a "candidate=!dp[%%P,%%J]!+1" >nul
            if !candidate! lss !best! set "best=!candidate!"
            set /a "candidate=!dp[%%I,%%Q]!+1" >nul
            if !candidate! lss !best! set "best=!candidate!"
            set "dp[%%I,%%J]=!best!"
        )
    )
)
for %%N in (!n!) do for %%M in (!m!) do set "result=!dp[%%N,%%M]!"
exit /b 0

:recursive
setlocal EnableDelayedExpansion
set "x=%~1"
set "y=%~2"
if not defined x (
    call :length "!y!"
    goto :recursive_done
)
if not defined y (
    call :length "!x!"
    goto :recursive_done
)
if "!x:~0,1!"=="!y:~0,1!" (
    call :recursive "!x:~1!" "!y:~1!"
    goto :recursive_done
)
call :recursive "!x:~1!" "!y!"
set "best=!result!"
call :recursive "!x!" "!y:~1!"
if !result! lss !best! set "best=!result!"
call :recursive "!x:~1!" "!y:~1!"
if !result! lss !best! set "best=!result!"
set /a "result=best+1" >nul
:recursive_done
endlocal & set "result=%result%" & exit /b 0
