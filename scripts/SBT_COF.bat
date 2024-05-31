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
set batchsizes[15]=1600
set batchsizes[16]=1700
set batchsizes[17]=1800
set batchsizes[18]=1900
set batchsizes[19]=2000



set ct="multi"
set nt="BNN"
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

set lfstart=../log/SBT_COF/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 2) do (
        for /L %%b in (0, 1, 19) do (
            echo !seeds[%%s]! !objectives[%%o]! !batchsizes[%%b]! 
            set lf=!lfstart!!seeds[%%s]!_!objectives[%%o]!_!batchsizes[%%b]!
            python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsizes[%%b]! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf!
            echo !lf!
        )
    )
)
REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 