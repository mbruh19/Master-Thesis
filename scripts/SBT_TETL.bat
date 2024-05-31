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

set tls[0]=10
set tls[1]=20
set tls[2]=30
set tls[3]=40
set tls[4]=50
set tls[5]=60
set tls[6]=70
set tls[7]=80
set tls[8]=90
set tls[9]=100


set batchsize=1000

set ct="multi"
set nt="BNN"
set ns=784 16 10
set ds="MNIST"
set vp=0.5
set ts=8000
set st="balanced"
set al="single_batch"
set so="ils"
set l="True" 
set ps=25 

set lfstart=../log/SBT_TETL/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 2) do (
        for /L %%t in (0, 1, 9) do (
            set lf=!lfstart!!seeds[%%s]!_!objectives[%%o]!_!tls[%%t]!
            python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tls[%%t]! -ps !ps! -l !l! -lf !lf!
            echo !lf!
            
        )
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 