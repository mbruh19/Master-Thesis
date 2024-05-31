@echo off

setlocal enabledelayedexpansion

set CURRENT_DIR=%CD% 

echo %CURRENT_DIR%

echo Current directory: %CURRENT_DIR%

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



set "objectives[0]=cross_entropy"
set "objectives[1]=brier"

set batchsize=2000

set reb[0]=0
set reb[1]=2 

set rec[0]=0
set rec[1]=4

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

set lfstart=../log/BNN_vs_TNN_v2/

for /L %%s in (3, 1, 4) do (
    for /L %%t in (0, 1, 0) do (
        for /L %%o in (0, 1, 0) do (
            for /L %%n in (0, 1, 1) do ( 
                echo Current iteration: seeds[%%s]=!seeds[%%s]!, tls[%%t]=!tls[%%t]!, objectives[%%o]=!objectives[%%o]!, nts[%%n]=!nts[%%n]!  REM Debugging line
                set "current_nt=!nts[%%n]!"
                echo !current_nt!
                if "!current_nt!"=="TNN" (
                    set "current_obj"=!objectives[%%o]!"
                    for /L %%r in (0, 1, 0) do (
                        if "!current_obj!"=="cross_entropy" (
                            set re=!rec[%%r]!
                        ) else (
                            set re=!reb[%%r]!
                        )
                        echo !re!
                        set lf=!lfstart!!seeds[%%s]!_!nts[%%n]!_!tls[%%t]!_!objectives[%%o]!_!re!
                        python -m main -ct !ct! -nt !nts[%%n]! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tls[%%t]! -ps !ps! -l !l! -lf !lf! -re !re!
                    )
                ) else (
                    set lf=!lfstart!!seeds[%%s]!_!nts[%%n]!_!tls[%%t]!_!objectives[%%o]!
                    echo !current_nt!
                    python -m main -ct !ct! -nt !nts[%%n]! -ns !ns! -ds !ds! -vp !vp! -bs !batchsize! -ts !ts! -st !st! -ot !objectives[%%o]! -so !so! -al !al! -se !seeds[%%s]! -tl !tls[%%t]! -ps !ps! -l !l! -lf !lf!
                )
            )
        )
    )
)   



REM python -m main


REM go back to original directory  
cd %CURRENT_DIR% 