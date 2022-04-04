#!/usr/bin/Rscript

setwd(sub("\"\n", "", sub(".*LOANSPATH=\"", "", readChar("/etc/profile", file.info("/etc/profile")$size))))

if(!library(stringr, logical.return=T)) { write("FAILED TO LOAD stringr", stderr()) }
if(!library(xgboost, logical.return=T)) { write("FAILED TO LOAD xgboost", stderr()) }
if(!library(Rcpp, logical.return=T)) { write("FAILED TO LOAD Rcpp", stderr()) }
sourceCpp("purchaser/textscore/MySpell-3.0/unholyjob.cpp")
sourceCpp("purchaser/rcpp_inotify/inotify.cpp")
source("purchaser/predictor_functions.R")
#=================================================

rf <- rememberForest("purchaser/RMODEL_XGBv1.1_MAY2020_nitoriR")
ZIP_GPS_map <- read.csv("purchaser/zipXX_latlon.csv")
badness_by_zip=read.csv("purchaser/badness_by_zip.csv", h=T, stringsAsFactors=F)
purp_spec_badness=read.csv("purchaser/purp_spec_badness.csv", h=T, stringsAsFactors=F)
inputCSVpath <- "purchaser/tmpRtoD/finished/temp_to_r.csv"
outputPath <- "purchaser/tmpRtoD/from_r.txt"
outputPathFinal <- "purchaser/tmpRtoD/r_finished/from_r.txt"
model_params = c("MTHS_SINCE_LAST_MAJOR_DEROG","delinq_2yrs","badness_by_zip","jobtitlegood", "EMPLOYMENT_LENGTH",
                 "REVOLVING_UTILIZATION","INQUIRIES_IN_LAST_6_MONTHS", "after_loan_monthly_income","dti_frac",
                 "FICO_RANGE_LOW", "purp_spec_badness","LOAN_AMOUNT", "is_rent")

# to whatever extent there might be caching gains with RF prediction, warm it up.
fakeinit=readAndCleanCSV("purchaser/sample_temp_to_r.csv", ZIP_GPS_map, badness_by_zip, purp_spec_badness)
fake_test_df = subset(fakeinit, select=model_params)
fake_test_df$jobtitlegood = as.integer(as.character(fake_test_df$jobtitlegood))
fake_test_df$is_rent = as.integer(fake_test_df$is_rent)
fake_probBad = predict(rf, xgb.DMatrix(data = as.matrix(fake_test_df)))
#=================================================

while(TRUE)
{
  #write("loan_predictor.r: about to inotify wait", stderr())
  inotifyWaitForMoveIn("purchaser/tmpRtoD/finished/")
  #write("loan_predictor.r: DONE inotify wait", stderr())

  # TODO collect timing of this and the prediction.
  dfc <- readAndCleanCSV(inputCSVpath, ZIP_GPS_map, badness_by_zip, purp_spec_badness)

  #write("loan_predictor.r: now predicting", stderr())
  #RF: probBad <- predict(rf, dfc, type="prob")[,2]
  test_df = subset(dfc, select=model_params)
  test_df$jobtitlegood = as.integer(as.character(test_df$jobtitlegood))
  test_df$is_rent = as.integer(test_df$is_rent)
  probBad = predict(rf, xgb.DMatrix(data = as.matrix(test_df)))
  #write("loan_predictor.r: done predicting", stderr())

  idAmtReturn <- data.frame(the_id = dfc$LOAN_ID, int_rate = dfc$int_rate,
                            probbad = probBad, durYrs = (dfc$TERM/12))
  sortedIdAmtReturn <- idAmtReturn[ order(probBad, -dfc$int_rate), ]

  write.csv(sortedIdAmtReturn, file=outputPath, quote=FALSE, row.names=FALSE,
            col.names=FALSE)
  file.rename(from=outputPath, to=outputPathFinal)

  # preserve a copy of the loan input data if the model produced any N/A probBads
  if (length(which(is.na(sortedIdAmtReturn$probbad))) > 0)
  {
    file.copy(inputCSVpath, "purchaser/BAD_loan_batch_which_caused_a_NA.csv")
  }
}
