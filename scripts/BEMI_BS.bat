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

set smtl=5


set batchsizes[0]=100
set batchsizes[1]=200
set batchsizes[2]=300
set batchsizes[3]=400
set batchsizes[4]=500
set batchsizes[5]=600
set batchsizes[6]=700
set batchsizes[7]=800
set batchsizes[8]=900
set batchsizes[9]=1000
set batchsizes[10]=1100
set batchsizes[11]=1200
set batchsizes[12]=1300
set batchsizes[13]=1400
set batchsizes[14]=1500

set objective="cross_entropy"


set ct="binary"
set nt="BNN"
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
set ps=25 

set lfstart=../log/BEMI_BS/

for /L %%b in (0, 1, 14) do (
    for /L %%s in (0, 1, 4) do (
            set lf=!lfstart!!seeds[%%s]!_!batchsizes[%%b]!
            python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsizes[%%b]! -ts !ts! -st !st! -ot !objective! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf! -smtl !smtl! -vs !vs!
            echo !lf!
    )
)

REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 