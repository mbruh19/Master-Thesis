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



set bps[0]=0.1
set bps[1]=0.3
set bps[2]=0.4
set bps[3]=0.5
set bps[4]=1.0

set ns=784 128 128 10

set "als[0]=batch_training"
set "als[1]=batch_training_ils"
set "als[2]=aggregation_algorithm"

set batchsize=1000


set ct="multi"
set nt="BNN"

set ds="MNIST"
set vp=0.2
set vs=12000
set ts=10000
set st="random"

set objective="cross_entropy"
set tl=600
set l="True" 
set ep=100
set us=1
set ue=15
set ui=10
set smtl=5
set ps=25

set lfstart=../log/MBT_FTBP_CS/

for /L %%s in (4, 1, 4) do (
    for /L %%p in (3, 1, 4) do (
        for /L %%a in (0, 1, 2) do ( 
            set "current_al=!als[%%a]!"
            if "!current_al!" == "batch_training" (
                set ni=4
            ) else (
                set ni=1
            )
            if "!current_al!" =="batch_training_fine_tuning" (
                set vp=0
                set vs=0
            ) else (
                set vp=0.2
                set vs=12000
            )
            REM Echo the value of ni for debugging
            echo als[%%a]=!current_al!, ni=!ni!
            set nss_underscored=!nss[%%n]!
            set nss_underscored=!nss_underscored: =_!
            set lf=!lfstart!!seeds[%%s]!_!bps[%%p]!_!als[%%a]!
            python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -vs !vs! -ts !ts! -st !st! -ot !objective! -al !als[%%a]! -se !seeds[%%s]! -tl !tl! -l !l! -lf !lf! -ep !ep! -bp !bps[%%p]! -es -ni !ni! -us !us! -ue !ue! -ui !ui! -smtl !smtl! -ps !ps!
            echo !lf!   
        )   
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 