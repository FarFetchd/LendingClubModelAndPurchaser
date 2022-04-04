#!/bin/bash

LOANSPATH=`grep "LOANSPATH" /etc/profile | sed s/LOANSPATH=// | sed 's/\"//g'`

/usr/bin/Rscript --vanilla "$LOANSPATH/purchaser/loan_predictor.r" 2>>"$LOANSPATH/purchaser/logs/cur_2020_postpandemic.txt"
