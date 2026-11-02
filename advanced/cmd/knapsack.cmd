@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Windows CMD 0/1 knapsack, full dynamic-programming table and reconstruction.
rem cmd /d /c knapsack.cmd
rem No external utilities. n <= 20, capacity <= 100; small nonnegative values.
rem A brute-force subset oracle checks every capacity from 0 through 20.
set "n=8"
set "w[1]=2"
set "v[1]=3"
set "w[2]=3"
set "v[2]=4"
set "w[3]=4"
set "v[3]=8"
set "w[4]=5"
set "v[4]=8"
set "w[5]=1"
set "v[5]=2"
set "w[6]=6"
set "v[6]=11"
set "w[7]=2"
set "v[7]=5"
set "w[8]=7"
set "v[8]=13"
for /l %%C in (0,1,20) do (
    set "capacity=%%C"
    call :solve
    call :oracle
    if not "!answer!"=="!oracle!" (
        echo DP/oracle mismatch at capacity %%C 1>&2
        exit /b 1
    )
    call :verify_selection
    if errorlevel 1 exit /b 1
)
rem An empty item list is a valid problem with value zero.
set "n=0"
set "capacity=10"
call :solve
if not "!answer!"=="0" exit /b 1
echo Knapsack: 21 brute-force comparisons, reconstruction and empty input passed
exit /b 0

:solve
rem dp[i,c] uses only items 1..i. Keeping rows separate prevents accidentally
rem solving unbounded knapsack by taking the same item repeatedly.
for /l %%C in (0,1,!capacity!) do set "dp[0,%%C]=0"
for /l %%I in (1,1,!n!) do (
    set /a "previous=%%I-1" >nul
    for %%P in (!previous!) do (
        for /l %%C in (0,1,!capacity!) do (
            set "best=!dp[%%P,%%C]!"
            if !w[%%I]! leq %%C (
                set /a "rest=%%C-!w[%%I]!" >nul
                for %%R in (!rest!) do set /a "candidate=!dp[%%P,%%R]!+!v[%%I]!" >nul
                if !candidate! gtr !best! set "best=!candidate!"
            )
            set "dp[%%I,%%C]=!best!"
        )
    )
)
for %%N in (!n!) do for %%C in (!capacity!) do set "answer=!dp[%%N,%%C]!"
set "selected=0"
set "remaining=!capacity!"
for /l %%I in (!n!,-1,1) do (
    set /a "previous=%%I-1" >nul
    for %%P in (!previous!) do for %%C in (!remaining!) do (
        if not "!dp[%%I,%%C]!"=="!dp[%%P,%%C]!" (
            set /a "selected=selected | (1 << (%%I-1))" >nul
            set /a "remaining=remaining-!w[%%I]!" >nul
        )
    )
)
exit /b 0

:oracle
set "oracle=0"
set /a "last=(1 << n)-1" >nul
for /l %%M in (0,1,!last!) do (
    set "weight=0"
    set "value=0"
    for /l %%I in (1,1,!n!) do (
        set /a "taken=(%%M >> (%%I-1)) & 1" >nul
        if !taken! equ 1 (
            set /a "weight=weight+!w[%%I]!, value=value+!v[%%I]!" >nul
        )
    )
    if !weight! leq !capacity! if !value! gtr !oracle! set "oracle=!value!"
)
exit /b 0

:verify_selection
set "weight=0"
set "value=0"
for /l %%I in (1,1,!n!) do (
    set /a "taken=(selected >> (%%I-1)) & 1" >nul
    if !taken! equ 1 (
        set /a "weight=weight+!w[%%I]!, value=value+!v[%%I]!" >nul
    )
)
if !weight! gtr !capacity! (
    echo Reconstructed subset exceeds capacity 1>&2
    exit /b 1
)
if not "!value!"=="!answer!" (
    echo Reconstructed subset has wrong value 1>&2
    exit /b 1
)
exit /b 0
