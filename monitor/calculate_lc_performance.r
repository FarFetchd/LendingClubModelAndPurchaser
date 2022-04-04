setwd(sub("\"\n", "", sub(".*LOANSPATH=\"", "", readChar("/etc/profile", file.info("/etc/profile")$size))))

report_portfolio <- function(x,portfolio_name)
{
  cur <- x[which(x$PORTFOLIO_NAME==portfolio_name),]

  value_recvd <- cur$PRINCIPAL_RECEIVED+cur$INTEREST_RECEIVED
  value_pending <- cur$PRINCIPAL_PENDING+(cur$ACCRUED_INTEREST-cur$INTEREST_PENDING)

  indgd <- which(cur$LOAN_STATUS=="Current" | cur$LOAN_STATUS=="Fully Paid")
  indgr <- which(cur$LOAN_STATUS=="In Grace Period")
  ind30 <- which(cur$LOAN_STATUS=="Late (16-30 days)")
  ind120 <- which(cur$LOAN_STATUS=="Late (31-120 days)")
  inddf <- which(cur$LOAN_STATUS=="Default")
  indco <- which(cur$LOAN_STATUS=="Charged Off")

  valgd <- sum(value_recvd[indgd] + value_pending[indgd])
  valgr <- sum(value_recvd[indgr] + 0.73 * value_pending[indgr])
  val30 <- sum(value_recvd[ind30] + 0.43 * value_pending[ind30])
  val120 <- sum(value_recvd[ind120] + 0.17 * value_pending[ind120])
  valdf <- sum(value_recvd[inddf] + 0.12 * value_pending[inddf])
  valco <- sum(value_recvd[indco])

  idxPaying <- which(cur$LOAN_STATUS=="Current" | cur$LOAN_STATUS=="In Grace Period" |
                     cur$LOAN_STATUS=="Late (16-30 days)")
  if(nrow(cur) == 0)
  {
    return(list(cur_invested=0, total_invested=0, value=0, gain=0,
                monthly_fees=0, weighted_age_days=0))
  }
  cur$monthly_payment <- 0
  #cur$monthly_payment[which(cur$LOAN_STATUS=="Fully Paid" | cur$LOAN_STATUS=="Charged Off" |
  #                        cur$LOAN_STATUS=="Default" | cur$LOAN_STATUS=="Late (31-120 days)")]<-0
  cur$mth_int <- (cur$INTEREST_RATE / 100) / 12
  cur$monthly_payment[idxPaying] <-
           cur$NOTE_AMOUNT[idxPaying] /
      ( ((1+cur$mth_int[idxPaying])^36 - 1)
                        /
   (cur$mth_int[idxPaying] * (1+cur$mth_int[idxPaying])^36)  )
  cur$monthly_fee <- 0.01 * cur$monthly_payment

  # CURRENTLY invested. Will eventually go to 0.
  cur_invested <- sum(cur$NOTE_AMOUNT - cur$PRINCIPAL_RECEIVED)
  cur_invested <- cur_invested - sum(ifelse(cur$LOAN_STATUS=="Charged Off",
                                            cur$PRINCIPAL_PENDING, 0))
  # TOTAL invested, double-counting paid off principal reinvested in same portfolio.
  total_invested <- sum(cur$NOTE_AMOUNT)
  value <- valgd + valgr + val30 + val120 + valdf + valco
  gain <- value - total_invested
  cur$NEXT_PAYMENT_DATE <- substr(cur$NEXT_PAYMENT_DATE, 1, 10)
  cur$ISSUE_DATE <- substr(cur$ISSUE_DATE, 1, 10)
  cur$duration_years <- as.numeric(as.Date(cur$NEXT_PAYMENT_DATE) -
                                   as.Date(cur$ISSUE_DATE)) / 365.25
  monthly_fees <- sum(cur$monthly_fee)

  cur$ISSUE_DATE <- as.Date(substr(cur$ISSUE_DATE, 1, 10))
  endDate <- Sys.Date()
  cur$age_days <- as.numeric(endDate - cur$ISSUE_DATE)
  cur$weighted_age_days <- cur$age_days * cur$NOTE_AMOUNT
  no_NA_please <- na.omit(cur)
  no_NA_please <- subset(no_NA_please, NOTE_AMOUNT > 0)
  weighted_age_days <- sum(no_NA_please$weighted_age_days) / sum(no_NA_please$NOTE_AMOUNT)

  return(list(cur_invested=cur_invested, total_invested=total_invested, value=value, gain=gain,
         monthly_fees=monthly_fees, weighted_age_days=weighted_age_days))
}

fixIfBad = function(filename)
{
  cur = read.csv(filename, h=T, stringsAsFactors=F)
  if (nrow(cur) > 10)
  {
    needWrite = FALSE
    for (i2 in seq(nrow(cur)-10, nrow(cur)))
    {
      i1 = i2-1
      value_diff_rounded = 50*round(cur$value[i2]/50 - cur$value[i1]/50)
      if (cur$total_invested[i2] - cur$total_invested[i1] > value_diff_rounded)
      {
        offset_val = (cur$total_invested[i2] - cur$total_invested[i1]) - value_diff_rounded
        cur$value[i2] = cur$value[i2] + offset_val
        cur$gain[i2] = cur$gain[i2] + offset_val
        needWrite = TRUE
      }
    }
    if (needWrite)
      write.csv(cur, filename, row.names=F)
  }
}

