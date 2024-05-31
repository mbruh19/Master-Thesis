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

set res[0]=0.0
set res[1]=0.00001
set res[2]=0.0001
set res[3]=0.001
set res[4]=0.01
set res[5]=0.1
set res[6]=0.2

set objective="softmax"
set batchsize=2000


set ct="multi"
set nt="TNN"
set ns=784 16 10
set ds="MNIST"
set vp=0.5
set ts=8000
set st="balanced"
set al="single_batch"
set so="ils"
set tl=60
set l="True" 
set ps=25 

set lfstart=../log/TNN_REG_TL_60/

for /L %%s in (0, 1, 4) do (
    for /L %%r in (0, 1, 6) do (
        echo !seeds[%%s]! !res[%%r]! 
        set lf=!lfstart!!seeds[%%s]!_!res[%%r]!
        python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objective! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf! -re !res[%%r]!
        echo !lf!

    )
)

REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 