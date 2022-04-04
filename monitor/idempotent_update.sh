#!/bin/bash

LOANSPATH=`grep "LOANSPATH" /etc/profile | sed s/LOANSPATH=// | sed 's/\"//g'`

#this xvfb-run version is needed if something weird happens that messes with R's chart generation.
#xvfb-run /usr/bin/Rscript --vanilla $LOANSPATH/monitor/plot_gain.r
/usr/bin/Rscript --vanilla $LOANSPATH/monitor/plot_gain.r

convert -size 240x24 xc:white -font "FreeMono" -pointsize 12 -fill black -draw "text 15,15 \"$(date)" $LOANSPATH/monitor/date.png
convert $LOANSPATH/monitor/gain_chart_2016originations.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/gain_chart_2016originations.png
convert $LOANSPATH/monitor/data/investment_chart_2016originations.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/data/investment_chart_2016originations.png
convert $LOANSPATH/monitor/gain_chart_2017originations.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/gain_chart_2017originations.png
convert $LOANSPATH/monitor/data/investment_chart_2017originations.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/data/investment_chart_2017originations.png
convert $LOANSPATH/monitor/gain_chart_2018RFv3Conservative.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/gain_chart_2018RFv3Conservative.png
convert $LOANSPATH/monitor/data/investment_chart_2018RFv3Conservative.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/data/investment_chart_2018RFv3Conservative.png
convert $LOANSPATH/monitor/gain_chart_2018RFv4.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/gain_chart_2018RFv4.png
convert $LOANSPATH/monitor/data/investment_chart_2018RFv4.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/data/investment_chart_2018RFv4.png
convert $LOANSPATH/monitor/gain_chart_2019RFv4.3.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/gain_chart_2019RFv4.3.png
convert $LOANSPATH/monitor/data/investment_chart_2019RFv4.3.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/data/investment_chart_2019RFv4.3.png
convert $LOANSPATH/monitor/gain_chart_2019XGBv1.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/gain_chart_2019XGBv1.png
convert $LOANSPATH/monitor/data/investment_chart_2019XGBv1.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/data/investment_chart_2019XGBv1.png
convert $LOANSPATH/monitor/available.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/available.png
convert $LOANSPATH/monitor/available_zoom3month.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/available_zoom3month.png
convert $LOANSPATH/monitor/net_annualized_roi_after_fees.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/net_annualized_roi_after_fees.png
convert $LOANSPATH/monitor/net_annualized_roi_after_fees_DERIVATIVE.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/net_annualized_roi_after_fees_DERIVATIVE.png
convert $LOANSPATH/monitor/chargeoff_fracs_combined.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/chargeoff_fracs_combined.png
convert $LOANSPATH/monitor/plot_since_v4_gain_per_dollaryear.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/plot_since_v4_gain_per_dollaryear.png
convert $LOANSPATH/monitor/account_val_history.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/account_val_history.png

TOTALVAL=`cat $LOANSPATH/monitor/account_value_minus_inFunding.txt`
CURAVAIL=`cat $LOANSPATH/monitor/cur_available_cash.txt`
DAILYOUTFLOW=`cat $LOANSPATH/monitor/recent_outflow.txt`
convert -size 240x24 xc:white -font "FreeMono" -pointsize 12 -fill black -draw "text 15,15 \"$TOTALVAL" $LOANSPATH/monitor/totalvalue.png
convert $LOANSPATH/monitor/totalvalue.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/totalvalue.png
convert -size 240x24 xc:white -font "FreeMono" -pointsize 12 -fill black -draw "text 15,15 \"$CURAVAIL" $LOANSPATH/monitor/cur_available.png
convert $LOANSPATH/monitor/cur_available.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/cur_available.png
convert -size 240x24 xc:white -font "FreeMono" -pointsize 12 -fill black -draw "text 15,15 \"$DAILYOUTFLOW" $LOANSPATH/monitor/recent_daily_outflow.png
convert $LOANSPATH/monitor/recent_daily_outflow.png $LOANSPATH/monitor/date.png -append $LOANSPATH/monitor/recent_daily_outflow.png

$LOANSPATH/monitor/publish_http.sh

cd $LOANSPATH/monitor/data
git add .
git commit -m "daily update"
git push origin master
