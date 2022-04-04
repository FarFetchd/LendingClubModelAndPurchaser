setwd(sub("\"\n", "", sub(".*LOANSPATH=\"", "", readChar("/etc/profile", file.info("/etc/profile")$size))))

plot_investment_start_date_SIMPLE <- function(inCSV, outPNG, useStartDate)
{
  df <- read.csv(inCSV, h=T, stringsAsFactors=F)
  df$date <- as.Date(df$date)
  # Compute each days cumulative fees: today's cumulative fees
  # divided by when the day in question was (normalized to 0,1 for start,now)
  startDate = min(df$date)
  endDate = max(df$date)
  periodDuration = as.numeric(endDate - startDate)
  df$days_since_start = as.numeric(df$date - startDate)
  endCumFees = sum(df$mthly_fees / 30.0)
  df$cumFees = endCumFees * (df$days_since_start / periodDuration)
  #===========================================================================

  df$gain_over_current <- df$cur_invested + df$gain
  df$goc_after_fees = df$gain_over_current - df$cumFees
  df$gain_less_fees = df$gain - df$cumFees

  # Zoom in to useStartDate and on
# TODO I THINK DONT WANT THIS NOW THAT I HAVE THE BETTER ESTIMATION  df = subset(df, date >= useStartDate)

  minG = min(df$gain_over_current, df$goc_after_fees)
  minC = min(df$cur_invested)
  maxG = max(df$gain_over_current, df$goc_after_fees)
  maxC = max(df$cur_invested)

  png(outPNG)
  plot(df$date, df$cur_invested, type = "l", col ="black",
       # Zoom in to useStartDate and on
       xlim=c(max(useStartDate, min(df$date)),max(df$date)),
       ylim=c(min(minC,minG),max(maxC,maxG)))
  points(df$date, df$gain_over_current, type = "l", col = "green")
  points(df$date, df$goc_after_fees, type = "l", col = "red")
  dev.off()

  write_nar_csv_SIMPLE(df, gsub(".png", "_NAR.csv", outPNG))
}

write_nar_csv_SIMPLE <- function(df, outCSV)
{
  df$cum_dollardays = 0
  df$return_per_dollaryear_derivative_ewma = 0
  df$return_per_dollaryear = 0
  for (i in seq(2, nrow(df)))
  {
    cur_dur = as.numeric(df$date[i] - df$date[i-1])

    # add in the trapezoid: square plus triangle
    if (cur_dur < 100) # days
    {
      triangle_base = min(df$cur_invested[i], df$cur_invested[i-1])
      triangle_top = max(df$cur_invested[i], df$cur_invested[i-1])
      df$cum_dollardays[i] = df$cum_dollardays[i-1] + triangle_base * cur_dur
                                                    + (triangle_top - triangle_base) * cur_dur * 0.5
    }
    else
    {
      # ACTUALLY NO... that is a nice clean way to interpolate, but it's not accurate for the big starting gaps
      # in the 2017 and 2018 data. For them, better to just assume cur_invested immediately jumped to the current level.
      df$cum_dollardays[i] = df$cum_dollardays[i-1] + cur_dur * df$cur_invested[i]
    }

    cur_dollardays = df$cum_dollardays[i] - df$cum_dollardays[i-1]
    if (cur_dollardays > 0)
    {
      cur_gain = df$gain_less_fees[i] - df$gain_less_fees[i-1]
      cur_gain_per_dollaryear = 365 * cur_gain / cur_dollardays
      df$return_per_dollaryear_derivative_ewma[i] = 0.97*df$return_per_dollaryear_derivative_ewma[i-1] +
                                                    0.03*cur_gain_per_dollaryear
    }
    else
    {
      df$return_per_dollaryear_derivative_ewma[i] = df$return_per_dollaryear_derivative_ewma[i-1]
    }

    df$return_per_dollaryear[i] = 365 * (df$gain_less_fees[i] / df$cum_dollardays[i])
    # HACK
    df$return_per_dollaryear[i] = min(0.15, df$return_per_dollaryear[i])
    df$return_per_dollaryear[i] = max(-0.02, df$return_per_dollaryear[i])
  }

  write.csv(df, outCSV, row.names=F)
}

