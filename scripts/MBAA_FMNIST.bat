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

set objective="integer"


set ns=784 128 128 10



set batchsize=1000


set ct="multi"
set nt="BNN"
set ds="FMNIST"
set vp=0
set vs=0
set ts=10000
set st="random"
set al="batch_training_fine_tuning"
set tl=600
set l="True" 
set bp=1


set lfstart=../log/MBAA_FMNIST/

for /L %%s in (0, 1, 4) do (
    set lf=!lfstart!!seeds[%%s]!_BP_1
    echo !lf!   
    python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -vs !vs! -ts !ts! -st !st! -ot !objective! -al !al! -se !seeds[%%s]! -tl !tl! -l !l! -lf !lf! -bp !bp!
    echo !lf!   
    echo !seeds[%%s]!
    
)


REM go back to original directory  
cd %CURRENT_DIR% 