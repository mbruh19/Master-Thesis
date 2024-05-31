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

set nss[0]=784 16 10
set nss[1]=784 128 10

set al="single_batch"

set batchsize=2000


set ct="multi"
set nt="BNN"

set ds="FMNIST"
set vp=0.5
set ts=8000
set st="balanced"
set so="ils"
set tl=300
set l="True" 
set ps=25

set lfstart=../log/SBT_DNS_FMNIST/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 2) do (
        for /L %%n in (0, 1, 1) do (
            set nss_underscored=!nss[%%n]!
            set nss_underscored=!nss_underscored: =_!
            set lf=!lfstart!!seeds[%%s]!_!objectives[%%o]!_!nss_underscored!_!als[%%a]!
            echo !lf! 
            python -m main -ct !ct! -nt !nt! -ns !nss[%%n]! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objectives[%%o]! -al !al! -se !seeds[%%s]! -tl !tl! -l !l! -lf !lf! -ps !ps! -so !so!
            echo !lf!   
        )   
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 