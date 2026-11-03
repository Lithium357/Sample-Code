@echo on
setlocal EnableExtensions EnableDelayedExpansion
rem Floyd-Warshall all-pairs shortest paths and next-hop reconstruction.
rem Windows CMD only; n <= 10; bounded integer weights; INF is a sentinel.
rem cmd /d /c floyd_warshall.cmd
set "n=5"
set "INF=1000000"
for /l %%I in (1,1,!n!) do for /l %%J in (1,1,!n!) do (
    set "edge[%%I,%%J]=!INF!"
    set "dist[%%I,%%J]=!INF!"
    set "next[%%I,%%J]=0"
    if %%I equ %%J set "dist[%%I,%%J]=0"
)
call :arc 1 2 3
call :arc 1 3 8
call :arc 1 5 -4
call :arc 2 4 1
call :arc 2 5 7
call :arc 3 2 4
call :arc 4 1 2
call :arc 4 3 -5
call :arc 5 4 6
for /l %%K in (1,1,!n!) do for /l %%I in (1,1,!n!) do for /l %%J in (1,1,!n!) do call :relax %%I %%J %%K
for /l %%I in (1,1,!n!) do if !dist[%%I,%%I]! lss 0 (
    echo Unexpected negative cycle 1>&2
    exit /b 1
)
rem Independent oracle: Bellman-Ford from every source using only original arcs.
for /l %%S in (1,1,!n!) do (
    for /l %%I in (1,1,!n!) do set "bf[%%I]=!INF!"
    set "bf[%%S]=0"
    set /a "passes=n-1" >nul
    for /l %%P in (1,1,!passes!) do (
        for /l %%I in (1,1,!n!) do for /l %%J in (1,1,!n!) do (
            if !bf[%%I]! lss !INF! if !edge[%%I,%%J]! lss !INF! (
                set /a "candidate=!bf[%%I]!+!edge[%%I,%%J]!" >nul
                if !candidate! lss !bf[%%J]! set "bf[%%J]=!candidate!"
            )
        )
    )
    for /l %%T in (1,1,!n!) do (
        if not "!bf[%%T]!"=="!dist[%%S,%%T]!" (
            echo Bellman-Ford mismatch 1>&2
            exit /b 1
        )
        set "source=%%S"
        set "target=%%T"
        call :verify_path
        if errorlevel 1 exit /b 1
    )
)
if not "!dist[1,3]!"=="-3" exit /b 1
rem Adding 3->1 with weight -100 creates a negative cycle. Detect it with
rem another Bellman-Ford pass: improvement after n-1 passes proves a cycle.
set "edge[3,1]=-100"
for /l %%I in (1,1,!n!) do set "bf[%%I]=0"
for /l %%P in (1,1,!n!) do (
    set "changed=0"
    for /l %%I in (1,1,!n!) do for /l %%J in (1,1,!n!) do (
        if !edge[%%I,%%J]! lss !INF! (
            set /a "candidate=!bf[%%I]!+!edge[%%I,%%J]!" >nul
            if !candidate! lss !bf[%%J]! (
                set "bf[%%J]=!candidate!"
                set "changed=1"
            )
        )
    )
)
if not "!changed!"=="1" exit /b 1
echo Floyd-Warshall: 25 oracle paths, negative weights and negative-cycle detection passed
exit /b 0

:arc
set "edge[%~1,%~2]=%~3"
set "dist[%~1,%~2]=%~3"
set "next[%~1,%~2]=%~2"
exit /b 0

:relax
set "left=!dist[%~1,%~3]!"
set "right=!dist[%~3,%~2]!"
set "existing=!dist[%~1,%~2]!"
if !left! geq !INF! exit /b 0
if !right! geq !INF! exit /b 0
set /a "candidate=left+right" >nul
if !candidate! lss !existing! (
    set "dist[%~1,%~2]=!candidate!"
    set "next[%~1,%~2]=!next[%~1,%~3]!"
)
exit /b 0

:verify_path
set "current=!source!"
set "total=0"
set "hops=0"
:path_loop
if "!current!"=="!target!" goto :path_done
set /a "hops=hops+1" >nul
if !hops! gtr !n! exit /b 1
for %%C in (!current!) do for %%T in (!target!) do set "following=!next[%%C,%%T]!"
if "!following!"=="0" exit /b 1
for %%C in (!current!) do for %%F in (!following!) do (
    if !edge[%%C,%%F]! geq !INF! exit /b 1
    set /a "total=total+!edge[%%C,%%F]!" >nul
)
set "current=!following!"
goto :path_loop
:path_done
for %%S in (!source!) do for %%T in (!target!) do (
    if not "!total!"=="!dist[%%S,%%T]!" exit /b 1
)
exit /b 0
