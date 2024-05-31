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

set nss[0]=784 16 10
set nss[1]=784 32 10
set nss[2]=784 64 10
set nss[3]=784 128 10
set nss[4]=784 16 16 10
set nss[5]=784 32 32 10
set nss[6]=784 64 64 10
set nss[7]=784 128 128 10
set nss[8]=784 256 10
set nss[9]=784 256 256 10



set batchsize=1000

set ct="multi"
set nt="BNN"

set ds="MNIST"
set vp=0.5
set ts=8000
set st="balanced"
set al="single_batch"
set tl=120
set so="ils"
set l="True" 
set ps=25 

set lfstart=../log/exp3/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 2) do (
        for /L %%n in (0, 1, 9) do (
            set nss_underscored=!nss[%%n]!
            set nss_underscored=!nss_underscored: =_!
            set lf=!lfstart!!seeds[%%s]!_!objectives[%%o]!_!nss_underscored!
            python -m main -ct !ct! -nt !nt! -ns !nss[%%n]! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !ps! -l !l! -lf !lf!
            echo !lf!   
        )
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 