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

set "nts[0]=BNN"
set "nts[1]=TNN"

set tls[0]=30
set tls[1]=60
set tls[2]=90
set tls[3]=120
set tls[4]=150
set tls[5]=180
set tls[6]=210
set tls[7]=240
set tls[8]=270
set tls[9]=300



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
set l="True" 
set ps=25 

set lfstart=../log/BNN_vs_TNN/

for /L %%s in (0, 1, 4) do (
    for /L %%r in (0, 1, 1) do (
        for /L %%t in (0, 1, 12) do (
            set lf=!lfstart!!seeds[%%s]!_!nts[%%r]!_!tls[%%t]!
            echo !lf!
            python -m main -ct !ct! -nt !nts[%%r]! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objective! -so !so! -al !al! -se !seeds[%%s]! -tl !tls[%%t]! -ps !ps! -l !l! -lf !lf! 
            echo !lf!
        )
    )
)

REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 