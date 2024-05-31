#!/bin/bash

# Enable extended globbing
shopt -s extglob

CURRENT_DIR=$(pwd)

echo "$CURRENT_DIR"

# Get directory to main.py
cd ../src || exit

seeds=(42 142 242 342 442)
objectives=("integer" "cross_entropy" "softmax")
batchsizes=(1100 1200 1300 1400 1500 1600 1700 1800 1900 2000)

ct="multi"
nt="BNN"
ns=(784 16 10)
ds="MNIST"
vp=0.5
ts=8000
st="balanced"
al="single_batch"
so="ils"
tl=60
l="True"
ps=25

lfstart="../log/SBT_COF/"

for s in "${!seeds[@]}"; do
    for o in "${!objectives[@]}"; do
        for b in "${!batchsizes[@]}"; do
            echo "${seeds[s]} ${objectives[o]} ${batchsizes[b]}"
            lf="${lfstart}${seeds[s]}_${objectives[o]}_${batchsizes[b]}"
            python3 -m main -ct "$ct" -nt "$nt" -ns "${ns[@]}" -ds "$ds" -vp "$vp" -bs "${batchsizes[b]}" -ts "$ts" -st "$st" -ot "${objectives[o]}" -so "$so" -al "$al" -se "${seeds[s]}" -tl "$tl" -ps "$ps" -l "$l" -lf "$lf"
            echo "$lf"
        done
    done
done

# Go back to original directory
cd "$CURRENT_DIR" || exit
