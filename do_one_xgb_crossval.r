if (!override_auto_filename)
{
  rfOutputFilename = paste0(out_filename_prefix, "_maxd", maxdepth, "_rounds", numrounds, "_eta", eta, "_mcw", minchildweight)
}
compare_filenames = c(paste0(rfOutputFilename,"_pareto.csv"),compare_filenames)
df = master_df
print(paste0("Now doing ", NUM_CROSSVAL_RUNS, " crossval splits for probBad"))
df$badProbs = 0
for(i in seq(1, NUM_CROSSVAL_RUNS))
{
  # for the training data we will feed to xgb, we need just exactly the columns we're training on. (and of course just the
  # rows that aren't part of this crossval slice).
  train_df = subset(subset(df, crossvalSplit!=i), select=model_params)
  if (sum(match(names(train_df),"jobtitlegood"), na.rm=T))
    train_df$jobtitlegood = as.integer(as.character(train_df$jobtitlegood))
  if (sum(match(names(train_df),"is_rent"), na.rm=T))
    train_df$is_rent = as.integer(train_df$is_rent)

  test_df = subset(subset(df, crossvalSplit==i), select=model_params)
  if (sum(match(names(train_df),"jobtitlegood"), na.rm=T))
    test_df$jobtitlegood = as.integer(as.character(test_df$jobtitlegood))
  if (sum(match(names(train_df),"is_rent"), na.rm=T))
    test_df$is_rent = as.integer(test_df$is_rent)

  if (model_type == "writeoff_regression")
  {
    xg_train = xgb.DMatrix(data = as.matrix(train_df), label = df$realWriteoffClamped[which(df$crossvalSplit!=i)])
    xg_test = xgb.DMatrix(data = as.matrix(test_df), label = df$realWriteoffClamped[which(df$crossvalSplit==i)])
    bst = xgboost(data = xg_train, max.depth = maxdepth, nrounds = numrounds, eta = eta, min_child_weight=minchildweight,
                  nthread = 4, objective = "reg:squarederror", verbose = 0)
  }
  else # trad_is_bad
  {
    xg_train = xgb.DMatrix(data = as.matrix(train_df), label = df$is_bad[which(df$crossvalSplit!=i)])
    xg_test = xgb.DMatrix(data = as.matrix(test_df), label = df$is_bad[which(df$crossvalSplit==i)])
    bst = xgboost(data = xg_train, max.depth = maxdepth, nrounds = numrounds, eta = eta, min_child_weight=minchildweight,
                  nthread = 4, objective = "binary:logistic", verbose = 0)
  }
  df$badProbs[which(df$crossvalSplit==i)] = predict(bst, xg_test)
  print(date())
  printf("Crossval xgboost training and predicting iteration %.0f of %.0f done...",
         i, NUM_CROSSVAL_RUNS)
}

source("crossvalRFworker.R")