prepare_df_for_agg_gain_per_dollaryear <- function(inCSV)
{
  df <- read.csv(inCSV, h=T, stringsAsFactors=F)
  df$date <- as.Date(df$date)
  startDate = min(df$date)
  endDate = max(df$date)
  periodDuration = as.numeric(endDate - startDate)
  df$days_since_start = as.numeric(df$date - startDate)
  endCumFees = sum(df$mthly_fees / 30.0)
  df$cumFees = endCumFees * (df$days_since_start / periodDuration)
  df$gain_less_fees = df$gain - df$cumFees
  return(df)
}

plot_since_v4_gain_per_dollaryear <- function()
{
  df1 = prepare_df_for_agg_gain_per_dollaryear("monitor/data/RFv4July2018_PERFORMANCE.csv")
  df2 = prepare_df_for_agg_gain_per_dollaryear("monitor/data/RFv4.3Mar2019_PERFORMANCE.csv")
  df3 = prepare_df_for_agg_gain_per_dollaryear("monitor/data/investment_chart_2019XGBv1_NAR.csv")

  df1$cum_dollardays = 0
  for (i in seq(2, nrow(df1)))
  {
    cur_dur = as.numeric(df1$date[i] - df1$date[i-1])
    # add in the trapezoid: square plus triangle
    triangle_base = min(df1$cur_invested[i], df1$cur_invested[i-1])
    triangle_top = max(df1$cur_invested[i], df1$cur_invested[i-1])
    df1$cum_dollardays[i] = df1$cum_dollardays[i-1] + triangle_base * cur_dur
                                                    + (triangle_top - triangle_base) * cur_dur * 0.5
  }
  df2$cum_dollardays = 0
  for (i in seq(2, nrow(df2)))
  {
    cur_dur = as.numeric(df2$date[i] - df2$date[i-1])
    # add in the trapezoid: square plus triangle
    triangle_base = min(df2$cur_invested[i], df2$cur_invested[i-1])
    triangle_top = max(df2$cur_invested[i], df2$cur_invested[i-1])
    df2$cum_dollardays[i] = df2$cum_dollardays[i-1] + triangle_base * cur_dur
                                                    + (triangle_top - triangle_base) * cur_dur * 0.5
  }
  df3$cum_dollardays = 0
  for (i in seq(2, nrow(df3)))
  {
    cur_dur = as.numeric(df3$date[i] - df3$date[i-1])
    # add in the trapezoid: square plus triangle
    triangle_base = min(df3$cur_invested[i], df3$cur_invested[i-1])
    triangle_top = max(df3$cur_invested[i], df3$cur_invested[i-1])
    df3$cum_dollardays[i] = df3$cum_dollardays[i-1] + triangle_base * cur_dur
                                                    + (triangle_top - triangle_base) * cur_dur * 0.5
  }

  i1 = which(df1$date == df3$date[1])[1]
  i2 = which(df2$date == df3$date[1])[1]
  df3$return_per_dollaryear = 0
  for (i3 in seq(1, nrow(df3)))
  {
    df3$cum_dollardays[i3] = df3$cum_dollardays[i3] + df2$cum_dollardays[i2] + df1$cum_dollardays[i1]
    df3$gain_less_fees[i3] = df3$gain_less_fees[i3] + df2$gain_less_fees[i2] + df1$gain_less_fees[i1]
    i2 = i2 + 1
    i1 = i1 + 1
    df3$return_per_dollaryear[i3] = 365 * (df3$gain_less_fees[i3] / df3$cum_dollardays[i3])
  }

  png("monitor/plot_since_v4_gain_per_dollaryear.png")
  plot(df3$date, df3$return_per_dollaryear, type = "l", col ="blue",
       # Zoom in to useStartDate and on
       xlim=c(min(df3$date),max(df3$date)),
       ylim=c(0,0.16))
  dev.off()
}


