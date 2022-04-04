library(stringr)
library(Rcpp)

setwd(sub("\"\n", "", sub(".*LOANSPATH=\"", "", readChar("/etc/profile", file.info("/etc/profile")$size))))

sourceCpp("purchaser/textscore/MySpell-3.0/unholyjob.cpp")

printf <- function(...) invisible(print(sprintf(...)))

# An estimate of effective total tax rate on interest income.
EFFECTIVE_TAX_RATE = 0.1

############################################
#NOTE: the data update scripts now depend on this variable in this file being
#      set to cleaned_historical.csv. If you are playing around with data in
#      a file with a different name, be sure to set it back afterwards.
loanDataFilename <- "cleaned_historical.csv"
############################################

print(paste0("Now reading ",loanDataFilename,"..."))
df <- read.csv(loanDataFilename, h=T, stringsAsFactors=F)
print(paste0("Done reading ",loanDataFilename,
             ", now processing..."))

# Remove NA-prone columns, and rows with important values NA
poor_coverage <- (is.na(df$LOAN_AMOUNT) |
is.na(df$TERM) |
is.na(df$INTEREST_RATE) |
is.na(df$INSTALLMENT) |
is.na(df$INQUIRIES_IN_LAST_6_MONTHS) |
is.na(df$PUB_REC_BANKRUPTCIES) |
is.na(df$TAX_LIENS))
df <- df[which(poor_coverage==FALSE),]
remove('poor_coverage')
df[,'open_acc_6m'] <- NULL
df[,'open_act_il'] <- NULL
df[,'annual_inc_joint'] <- NULL
df[,'dti_joint'] <- NULL
df[,'mths_since_last_record'] <- NULL

df$EMPLOYMENT_LENGTH[which(is.na(df$EMPLOYMENT_LENGTH))] <- -1

df$issue_d <- as.Date(df$issue_d)
df$last_pymnt_d <- as.Date(df$last_pymnt_d)

#df$year_issued <- year(df$issue_d)
#df$month_issued <- month(df$issue_d)
# A significant jump in defaults happened around here.
# With data so recent, 60 month can no longer be trained on.
print(paste0(nrow(df)," rows including pre-2014 and 60months"))
df <- subset(df, issue_d > "2014-09-01" & TERM < 60)
print(paste0(nrow(df)," rows EXcluding pre-2014 and 60months"))

#restrict to any finished loan:
df <- subset(df, loan_status != "")
df <- subset(df, loan_status %in% c("Late (31-120 days)", "Default",
                                    "Charged Off", "Fully Paid"))
print(paste0(nrow(df)," loans are bad or finished"))

# Huh? how does principal grow? It's not people being late; almost
# all are fully paid, with no late fees received.
df <- subset(df, LOAN_AMOUNT >= out_prncp)
# Some PUB_REC_DEROGs are a weird %. ever_120_pd should be a good proxy.
idx<-which(grepl("%", df$PUB_REC_DEROG)==TRUE)
df$PUB_REC_DEROG[idx]<-df$num_accts_ever_120_pd[idx]
df$PUB_REC_DEROG <- as.numeric(df$PUB_REC_DEROG)
df <- subset(df, is.na(PUB_REC_DEROG) == FALSE)
print(paste0(nrow(df)," rows after removing weird % PUB_REC_DEROG"))

df$ANNUAL_INCOME_VERIFIED <- factor(df$ANNUAL_INCOME_VERIFIED)
df$HOME_OWNERSHIP <- factor(df$HOME_OWNERSHIP)
# There are a few weird ones: ANY and NONE
df <- subset(df, HOME_OWNERSHIP=="RENT" | HOME_OWNERSHIP=="OWN" | HOME_OWNERSHIP=="MORTGAGE")
df$is_rent <- df$HOME_OWNERSHIP=="RENT"
df$rent_own_mort <- factor(df$HOME_OWNERSHIP)

# I suspect these rows have a missing column; they also all have like 20000 bankruptcies...
df <- subset(df, application_type=="Individual" | application_type=="Joint App")

zip_to_gps <- read.csv("purchaser/zipXX_latlon.csv")
df$longitude <- zip_to_gps$meanlons[match(df$ADDRESS_ZIP, zip_to_gps$zip_1st3)]
df$latitude <- zip_to_gps$meanlats[match(df$ADDRESS_ZIP, zip_to_gps$zip_1st3)]
missing_latlon <- (is.na(df$longitude) | is.na(df$latitude))
df <- df[which(missing_latlon==FALSE),]
print(paste0(nrow(df)," rows after removing missing latlon"))

