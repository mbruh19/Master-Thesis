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


set res[0]=0.0
set res[1]=0.00001
set res[2]=0.0001
set res[3]=0.001
set res[4]=0.01
set res[5]=0.1
set res[6]=1.0
set res[7]=10.0

set bs=2000
set ct="multi"
set nt="TNN"
set ns=784 16 10
set ds="MNIST"
set vp=0.5
set ts=8000
set st="balanced"
set al="single_batch"
set so="ils"
set tl=300
set l="True" 
set ps=30

set lfstart=../log/TNN_COF/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 2) do (
        for /L %%b in (0, 1, 0) do (
            echo !seeds[%%s]! !objectives[%%o]! !res[%%b]!
            set lf=!lfstart!!seeds[%%s]!_!objectives[%%o]!_!res[%%b]!
            python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !bs! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf! -re !res[%%b]!
            echo !lf!
        )
    )
)
REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 


REM go back to original directory  
cd %CURRENT_DIR% 