plot_gain_start_date <- function(inCSV, outPNG, useStartDate)
{
  df <- read.csv(inCSV, h=T, stringsAsFactors=F)
  df$date <- as.Date(df$date)
  # Compute each days cumulative fees: today's cumulative fees
  # divided by when the day in question was (normalized to 0,1 for start,now)
  startDate = min(df$date)
  endDate = max(df$date)
  periodDuration = as.numeric(endDate - startDate)
  df$days_since_start = as.numeric(df$date - startDate)
  endCumFees = sum(df$mthly_fees / 30.0)
  df$cumFees = endCumFees * (df$days_since_start / periodDuration)
  #===========================================================================

  df$gain_after_fees = df$gain - df$cumFees

  # Zoom in to useStartDate and on
  df = subset(df, date >= useStartDate)

  minG = min(df$gain, df$gain_after_fees)
  maxG = max(df$gain, df$gain_after_fees)
  png(outPNG)
  plot(df$date, df$gain, type = "l", col ="black",
       # Zoom in to useStartDate and on
       xlim=c(max(useStartDate, min(df$date)),max(df$date)),
       ylim=c(minG,maxG))
  points(df$date, df$gain_after_fees, type = "l", col = "red")
  dev.off()
}

plot_cash_available <- function(inCSV, outPNG, outPNG3mo)
{
  df <- read.csv(inCSV, h=T, stringsAsFactors=F)
  df$date <- as.Date(df$date)
  minA = min(df$available)
  maxA = max(df$available)
  png(outPNG)
  plot(df$date, df$available, type = "l", col = "black",
       ylim=c(minA, maxA))
  dev.off()
  png(outPNG3mo)
  df3 = subset(df, date >= max(df$date) - 60)
  minA = min(df3$available)
  maxA = max(df3$available)
  plot(df3$date, df3$available, type = "l", col = "black",
       ylim=c(minA, maxA))
  dev.off()
}

# e.g. "2005-05-05" would use earliest date in the data as start date.
# However, I already decided I want all of these at at least "2018-05-01".
plot_investment_SIMPLE <- function(inCSV, outPNG)
{
  plot_investment_start_date_SIMPLE(inCSV, outPNG, as.Date("2018-05-01"))
}
plot_gain <- function(inCSV, outPNG)
{
  plot_gain_start_date(inCSV, outPNG, as.Date("2018-05-01"))
}

plot_investment_SIMPLE("monitor/data/RF2016_aggregate_PERFORMANCE.csv",
                "monitor/data/investment_chart_2016originations.png")
plot_investment_SIMPLE("monitor/data/RFv3_2017_PERFORMANCE.csv",
                "monitor/data/investment_chart_2017originations.png")
plot_investment_SIMPLE("monitor/data/RFv3_2018conservative_PERFORMANCE.csv",
                "monitor/data/investment_chart_2018RFv3Conservative.png")
plot_investment_start_date_SIMPLE("monitor/data/RFv4July2018_PERFORMANCE.csv",
                                  "monitor/data/investment_chart_2018RFv4.png",
                                  as.Date("2018-09-05"))
plot_investment_start_date_SIMPLE("monitor/data/RFv4.3Mar2019_PERFORMANCE.csv",
                                  "monitor/data/investment_chart_2019RFv4.3.png",
                                  as.Date("2019-04-20"))
plot_investment_start_date_SIMPLE("monitor/data/XGBv1Sep2019_PERFORMANCE.csv",
                                  "monitor/data/investment_chart_2019XGBv1.png",
                                  as.Date("2019-10-25"))
plot_investment_start_date_SIMPLE("monitor/data/XGBv1.1May2020_PERFORMANCE.csv",
                                  "monitor/data/investment_chart_2020XGBv1.1.png",
                                  as.Date("2020-05-25"))
print("now plotting gain")

plot_gain("monitor/data/RF2016_aggregate_PERFORMANCE.csv",
          "monitor/gain_chart_2016originations.png")
plot_gain("monitor/data/RFv3_2017_PERFORMANCE.csv",
          "monitor/gain_chart_2017originations.png")
