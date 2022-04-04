

cleanTheData <- function(df, zip_to_gps, badness_by_zip, purp_spec_badness)
{
  # 3 year only, no 5 year
  df = subset(df, TERM == 36)

	df$int_rate <- as.numeric(df$INTEREST_RATE)
	if(max(df$int_rate, na.rm=T) > 1.00001) { df$int_rate <- df$int_rate / 100 }

	df$REVOLVING_UTILIZATION <- as.numeric(df$REVOLVING_UTILIZATION)
  df$REVOLVING_UTILIZATION[which(is.na(df$REVOLVING_UTILIZATION))] <- 100
  df$REVOLVING_UTILIZATION <- ifelse(df$REVOLVING_UTILIZATION < 100, df$REVOLVING_UTILIZATION, 100)

  df$delinq_2yrs <- ifelse(is.na(df$DELINQUENCIES_IN_LAST_2_YEARS), 0,
                           df$DELINQUENCIES_IN_LAST_2_YEARS)

	df$MTHS_SINCE_LAST_MAJOR_DEROG[which(is.na(df$MTHS_SINCE_LAST_MAJOR_DEROG))] <- 600

  # Here it's in months for some reason, while in historical it's been years, and had "10+"
  df$EMPLOYMENT_LENGTH[which(is.na(df$EMPLOYMENT_LENGTH))] <- -12
	df$EMPLOYMENT_LENGTH <- df$EMPLOYMENT_LENGTH / 12

	df$PUB_REC_BANKRUPTCIES[which(is.na(df$PUB_REC_BANKRUPTCIES))] <- 1
	df$INQUIRIES_IN_LAST_6_MONTHS[which(is.na(df$INQUIRIES_IN_LAST_6_MONTHS))] <- 3

  df$dti_frac <- df$DEBT_TO_INCOME_RATIO / 100.0
  # Monthly payments on NON-LC loans, derived from DTI
  df$other_loan_installment <- df$dti_frac * (df$ANNUAL_INCOME / 12)
  df$after_loan_monthly_income <- ifelse(
    df$PURPOSE=="credit_card" | df$PURPOSE=="debt_consolidation",
    df$ANNUAL_INCOME / 12 - (df$other_loan_installment),
    df$ANNUAL_INCOME / 12 - (df$INSTALLMENT + df$other_loan_installment))

  # FICO_RANGE_LOW should be fine as it is

  df$highly_specific = (df$LOAN_AMOUNT %% 100 != 0)

  df$PURPOSE_SPEC = paste0(df$PURPOSE, ifelse(df$highly_specific, "_SPEC", "_NSPC"))
  df$purp_spec_badness <- 0.4  # default for not-enough-data ones: wedding, educational,
                               # small_business, renewable_energy
  df$purp_spec_badness = purp_spec_badness$purp_spec_badness[match(df$PURPOSE_SPEC, purp_spec_badness$name_SPEC)]

  df$badness_by_zip = 0.2 # default: ~90th percentile of badness_by_zip.csv
  df$badness_by_zip = badness_by_zip$badness_by_zip[match(df$ADDRESS_ZIP, badness_by_zip$ADDRESS_ZIP)]


  # LOAN_AMOUNT should be fine as it is

	df$HOME_OWNERSHIP <- factor(df$HOME_OWNERSHIP)
	df$is_rent <- df$HOME_OWNERSHIP=="RENT"

#	df$longitude <- zip_to_gps$meanlons[match(df$ADDRESS_ZIP, zip_to_gps$zip_1st3)]
#	df$latitude <- zip_to_gps$meanlats[match(df$ADDRESS_ZIP, zip_to_gps$zip_1st3)]

	df$jobtitlegood <- factor(properjobtitleprod(df$EMP_TITLE))
	return(df)
}

readAndCleanCSV <- function(filenameCSV, zipgps, badness_by_zip, purp_spec_badness)
{
	dfInput <- read.csv(filenameCSV, h=T, stringsAsFactors=F)

	dfInput <- cleanTheData(dfInput, zipgps, badness_by_zip, purp_spec_badness)
	return(dfInput)

}

# NOTE: not just for RFs anymore haha! Now doing XGB. Maybe I should rename this.
rememberForest <- function(forestFileName)
{
	treeReader <- file(forestFileName, open="rb")
	theNewRF <- unserialize(treeReader)
	close(treeReader)
	return(theNewRF)
}
