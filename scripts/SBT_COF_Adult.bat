@echo off

setlocal enabledelayedexpansion

set CURRENT_DIR=%CD% 

echo %CURRENT_DIR%

REM Get directory to main.py
cd ../src


set seeds[0]=42
set seeds[1]=142
set seeds[2]=242
set seeds[3]=342
set seeds[4]=442

set "objectives[0]=integer"
set "objectives[1]=cross_entropy"
set "objectives[2]=brier"


set bs=800
set ct="binary"
set nt="BNN"
set ns=104 16 1
set ds="Adult"
set vs=0
set ts=15060
set st="random"
set al="single_batch"
set so="ils"
set tl=60
set l="True" 
set ps=50

set lfstart=../log/SBT_COF_Adult/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 2) do (
        echo !seeds[%%s]! !objectives[%%o]! !res[%%b]!
        set lf=!lfstart!!seeds[%%s]!_!objectives[%%o]!_!res[%%b]!
        python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vs !vs! -bs !bs! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf!
        echo !lf!
        
    )
)
REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 


REM go back to original directory  
cd %CURRENT_DIR% 