plot_gain("monitor/data/RFv3_2018conservative_PERFORMANCE.csv",
          "monitor/gain_chart_2018RFv3Conservative.png")
plot_gain_start_date("monitor/data/RFv4July2018_PERFORMANCE.csv",
                     "monitor/gain_chart_2018RFv4.png",
                     as.Date("2018-09-05"))
plot_gain_start_date("monitor/data/RFv4.3Mar2019_PERFORMANCE.csv",
                     "monitor/gain_chart_2019RFv4.3.png",
                     as.Date("2019-04-20"))
plot_gain_start_date("monitor/data/XGBv1Sep2019_PERFORMANCE.csv",
                     "monitor/gain_chart_2019XGBv1.png",
                     as.Date("2019-10-25"))
plot_gain_start_date("monitor/data/XGBv1.1May2020_PERFORMANCE.csv",
                     "monitor/gain_chart_2020XGBv1.1.png",
                     as.Date("2020-05-25"))

plot_cash_available("monitor/data/available_cash.csv",
                    "monitor/available.png",
                    "monitor/available_zoom3month.png")

print("now plotting return")

#==============Plot return_per_dollaryear (used to be NAR) from all of the generated NAR CSVs======================
df2016 <- read.csv("monitor/data/investment_chart_2016originations_NAR.csv",
                   h=T, stringsAsFactors=F)
df2017 <- read.csv("monitor/data/investment_chart_2017originations_NAR.csv",
                   h=T, stringsAsFactors=F)
df2018v3 <- read.csv("monitor/data/investment_chart_2018RFv3Conservative_NAR.csv",
                     h=T, stringsAsFactors=F)
df2018v4 <- read.csv("monitor/data/investment_chart_2018RFv4_NAR.csv",
                     h=T, stringsAsFactors=F)
df2019v43 <- read.csv("monitor/data/investment_chart_2019RFv4.3_NAR.csv",
                      h=T, stringsAsFactors=F)
df2019xbg <- read.csv("monitor/data/investment_chart_2019XGBv1_NAR.csv",
                      h=T, stringsAsFactors=F)
df2020xbg <- read.csv("monitor/data/investment_chart_2020XGBv1.1_NAR.csv",
                      h=T, stringsAsFactors=F)
png("monitor/net_annualized_roi_after_fees.png")
  xmin = min(df2017$weighted_age_days, df2018v3$weighted_age_days, df2018v4$weighted_age_days, df2019v43$weighted_age_days)
  xmax = max(df2017$weighted_age_days, df2018v3$weighted_age_days, df2018v4$weighted_age_days, df2019v43$weighted_age_days)
  ymin = min(df2017$return_per_dollaryear, df2018v3$return_per_dollaryear,
             df2018v4$return_per_dollaryear, df2019v43$return_per_dollaryear)
  ymax = max(df2017$return_per_dollaryear, df2018v3$return_per_dollaryear,
             df2018v4$return_per_dollaryear, df2019v43$return_per_dollaryear)
  # doesnt have weighted_age_days plot(df2016$weighted_age_days, df2016$return_per_dollaryear, col ="red")
  plot(df2017$weighted_age_days, df2017$return_per_dollaryear, col = "black",
       xlim=c(xmin, xmax), ylim=c(0.04, ymax))
  points(df2018v3$weighted_age_days, df2018v3$return_per_dollaryear, col = "green")
  points(df2018v4$weighted_age_days, df2018v4$return_per_dollaryear, col = "blue")
  points(df2019v43$weighted_age_days, df2019v43$return_per_dollaryear, col = "purple")
  points(df2019xbg$weighted_age_days, df2019xbg$return_per_dollaryear, col = "orange")
  points(df2020xbg$weighted_age_days, df2020xbg$return_per_dollaryear, col = "red")
dev.off()
#=============all NAR plots now plotted=====================================

print("now plotting return instantaneous")

