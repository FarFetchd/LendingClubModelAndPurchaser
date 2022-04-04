setwd(sub("\"\n", "",
          sub(".*LOANSPATH=\"", "",
              readChar("/etc/profile", file.info("/etc/profile")$size))))

TOO_SLOW = -1234

computeRecentDailyLoansSeen = function()
{
  all = read.csv("monitor/data/loans_seen.csv", h=T)
  all$date = as.Date(all$date)
  today = Sys.Date()
  # take last 90 days, or previous 30 datapoints if <30 datapoints in last 90 days
  last90days = subset(all, date > today - 90)
  dayoffset = 90
  while (nrow(last90days) < 30 & nrow(all) >= 30)
  {
    dayoffset = dayoffset + 1
    last90days = subset(all, date > today - dayoffset)
  }
  return (4 * mean(last90days$loans_seen))
}

# spend rate is expressed as a positive: -.2 would mean that cash is piling up
# at a rate of 20 cents per day.
spendrateForFrac = function(fractaken, dollars_per_loan_unit)
{
  daily_cash_pileup = scan("monitor/recent_outflow.txt", quiet=T)[1]
  daily_loans_seen = computeRecentDailyLoansSeen()

  return (daily_loans_seen * fractaken * dollars_per_loan_unit -
          daily_cash_pileup)
}

returnVsEasy = function(roi, fractaken, cash_avail, dollars_per_loan_unit)
{
  spend = spendrateForFrac(fractaken, dollars_per_loan_unit)
  # 0.000055 return per dollarday is ~ 2% per year.
  oppcost_dollars_per_dollarday=0.000055

  if (spend < 0 | cash_avail / spend > 30) # >30 days is too silly to consider
    return(TOO_SLOW)
  # opp_cost_idle is the opportunity cost of the cash sitting idle while we're
  # waiting to find loans to buy (at the rate of the current estimated spendrate).
  # The dollardays we're using here is the triangle of the cash being spent
  # down over time, so, (cash_avail) * (time it will take) / 2.
  # (time it will take) is cash_avail / spend.
  opp_cost_idle =
      oppcost_dollars_per_dollarday *
      ((cash_avail * (cash_avail / spend)) / 2)
  batch_return = 3 * roi * cash_avail
  # if you choose LC, you get the LC batch return, miss out on VMATX during
  # idle period, and miss out on VMATX during 3 year term.
  LC_advantage = batch_return -
                 (opp_cost_idle + cash_avail*3*365*oppcost_dollars_per_dollarday)
  return(LC_advantage)
}

# TODO multiaccount: data/available_cash.csv, everywhere that uses EXAMPLEACCOUNT
cash_per_note = as.numeric(read.csv(
    "purchaser/state/EXAMPLEACCOUNT/cashPerNote.txt", h=F))

hmm = read.csv("monitor/data/available_cash.csv", h=T)
hmm$date = as.Date(hmm$date)
avail = mean(hmm$available[which(hmm$date >= max(hmm$date))])

df2=read.csv("purchaser/state/curPareto.csv", h=T)
df2$benefit=0
for(i in seq(1, nrow(df2)))
{
  df2$benefit[i] = returnVsEasy(df2$ROIavg[i], df2$fractaken[i], avail,
                                cash_per_note)
}


if (max(df2$benefit) == TOO_SLOW)
{
  write(paste0(date(), ": don't expect to spend down our $",avail,
               " within 30 days. Falling back to max fractaken."),
        file="purchaser/logs/maxed_out_spendrates", append=T)
  df2=df2[order(df2$fractaken),]
} else {
  df2=df2[order(df2$benefit),]
}
bestSpendrateROI = df2$ROIavg[nrow(df2)]
bestSpendrateFrac = df2$fractaken[nrow(df2)]
bestSpendrateProbBad = df2$badProb[nrow(df2)]
bestSpendrateIntFloor = df2$interest[nrow(df2)]
bestSpendrateIntCeil = df2$intceil[nrow(df2)]
bestBenefit = df2$benefit[nrow(df2)]

# TODO multiaccount: all of the below
write(bestSpendrateROI,
      file="purchaser/state/EXAMPLEACCOUNT/curSpendrateExpectedROI.txt")
write(bestSpendrateFrac,
      file="purchaser/state/EXAMPLEACCOUNT/curSpendrateExpectedFractaken.txt")
write(bestSpendrateProbBad,
      file="purchaser/state/EXAMPLEACCOUNT/probBadCutoff.txt")
write(bestSpendrateIntFloor,
      file="purchaser/state/EXAMPLEACCOUNT/interestFloor.txt")
write(bestSpendrateIntCeil,
      file="purchaser/state/EXAMPLEACCOUNT/interestCeiling.txt")
bestSpendrate_cash = spendrateForFrac(bestSpendrateFrac, cash_per_note)
write(bestSpendrate_cash,
      file="purchaser/state/EXAMPLEACCOUNT/curExpectedSpendrate.txt")
