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
set "objectives[2]=softmax"

set ni=4

set ns=784 64 10

set batchsize=1000


set ct="multi"
set nt="BNN"

set ds="MNIST"
set vp=1/3
set vs=10000
set ts=10000
set st="random"
set al="batch_training_ils"
set tl=3600
set smtl=5
set l="True" 
set ep=2
set bp=0.1
set ps=25
set es="True"

set lfstart=../log/BatchTrainingILS/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 2) do (
            set lf=!lfstart!!seeds[%%s]!_!objectives[%%o]!
            python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -vs !vs! -ts !ts! -st !st! -ot !objectives[%%o]! -al !al! -se !seeds[%%s]! -tl !tl! -l !l! -lf !lf! -ps !ps! -smtl !smtl! -ep !ep! -bp !bp! -es !es! -ni !ni!
            echo !lf!   
            echo !seeds[%%s]!
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 