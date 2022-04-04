library(xgboost)

printf <- function(...) invisible(print(sprintf(...)))

source("modelBuildingVars.R")
source("initLoans.R")

print("Now training the real, full xgboost trees")
model_params = c("MTHS_SINCE_LAST_MAJOR_DEROG","delinq_2yrs","badness_by_zip","jobtitlegood", "EMPLOYMENT_LENGTH",
                 "REVOLVING_UTILIZATION","INQUIRIES_IN_LAST_6_MONTHS", "after_loan_monthly_income","dti_frac",
                 "FICO_RANGE_LOW", "purp_spec_badness","LOAN_AMOUNT", "is_rent")
maxdepth = 11
numrounds = 200
eta = 0.1
minchildweight = 10
      train_df = subset(df, select=model_params)
      if (sum(match(names(train_df),"jobtitlegood"), na.rm=T))
        train_df$jobtitlegood = as.integer(as.character(train_df$jobtitlegood))
      if (sum(match(names(train_df),"is_rent"), na.rm=T))
        train_df$is_rent = as.integer(train_df$is_rent)
      xg_train = xgb.DMatrix(data = as.matrix(train_df), label = df$is_bad)
      the_model = xgboost(data = xg_train, max.depth = maxdepth, nrounds = numrounds, eta = eta, min_child_weight=minchildweight,
                          nthread = 4, objective = "binary:logistic", verbose = 1)

print(paste0("Now writing model to purchaser/", rfOutputFilename,"..."))
sercon<-file(paste0("purchaser/",rfOutputFilename), open="wb")
serialize(the_model, sercon)
close(sercon)
print(paste0("Real, full random forest written into ",
             "purchaser/", rfOutputFilename,"!"))

# uh... these don't appear to work, so don't pretend that it happened.
# i just added manual copying to the README instructions.
#file.copy("cur_badness_by_zip.csv", "purchaser/badness_by_zip.csv")
#file.copy("cur_purp_spec_badness.csv", "purchaser/purp_spec_badness.csv")
#print("badness_by_zip and purp_spec_badness CSVs copied into purchaser dir")
print("!!!")
print("DONT FORGET!!!!!!! Copy the _pareto.csv from your chosen model's crossval runs into purchaser/state/curPareto.csv")