# 500k is 99.9th percentile, let's not get crazy skewed.
df$ANNUAL_INCOME <- ifelse(df$ANNUAL_INCOME < 500000, df$ANNUAL_INCOME, 500000)

# It's a little roundabout, since we no longer use the Zillow data,
# but let's remove the weirdo outliers (mostly overseas military bases).
zip_to_expenses <- read.csv("rent_to_pt_by_shortzip.csv")
missing_zip <- setdiff(unique(df$ADDRESS_ZIP), zip_to_expenses$RegionName)
df <- subset(df, !(ADDRESS_ZIP %in% missing_zip))
print(paste0(nrow(df)," rows after removing ZIPs missing from Zillow"))

# :( apparently this feature is just awful. Oh well, it was fun collecting it...
df$living_expenses = 0
idx <- which(df$HOME_OWNERSHIP=="RENT")
df$living_expenses[idx] <-
    zip_to_expenses$zillow_rent_zri[match(df$ADDRESS_ZIP[idx],
                                          zip_to_expenses$RegionName)]
idx <- which(df$HOME_OWNERSHIP=="MORTGAGE")
df$living_expenses[idx] <-
    zip_to_expenses$zillow_rent_zri[match(df$ADDRESS_ZIP[idx],
                                          zip_to_expenses$RegionName)] +
    (zip_to_expenses$yearly_pt[match(df$ADDRESS_ZIP[idx],
                                     zip_to_expenses$RegionName)]/12)
idx <- which(df$HOME_OWNERSHIP=="OWN")
df$living_expenses[idx] <-
    zip_to_expenses$yearly_pt[match(df$ADDRESS_ZIP[idx],
                                    zip_to_expenses$RegionName)]/12


df$DEBT_TO_INCOME_RATIO <- as.numeric(df$DEBT_TO_INCOME_RATIO)
df$dti_frac <- df$DEBT_TO_INCOME_RATIO / 100.0
# Monthly payments on NON-LC loans, derived from DTI
df$other_loan_installment <- df$dti_frac * (df$ANNUAL_INCOME / 12)
# Monthly income net of all loan payments. Don't double count refinancing people.
df$after_loan_monthly_income <- ifelse(
    df$purpose=="credit_card" | df$purpose=="debt_consolidation",
    df$ANNUAL_INCOME / 12 - (df$other_loan_installment),
    df$ANNUAL_INCOME / 12 - (df$INSTALLMENT + df$other_loan_installment))
# Also net of cost of living estimated for their ZIP code.
# :( apparently this feature is just awful. Oh well, it was fun collecting it...
df$after_expense_monthly_income <- ifelse(
    df$purpose=="credit_card" | df$purpose=="debt_consolidation",
    df$ANNUAL_INCOME / 12 - (df$other_loan_installment + df$living_expenses),
    df$ANNUAL_INCOME / 12 - (df$INSTALLMENT + df$other_loan_installment + df$living_expenses))
print(paste0(nrow(df)," rows before removing missing monthly income"))
df <- subset(df, is.na(after_loan_monthly_income)==FALSE)
print(paste0(nrow(df)," rows after removing missing monthly income"))

# TONOTDO: filtering, where we say "bankruptcies? NOPE" and either override the
#          model on such loans, OR not even include them in training. Turns out
#          to not be helpful at all, and is in fact a tiny bit counterproductive.

# Negative? lol wut
df <- subset(df, dti_frac >= 0)
# Weird outliers. (Like 30 of them).
df <- subset(df, dti_frac < 2)

df$jobtitlegood <- factor(properjobtitledev(df$EMP_TITLE))

# Based on 2010 census data and number of flood insurance claims starting 2010, how many flood claims per person in each ZIP?
floodclaims = read.csv("floodclaims_per_person_by_ZCTA.csv", h=T, stringsAsFactors=F)
df$floodclaims_per_person = 999
for(zip in floodclaims$zip)
{
  df$floodclaims_per_person[which(df$ADDRESS_ZIP==zip)] = floodclaims$floodclaims_per_person[which(floodclaims$zip==zip)]
}
# fill in missing data
df$floodclaims_per_person[which(df$floodclaims_per_person==999)] = 0.0003759 # median


df$REVOLVING_UTILIZATION <- ifelse(df$REVOLVING_UTILIZATION < 100, df$REVOLVING_UTILIZATION, 100)
df$bc_util <- ifelse(is.na(df$bc_util), 0, df$bc_util)
df$bc_util <- ifelse(df$bc_util < 100, df$bc_util, 100)
#df$REVOLVING_UTILIZATION <- ifelse(df$REVOLVING_UTILIZATION > df$bc_util, df$REVOLVING_UTILIZATION, df$bc_util)
df[,'bc_util'] <- NULL

