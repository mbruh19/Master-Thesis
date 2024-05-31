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
set nss[1]=784 128 10

set bps[0]=0.05
set bps[1]=0.1
set bps[2]=0.15
set bps[3]=0.2




set ct="multi"
set nt="BNN"

set batchsize=1000

set ds="MNIST"
set vp=1/3
set vs=10000
set ts=10000
set st="random"
set al="batch_training"
set tl=3600
set l="True" 
set ep=10
set es="True"
set ni=20


set lfstart=../log/MBT_FT_II/

for /L %%s in (0, 1, 4) do (
    for /L %%o in (0, 1, 3) do (
        for /L %%n in (0, 1, 1) do (
            
            set nss_underscored=!nss[%%n]!
            set nss_underscored=!nss_underscored: =_!
            set lf=!lfstart!!seeds[%%s]!_!bps[%%o]!_!nss_underscored!
            echo !lf!
            python -m main -ct !ct! -nt !nt! -ns !nss[%%n]! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objective! -al !al! -se !seeds[%%s]! -tl !tl! -bp !bps[%%o]! -l !l! -lf !lf! -es !es! -ni !ni! -ep !ep!
            echo !lf!   
        )
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 