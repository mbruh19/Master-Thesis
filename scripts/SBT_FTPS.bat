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


set objective="cross_entropy"

set nss[0]=784 16 10
set nss[1]=784 128 10


set pss[0]=5
set pss[1]=10
set pss[2]=15
set pss[3]=20
set pss[4]=25
set pss[5]=30
set pss[6]=35
set pss[7]=40




set batchsize=2000

set ct="multi"
set nt="BNN"

set ds="MNIST"
set vp=0.5
set ts=8000
set st="balanced"
set al="single_batch"
set tl=300
set so="ils"
set l="True" 

set lfstart=../log/SBT_FTPS/

for /L %%s in (0, 1, 4) do (
    for /L %%p in (0, 1, 7) do (
        for /L %%n in (0, 1, 1) do (
            set nss_underscored=!nss[%%n]!
            set nss_underscored=!nss_underscored: =_!
            set lf=!lfstart!!seeds[%%s]!_!pss[%%p]!_!nss_underscored!
            python -m main -ct !ct! -nt !nt! -ns !nss[%%n]! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objective! -so !so! -al !al! -se !seeds[%%s]! -tl !tl! -ps !pss[%%p]! -l !l! -lf !lf!
            echo !lf!   
        )
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 