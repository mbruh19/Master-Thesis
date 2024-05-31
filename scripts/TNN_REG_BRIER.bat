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


set objective="brier"

set res[0]=0.5
set res[1]=0.75
set res[2]=1
set res[3]=1.25
set res[4]=1.5
set res[5]=1.75
set res[6]=2
set res[7]=2.25
set res[8]=2.5
set res[9]=2.75
set res[10]=3
set res[11]=3.25
set res[12]=3.5
set res[13]=3.75
set res[14]=4

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

set lfstart=../log/TNN_REG_BRIER/

for /L %%s in (0, 1, 4) do (
    for /L %%b in (2, 1, 2) do (
        echo !seeds[%%s]! !res[%%b]!
        set lf=!lfstart!!seeds[%%s]!_!res[%%b]!
        python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !bs! -ts !ts! -st !st! -ot !objective! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf! -re !res[%%b]!
        echo !lf!
    )
)

REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 


REM go back to original directory  
cd %CURRENT_DIR% 