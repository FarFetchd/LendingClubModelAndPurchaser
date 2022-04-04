#!/bin/bash

LOANSPATH=`grep "LOANSPATH" /etc/profile | sed s/LOANSPATH=// | sed 's/\"//g'`

echo "remember, if running manually, you also need LOAN_PREDICTOR_R.sh running separately!"
# not as relevant on the pi, also, renice needs to hit R now. echo "DONT'T FORGET TO RENICE! Run: sudo renice -5 -p \$(pidof rest_loans_cpp)"
mkdir "$LOANSPATH/purchaser/tmpRtoD/finished"
mkdir "$LOANSPATH/purchaser/tmpRtoD/r_finished"
"$LOANSPATH/purchaser/rest_loans_cpp" startnow 2>>"$LOANSPATH/purchaser/logs/cur_2020_postpandemic.txt"