recordChargeoffRate = function(x, portfolio_name, weighted_age_days)
{
  filename_chargeoff = paste0("monitor/data/",
                              portfolio_name,"_CHARGEOFFS.csv")

  bad = subset(x, LOAN_STATUS=="Late (31-120 days)" | LOAN_STATUS=="Default" | LOAN_STATUS=="Charged Off")
  bad_this=nrow(subset(bad, PORTFOLIO_NAME==portfolio_name))
  all_this=nrow(subset(x, PORTFOLIO_NAME==portfolio_name))
  frac_this=bad_this/all_this

  cat(paste0(Sys.Date(),",",
             round(weighted_age_days, digits=1),",",
             bad_this,",",
             all_this,",",
             round(frac_this, digits=4)),
      file=filename_chargeoff, sep="\n", append=T)
}

recentCashOutflow = function()
{
  df = read.csv("monitor/data/spent.csv", h=T)
  df$date = as.Date(df$date)
  available = read.csv("monitor/data/available_cash.csv", h=T)
  available$date = as.Date(available$date)

  end_date = Sys.Date() - 1
  while (length(which(df$date == end_date)) == 0 | length(which(available$date == end_date)) == 0)
  {
    end_date = end_date - 1
  }
  start_date = end_date - 30
  while (length(which(df$date == start_date)) == 0 | length(which(available$date == start_date)) == 0)
  {
    start_date = start_date - 1
  }
  total_spent = sum(df$spent[which(df$date >= start_date & df$date <= end_date)])
  avail_start = mean(available$available[which(available$date == start_date)])
  avail_end = mean(available$available[which(available$date == end_date)])
  return (((avail_end - avail_start) + total_spent) / as.numeric(end_date - start_date))
}




x <- read.csv("monitor/today_performance.csv",
              h=T, stringsAsFactors=F)
# Filter those with an empty or otherwise malformed ISSUE_DATE
x=x[which(nchar(x$ISSUE_DATE)>=8),]

x$GRADE<-NULL
x$CURRENT_PAYMENT_STATUS<-NULL
x$ORDER_ID<-NULL
x$LOAN_AMOUNT<-NULL
x$CAN_BE_TRADED<-NULL
x$PURPOSE<-NULL
x$APPLICATION_TYPE<-NULL
x$DISBURSEMENT_METHOD<-NULL
x$LOAN_STATUS_DATE<-NULL
x$NOTE_ID<-NULL
x$STATUS_DATE<-NULL
x$LOAN_ID<-NULL
x$PRINCIPAL_REMAINING<-NULL
x$ORDER_DATE<-NULL
x$INVESTED<-NULL
x$CREDIT_TREND<-NULL

total_cur_invested = 0

portfolio_names<-c(
    "earlySep2016Data", "july2016data", "july2016fastInvest", "ManualTest",
    "nov2016data", "nov2016updatedDates", "RandomForestv1", "RandomForestv2ZIP",
    "RandomForestv3Reality", "RFJune2016Data", "RFv3_2017", "RFv3_2018conservative",
    "RFv3GoodQueryTiming", "RFv3GQTDoubled", "RFv3Jun2016Rates", "RFv3Oct2016",
    "RFv4July2018", "RFv4.3Mar2019", "XGBv1Sep2019", "XGBv1.1May2020")
for(i in 1:length(portfolio_names))
{
  filename = paste0("monitor/data/",
                    portfolio_names[i],"_PERFORMANCE.csv")
  res <- report_portfolio(x, portfolio_names[i])
  cat(paste0(Sys.Date(),",",
             res$cur_invested,",",
             res$total_invested,",",
             res$value,",",
             res$gain,",",
             res$monthly_fees,",",
             res$weighted_age_days), #,",",
      file=filename, sep="\n", append=T)
  fixIfBad(filename)

  if (portfolio_names[i] == "RFv3_2017" |
      portfolio_names[i] == "RFv3_2018conservative" |
      portfolio_names[i] == "RFv4July2018" |
      portfolio_names[i] == "RFv4.3Mar2019" |
      portfolio_names[i] == "XGBv1Sep2019" |
      portfolio_names[i] == "XGBv1.1May2020")
  {
    recordChargeoffRate(x, portfolio_names[i], res$weighted_age_days)
  }
  total_cur_invested = total_cur_invested + res$cur_invested
}

# TODO multiaccount
write(total_cur_invested, "purchaser/state/EXAMPLEACCOUNT/totalCurInvested.txt")
source("monitor/aggregate2016.R")

write(recentCashOutflow(), "monitor/recent_outflow.txt")
hmm = read.csv("monitor/data/available_cash.csv", h=T)
hmm$date = as.Date(hmm$date)
avail = mean(hmm$available[which(hmm$date >= max(hmm$date))])
write(avail, "monitor/cur_available_cash.txt")
write(total_cur_invested + avail, "monitor/account_value_minus_inFunding.txt")