#==============Plot return_per_dollaryear DERIVATIVE from all of the generated NAR CSVs======================
png("monitor/net_annualized_roi_after_fees_DERIVATIVE.png")
  xmin = min(df2017$weighted_age_days, df2018v3$weighted_age_days, df2018v4$weighted_age_days, df2019v43$weighted_age_days)
  xmax = max(df2017$weighted_age_days, df2018v3$weighted_age_days, df2018v4$weighted_age_days, df2019v43$weighted_age_days)
  ymin = min(df2017$return_per_dollaryear_derivative_ewma, df2018v3$return_per_dollaryear_derivative_ewma,
             df2018v4$return_per_dollaryear_derivative_ewma, df2019v43$return_per_dollaryear_derivative_ewma)
  ymax = max(df2017$return_per_dollaryear_derivative_ewma, df2018v3$return_per_dollaryear_derivative_ewma,
             df2018v4$return_per_dollaryear_derivative_ewma, df2019v43$return_per_dollaryear_derivative_ewma)
  # doesnt have weighted_age_days plot(df2016$weighted_age_days, df2016$return_per_dollaryear_derivative_ewma, col ="red")
  plot(df2017$weighted_age_days, df2017$return_per_dollaryear_derivative_ewma, col = "black",
       xlim=c(xmin, xmax), ylim=c(ymin, 0.2))
  points(df2018v3$weighted_age_days, df2018v3$return_per_dollaryear_derivative_ewma, col = "green")
  points(df2018v4$weighted_age_days, df2018v4$return_per_dollaryear_derivative_ewma, col = "blue")
  points(df2019v43$weighted_age_days, df2019v43$return_per_dollaryear_derivative_ewma, col = "purple")
  points(df2019xbg$weighted_age_days, df2019xbg$return_per_dollaryear_derivative_ewma, col = "orange")
  points(df2020xbg$weighted_age_days, df2020xbg$return_per_dollaryear_derivative_ewma, col = "red")
dev.off()
#=============all NAR plots now plotted=====================================

print("done plotting return instantaneous")

#===============plot weighted age vs chargeoffs=============================
df1 <- read.csv("monitor/data/RFv3_2017_CHARGEOFFS.csv", h=T, stringsAsFactors=F)
df2 <- read.csv("monitor/data/RFv3_2018conservative_CHARGEOFFS.csv", h=T, stringsAsFactors=F)
df3 <- read.csv("monitor/data/RFv4July2018_CHARGEOFFS.csv", h=T, stringsAsFactors=F)
df4 <- read.csv("monitor/data/RFv4.3Mar2019_CHARGEOFFS.csv", h=T, stringsAsFactors=F)
df5 <- read.csv("monitor/data/XGBv1Sep2019_CHARGEOFFS.csv", h=T, stringsAsFactors=F)
df6 <- read.csv("monitor/data/XGBv1.1May2020_CHARGEOFFS.csv", h=T, stringsAsFactors=F)
png("monitor/chargeoff_fracs_combined.png")
  xmax = max(df1$weighted_age_days, df2$weighted_age_days, df3$weighted_age_days, df4$weighted_age_days)
  plot(df1$weighted_age_days, df1$frac_charged_off, col = "black",
       xlim=c(90, xmax), ylim=c(0, 0.3))
  points(df2$weighted_age_days, df2$frac_charged_off, col = "green")
  points(df3$weighted_age_days, df3$frac_charged_off, col = "blue")
  points(df4$weighted_age_days, df4$frac_charged_off, col = "purple")
  points(df5$weighted_age_days, df5$frac_charged_off, col = "orange")
  points(df6$weighted_age_days, df6$frac_charged_off, col = "red")
dev.off()
#===============weighted age vs chargeoffs now plotted======================

plot_since_v4_gain_per_dollaryear()

#====================total account value over time==========================
accval=read.csv("monitor/data/account_val_history.csv", h=T, stringsAsFactors=F)
accval$date = as.Date(accval$date)
png("monitor/account_val_history.png")
  plot(accval$date, accval$account_value, type = "l", col = "black",
       xlim=c(as.Date("2020-09-01"), max(accval$date)),
       ylim=c(min(accval$account_value), max(accval$account_value)))
dev.off()
