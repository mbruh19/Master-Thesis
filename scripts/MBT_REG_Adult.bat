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

set regs[0]=0
set regs[1]=2
set regs[2]=4
set regs[3]=6
set regs[4]=10
set regs[5]=8
set regs[6]=0.5


set ns=104 16 1
set al="batch_training_fine_tuning"

set batchsize=800


set ct="binary"
set nt="TNN"

set ds="Adult"
set vs=0
set ts=15060
set st="random"
set tl=90
set l="True" 
set ep=1000
set us=1
set ue=30
set ui=10
set smtl=0.5
set ps=30
set bp=1
set ni=0

set lfstart=../log/MBT_REG_Adult/

for /L %%s in (3, 1, 4) do (
    for /L %%r in (0, 1, 4) do (
        REM Echo the value of ni for debugging
        echo als[%%a]=!current_al!, ni=!ni!
        set nss_underscored=!nss[%%n]!
        set nss_underscored=!nss_underscored: =_!
        set lf=!lfstart!!seeds[%%s]!_!regs[%%r]!
        python -m main -ct !ct! -nt !nt! -ns !ns! -ds !ds! -bs !batchsize! -vs !vs! -ts !ts! -st !st! -ot !objective! -al !al! -se !seeds[%%s]! -tl !tl! -l !l! -lf !lf! -ep !ep! -re !regs[%%r]! -ni !ni! -us !us! -ue !ue! -ui !ui! -smtl !smtl! -ps !ps! -bp !bp!
        echo !lf!   
    )
)


REM go back to original directory  
cd %CURRENT_DIR% 