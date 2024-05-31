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

set pss[0]=10
set pss[1]=30
set pss[2]=50

set reg[0]=0
set reg[1]=0.0001
set reg[2]=0.001
set reg[3]=0.01


set smtl=20


set batchsize=1000


set objective="cross_entropy"


set ct="binary"
set nt="TNN"
set ns=784 10 1
set ds="MNIST"
set vp=0.0
set vs=0
set ts=8000
set st="balanced"
set al="binary_training"
set so="ils"
set tl=90
set l="True" 


set lfstart=../log/BEMI_TNN/

for /L %%s in (4, 1, 4) do (
    for /L %%r in (3, 1, 3) do (
        for /L %%b in (2, 1, 2) do (
            set lf=!lfstart!!seeds[%%s]!_!pss[%%b]!_!reg[%%r]!
            python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objective! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !pss[%%b]! -l !l! -lf !lf! -smtl !smtl! -vs !vs! -re !reg[%%r]!
            echo !lf!
        )
    )      
)

REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 