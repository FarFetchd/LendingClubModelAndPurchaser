#!/bin/bash

LOANSPATH=`grep "LOANSPATH" /etc/profile | sed s/LOANSPATH=// | sed 's/\"//g'`

# TODO multiaccount
wget -O $LOANSPATH/monitor/today_performance.csv --header="Accept: text/csv" --header="Authorization: SANITIZED" "https://api.lendingclub.com/api/investor/v1/accounts/SANITIZED/detailednotes"

# TODO probably trim this next line.... should really count issued, right? otherwise you're
# ignoring a full month that principal was definitely tied up. (and, ignoring it means that right
# after the 2nd payment, you see double return for the first 30 days. probably explains the graphs
# starting bizarrely high and converging downward).
#sed -i '/Issued/d' $LOANSPATH/monitor/today_performance.csv
# not sure if this is actually a real one, but i think it might be
sed -i '/Issuing/d' $LOANSPATH/monitor/today_performance.csv
sed -i '/In Review/d' $LOANSPATH/monitor/today_performance.csv

#adjust_spent looks for what looks like an account contribution (expected to be >=2k, in units of 1k)
#and adjusts spent.csv accordingly to prevent loan-payoff-outflow estimate to suddenly be absurdly large
/usr/bin/Rscript --vanilla $LOANSPATH/monitor/adjust_spent.r
/usr/bin/Rscript --vanilla $LOANSPATH/monitor/calculate_lc_performance.r

MONEYZ=`cat $LOANSPATH/monitor/account_value_minus_inFunding.txt` ; echo "$(date --rfc-3339=date),$MONEYZ" >>$LOANSPATH/monitor/data/account_val_history.csv

$LOANSPATH/monitor/idempotent_update.sh