# Forget temporary fields and variables
df[,'other_loan_installment'] <- NULL
# df[,'MTHS_SINCE_LAST_MAJOR_DEROG'] <- NULL
df[,'CHARGEOFF_WITHIN_12_MTHS'] <- NULL
#df[,'PUB_REC_BANKRUPTCIES'] <- NULL
df[,'TAX_LIENS'] <- NULL
df[,'collections_12_mths_ex_med'] <- NULL
#df[,'delinq_2yrs'] <- NULL
#df[,'acc_now_delinq'] <- NULL
df[,'mths_since_recent_revol_delinq'] <- NULL
df[,'mths_since_recent_bc_dlq'] <- NULL
#df[,'num_accts_ever_120_pd'] <- NULL
#df[,'HOME_OWNERSHIP'] <- NULL
#df[,'purpose'] <- NULL
remove('zip_to_gps', 'missing_latlon')

# Compute real historical returns. (Be sure to never use it as a feature, of course!)
df$DURATION_YEARS <- as.numeric(df$last_pymnt_d - df$issue_d) / 365.25
# no longer need last_pymnt_d, and its NAs will mess us up
df[,'last_pymnt_d'] <- NULL
df$DURATION_YEARS[which(is.na(df$DURATION_YEARS))] <- 0
df$DURATION_YEARS[which(df$DURATION_YEARS<=0)] <- 1/12
# A negative value means money lost.
chargeoff_losses <- -(df$LOAN_AMOUNT + df$collection_recovery_fee - df$total_pymnt)
# Some "bad" loans actually make gains: they defaulted after more than paying back the
#  principal. Annualize those gains.
df$realWriteoff <-
    ifelse(chargeoff_losses < 0,
           chargeoff_losses / df$LOAN_AMOUNT,
           (1 + chargeoff_losses / df$LOAN_AMOUNT)^(1 / df$DURATION_YEARS) - 1)
# Ridiculous tax owed on interest eaten by chargeoffs. Expressed as negative ROI percentage points.
df$chargeoff_tax_pctg_pts = ifelse(chargeoff_losses < 0,
                                   (chargeoff_losses / df$LOAN_AMOUNT) * EFFECTIVE_TAX_RATE,
                                   0)

df$is_bad <- ifelse(df$loan_status %in% c("Late (16-30 days)", "Late (31-120 days)",
                                          "Default", "Charged Off"),
                    1, 0)
#df$is_current <- ifelse(df$loan_status=="Current", 1, 0)
#df$is_done <- ifelse(df$loan_status=="Fully Paid", 1, 0)

df$realROI <- ifelse(df$is_bad == 1, df$realWriteoff, df$INTEREST_RATE) + df$chargeoff_tax_pctg_pts

# lol wut? One was 10919.367. WOULDNT IT BE NICE.
# ...furthermore, I'm not entirely sure what's going on with these "not too shabby ROI!" chargeoffs.
# There are only like 1k or 2k of them with ROI > 0.05, so just exclude them.
df <- subset(df, realROI < 0.3)
df <- subset(df,  is_bad==0 | (is_bad==1 & realWriteoff<0.05))

# Experimental: how much actually lost (0 if net gain, both for "good" chargeoffs and happy finished ones).
# Idea being, predict this value rather than probBad. Tried before, but I think I was predicting on actual
# ROI, not just "how much lost if any". (Expressed as positive; 0.1 means lost 10%).
df$realWriteoffClamped = max(df$realWriteoff, -1)
df$realWriteoffClamped = min(df$realWriteoffClamped, 0)
df$realWriteoffClamped = -df$realWriteoffClamped

# 1 or 0 zeros (e.g. $2750 or $2575). Counterintuitively (to me at least), these
# more specific loan amounts do *worse*! (26.3% bad vs 18.5% bad, as of Oct2018).
df$highly_specific = (df$LOAN_AMOUNT %% 100 != 0)

# A view of historical badness by category (car, credit_card, etc), as of early July 2018
# TODO hmmm.... should we maybe filter by roughly what loans we actually consider? like,
# 0.08 < interest < 0.2 or something.
df$badness_by_purpose = 0
purposes = unique(df$purpose)
for (i in 1:length(purposes))
{
  cur_idx = which(df$purpose==purposes[i])
  df$badness_by_purpose[cur_idx] = mean(df$is_bad[cur_idx])
}

