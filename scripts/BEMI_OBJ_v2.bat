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

set smtls[0]=5
set smtls[1]=10


set batchsizes[0]=100
set batchsizes[1]=1000

set "objectives[0]=integer"
set "objectives[1]=brier"
set "objectives[2]=cross_entropy"


set ct="binary"
set nt="BNN"
set ns=784 10 3 1
set ds="MNIST"
set vp=0.0
set vs=0
set ts=8000
set st="balanced"
set al="binary_training"
set so="ils"
set tl=90
set l="True" 
set ps=25 

set lfstart=../log/BEMI_OBJ_v2/

for /L %%s in (0, 1, 4) do (
    for /L %%r in (0, 1, 1) do (
        for /L %%b in (0, 1, 1) do (
            for /L %%o in (0, 1, 2) do (
                set lf=!lfstart!!seeds[%%s]!_!batchsizes[%%b]!_!smtls[%%r]!_!objectives[%%o]!
                python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsizes[%%b]! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf! -smtl !smtls[%%r]! -vs !vs!
                echo !lf!
    )   )   )
)

REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 