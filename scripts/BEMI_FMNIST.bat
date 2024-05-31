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

set smtl=20


set batchsize=1000

set objective="cross_entropy"


set ct="binary"
set nt="BNN"
set ns=784 10 1
set ds="FMNIST"
set vp=0.0
set vs=0
set ts=8000
set st="balanced"
set al="binary_training"
set so="ils"
set tl=90
set l="True" 
set ps=25 

set lfstart=../log/BEMI_FMNIST/

for /L %%s in (0, 1, 4) do (
        echo !seeds[%%s]! !smtls[%%r]! 
        set lf=!lfstart!!seeds[%%s]!
        python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objective! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf! -smtl !smtl! -vs !vs!
        echo !lf!
)


REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 