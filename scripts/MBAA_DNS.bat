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

set nss[0]=784 64 10
set nss[1]=784 64 64 10
set nss[2]=784 128 10
set nss[3]=784 128 128 10
set nss[4]=784 256 10
set nss[5]=784 256 256 10



set batchsize=1000


set ct="multi"
set nt="BNN"
set ds="MNIST"
set vp=0
set vs=0
set ts=10000
set st="random"
set al="batch_training_fine_tuning"
set tl=600
set l="True" 
set bp=1

set us=1
set ue=15
set ui=10

set lfstart=../log/MBAA_DNS/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 4) do (
            set nss_underscored=!nss[%%o]!
            set nss_underscored=!nss_underscored: =_!
            set lf=!lfstart!!seeds[%%s]!_!nss_underscored!
            python -m main -ct !ct! -nt !nt! -ns !nss[%%o]! -ds !ds! -vp !vp! -bs !batchsize! -vs !vs! -ts !ts! -st !st! -ot !objective! -al !al! -se !seeds[%%s]! -tl !tl! -l !l! -lf !lf! -bp !bp! -us !us! -ue !ue! -ui !ui!
            echo !lf!   
            echo !seeds[%%s]!
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 