# badness_by_purpose further broken down by whether loan amount is highly_specific.
df$purp_spec_badness = 0
purposes = unique(df$purpose)
#even further broken down, by hardship, is the specificity just because of hardship adjustment? answer: NOPE!
#the effect is definitely still there. so, just take purpspecbadness from the non-hardship data only and we're fine.
df$hardship_ever = (df$hardship_status=="ACTIVE"|df$hardship_status=="BROKEN"|df$hardship_status=="COMPLETED")
psb_mat = c()
for (i in 1:length(purposes))
{
  cur_idx = which(df$purpose==purposes[i] & df$highly_specific & !df$hardship_ever) # YES highly_specific
  historical_badness = ifelse(is.na(mean(df$is_bad[cur_idx])), 0.4, mean(df$is_bad[cur_idx]))
  historical_badness = ifelse(historical_badness==0, 0.4, historical_badness)
  df$purp_spec_badness[cur_idx] = historical_badness
  psb_mat = c(psb_mat, paste0(purposes[i],"_SPEC"), historical_badness)
#  print(paste0("df$purp_spec_badness[df$PURPOSE=='",purposes[i],"'&df$highly_specific]=",
#               historical_badness), quote=F)
}
for (i in 1:length(purposes))
{
  cur_idx = which(df$purpose==purposes[i] & !df$highly_specific & !df$hardship_ever) # NOT highly_specific
  historical_badness = ifelse(is.na(mean(df$is_bad[cur_idx])), 0.4, mean(df$is_bad[cur_idx]))
  historical_badness = ifelse(historical_badness==0, 0.4, historical_badness)
  df$purp_spec_badness[cur_idx] = historical_badness
  psb_mat = c(psb_mat, paste0(purposes[i],"_NSPC"), historical_badness)
#  print(paste0("df$purp_spec_badness[df$PURPOSE=='",purposes[i],"'&!df$highly_specific]=",
#               historical_badness), quote=F)
}
psb_df = data.frame(t(matrix(psb_mat,nrow=2)))
colnames(psb_df) <- c("name_SPEC","purp_spec_badness")
write.csv(psb_df, file = "cur_purp_spec_badness.csv")

# Like badness_by_purpose, but by ZIP
df$badness_by_zip = 0
uniq_zips = unique(df$ADDRESS_ZIP)
zip_counts = uniq_zips
for (i in 1:length(uniq_zips))
{
  zip_counts[i] = length(which(df$ADDRESS_ZIP == uniq_zips[i]))
}
zip_counts = as.numeric(zip_counts)
for (i in 1:length(uniq_zips))
{
  cur_idx = which(df$ADDRESS_ZIP==uniq_zips[i])
  if (length(cur_idx) > 20) # don't record mean when too few samples
  {
    df$badness_by_zip[cur_idx] = mean(df$is_bad[cur_idx])
  }
  else
  {
    observed_badness = mean(df$is_bad[cur_idx])
    if (observed_badness < 0.1 & length(cur_idx) > 5) {
      df$badness_by_zip[cur_idx] = 0.10001
    } else if (observed_badness < 0.2) {
      df$badness_by_zip[cur_idx] = 0.12222
    } else {
      df$badness_by_zip[cur_idx] = 0.16666
    }
  }
}
max_bbz = max(df$badness_by_zip)
max_bbz = ifelse(max_bbz >= 0.4, 0.4, max_bbz)
# Go back and replace the badness_by_zip of few-sample ZIPs with an estimate
# based on all other ZIPs. And build the matrix for export.
bbzMat = c()
for (i in 1:length(uniq_zips))
{
  cur_idx = which(df$ADDRESS_ZIP==uniq_zips[i])
  an_idx = cur_idx[1]
  bbz_val = 0
  if (length(cur_idx) <= 20)
  {
    if (df$badness_by_zip[an_idx] < 0.11111) {
      bbz_val = quantile(df$badness_by_zip, c(0.25))[1]
    } else if (df$badness_by_zip[an_idx] < 0.16) {
      bbz_val = median(df$badness_by_zip)
    } else {
      bbz_val = max_bbz
    }
    df$badness_by_zip[cur_idx] = bbz_val
  }
  else
  {
    bbz_val = df$badness_by_zip[an_idx]
  }
  bbzMat = c(bbzMat, uniq_zips[i], bbz_val)
}
bbzdf = data.frame(t(matrix(bbzMat,nrow=2)))
colnames(bbzdf) <- c("ADDRESS_ZIP","badness_by_zip")
write.csv(bbzdf, file = "cur_badness_by_zip.csv")

remove('chargeoff_losses')

df = na.omit(df)
print(paste0(nrow(df)," rows after omitting NAs"))

print(paste0("**********DONE LOADING AND PROCESSING (INTO VAR 'df') THE FILE ",
                        loanDataFilename,"**********"))
print(paste0("df has ", nrow(df), " rows"))
