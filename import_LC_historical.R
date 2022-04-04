library(stringr)
library(lubridate)

curCleaning <- read.csv("combined.csv", h=T, stringsAsFactors=F)

colnames(curCleaning)[colnames(curCleaning) == 'int_rate'] <- 'INTEREST_RATE'
curCleaning$INTEREST_RATE <- str_replace_all(curCleaning$INTEREST_RATE, "[%]", "")
curCleaning$INTEREST_RATE <- as.numeric(curCleaning$INTEREST_RATE)
if(max(curCleaning$INTEREST_RATE, na.rm=T) > 1.00001) { curCleaning$INTEREST_RATE <- curCleaning$INTEREST_RATE / 100 }
print("REMEMBER, DISCARDING THOSE WITH INTEREST <6% and >20%!!!")
curCleaning <- subset(curCleaning, INTEREST_RATE <= 0.2 & INTEREST_RATE >= 0.06)

colnames(curCleaning)[colnames(curCleaning) == 'loan_amnt'] <- 'LOAN_AMOUNT'
colnames(curCleaning)[colnames(curCleaning) == 'term'] <- 'TERM'
colnames(curCleaning)[colnames(curCleaning) == 'emp_title'] <- 'EMP_TITLE'
colnames(curCleaning)[colnames(curCleaning) == 'emp_length'] <- 'EMPLOYMENT_LENGTH'
colnames(curCleaning)[colnames(curCleaning) == 'home_ownership'] <- 'HOME_OWNERSHIP'
colnames(curCleaning)[colnames(curCleaning) == 'annual_inc'] <- 'ANNUAL_INCOME'
colnames(curCleaning)[colnames(curCleaning) == 'verification_status'] <- 'ANNUAL_INCOME_VERIFIED'
colnames(curCleaning)[colnames(curCleaning) == 'zip_code'] <- 'ADDRESS_ZIP'
colnames(curCleaning)[colnames(curCleaning) == 'earliest_cr_line'] <- 'EARLIEST_CREDIT_LINE_DATE'
colnames(curCleaning)[colnames(curCleaning) == 'fico_range_low'] <- 'FICO_RANGE_LOW'
colnames(curCleaning)[colnames(curCleaning) == 'fico_range_high'] <- 'FICO_RANGE_HIGH'
colnames(curCleaning)[colnames(curCleaning) == 'inq_last_6mths'] <- 'INQUIRIES_IN_LAST_6_MONTHS'
colnames(curCleaning)[colnames(curCleaning) == 'mths_since_last_delinq'] <- 'MONTHS_SINCE_LAST_DELINQUENCY'
colnames(curCleaning)[colnames(curCleaning) == 'revol_util'] <- 'REVOLVING_UTILIZATION'
colnames(curCleaning)[colnames(curCleaning) == 'mths_since_last_major_derog'] <- 'MTHS_SINCE_LAST_MAJOR_DEROG'
colnames(curCleaning)[colnames(curCleaning) == 'chargeoff_within_12_mths'] <- 'CHARGEOFF_WITHIN_12_MTHS'
colnames(curCleaning)[colnames(curCleaning) == 'pub_rec_bankruptcies'] <- 'PUB_REC_BANKRUPTCIES'
colnames(curCleaning)[colnames(curCleaning) == 'pub_rec'] <- 'PUB_REC_DEROG'
colnames(curCleaning)[colnames(curCleaning) == 'tax_liens'] <- 'TAX_LIENS'

colnames(curCleaning)[colnames(curCleaning) == 'dti'] <- 'DEBT_TO_INCOME_RATIO'
colnames(curCleaning)[colnames(curCleaning) == 'installment'] <- 'INSTALLMENT'

curCleaning[,'inq_last_12m'] <- NULL
curCleaning[,'total_cu_tl'] <- NULL
curCleaning[,'inq_fi'] <- NULL
curCleaning[,'all_util'] <- NULL
curCleaning[,'max_bal_bc'] <- NULL
curCleaning[,'open_rv_24m'] <- NULL
curCleaning[,'open_rv_12m'] <- NULL
curCleaning[,'il_util'] <- NULL
curCleaning[,'total_bal_il'] <- NULL
curCleaning[,'mths_since_rcnt_il'] <- NULL
curCleaning[,'open_il_24m'] <- NULL
curCleaning[,'open_il_12m'] <- NULL
curCleaning[,'open_il_6m'] <- NULL
curCleaning[,'open_acc_6m'] <- NULL
curCleaning[,'open_act_il'] <- NULL
curCleaning[,'annual_inc_joint'] <- NULL
curCleaning[,'dti_joint'] <- NULL
curCleaning[,'mths_since_last_record'] <- NULL

#curCleaning[,'funded_amnt'] <- NULL
curCleaning[,'funded_amnt_inv'] <- NULL
curCleaning[,'grade'] <- NULL
curCleaning[,'sub_grade'] <- NULL
curCleaning[,'pymnt_plan'] <- NULL
curCleaning[,'title'] <- NULL
curCleaning[,'addr_state'] <- NULL
curCleaning[,'open_acc'] <- NULL
curCleaning[,'total_acc'] <- NULL
curCleaning[,'initial_list_status'] <- NULL
curCleaning[,'last_credit_pull_d'] <- NULL
#curCleaning[,'id'] <- NULL
curCleaning[,'member_id'] <- NULL
curCleaning[,'url'] <- NULL
curCleaning[,'desc'] <- NULL

curCleaning[,'num_rev_accts'] <- NULL
curCleaning[,'num_rev_tl_bal_gt_0'] <- NULL
curCleaning[,'num_sats'] <- NULL
curCleaning[,'num_tl_120dpd_2m'] <- NULL
curCleaning[,'num_tl_30dpd'] <- NULL
curCleaning[,'num_tl_90g_dpd_24m'] <- NULL
curCleaning[,'num_tl_op_past_12m'] <- NULL
curCleaning[,'pct_tl_nvr_dlq'] <- NULL
curCleaning[,'percent_bc_gt_75'] <- NULL
curCleaning[,'total_bal_ex_mort'] <- NULL
curCleaning[,'total_bc_limit'] <- NULL
curCleaning[,'total_il_high_credit_limit'] <- NULL
curCleaning[,'mo_sin_old_il_acct'] <- NULL
curCleaning[,'mo_sin_old_rev_tl_op'] <- NULL
curCleaning[,'mo_sin_rcnt_rev_tl_op'] <- NULL
curCleaning[,'mo_sin_rcnt_tl'] <- NULL

curCleaning[,'hardship_flag'] <- NULL #worthless even if interested in hardship
curCleaning[,'hardship_type'] <- NULL
curCleaning[,'hardship_reason'] <- NULL
#curCleaning[,'hardship_status'] <- NULL
curCleaning[,'deferral_term'] <- NULL
curCleaning[,'hardship_amount'] <- NULL
curCleaning[,'hardship_start_date'] <- NULL
curCleaning[,'hardship_end_date'] <- NULL
curCleaning[,'payment_plan_start_date'] <- NULL
curCleaning[,'hardship_length'] <- NULL
curCleaning[,'hardship_dpd'] <- NULL
curCleaning[,'hardship_loan_status'] <- NULL
curCleaning[,'orig_projected_additional_accrued_interest'] <- NULL
curCleaning[,'hardship_payoff_balance_amount'] <- NULL
curCleaning[,'hardship_last_payment_amount'] <- NULL
curCleaning[,'disbursement_method'] <- NULL
curCleaning[,'debt_settlement_flag'] <- NULL
curCleaning[,'debt_settlement_flag_date'] <- NULL
curCleaning[,'settlement_status'] <- NULL
curCleaning[,'settlement_date'] <- NULL
curCleaning[,'settlement_amount'] <- NULL
curCleaning[,'settlement_percentage'] <- NULL
curCleaning[,'settlement_term'] <- NULL
curCleaning[,'tot_hi_cred_lim'] <- NULL
curCleaning[,'revol_bal_joint'] <- NULL
curCleaning[,'sec_app_fico_range_low'] <- NULL
curCleaning[,'sec_app_fico_range_high'] <- NULL
curCleaning[,'sec_app_earliest_cr_line'] <- NULL
curCleaning[,'sec_app_inq_last_6mths'] <- NULL
curCleaning[,'sec_app_mort_acc'] <- NULL
curCleaning[,'sec_app_open_acc'] <- NULL
curCleaning[,'sec_app_revol_util'] <- NULL
curCleaning[,'sec_app_open_act_il'] <- NULL
curCleaning[,'sec_app_num_rev_accts'] <- NULL
curCleaning[,'sec_app_chargeoff_within_12_mths'] <- NULL
curCleaning[,'sec_app_collections_12_mths_ex_med'] <- NULL
curCleaning[,'sec_app_mths_since_last_major_derog'] <- NULL
curCleaning[,'delinq_amnt'] <- NULL
curCleaning[,'mort_acc'] <- NULL
curCleaning[,'mths_since_recent_bc'] <- NULL
curCleaning[,'mths_since_recent_inq'] <- NULL
curCleaning[,'num_actv_bc_tl'] <- NULL
curCleaning[,'num_actv_rev_tl'] <- NULL
curCleaning[,'num_bc_sats'] <- NULL
curCleaning[,'num_bc_tl'] <- NULL
curCleaning[,'num_il_tl'] <- NULL
curCleaning[,'num_op_rev_tl'] <- NULL
curCleaning[,'bc_open_to_buy'] <- NULL
curCleaning[,'out_prncp_inv'] <- NULL

curCleaning$issue_d <- as.Date(curCleaning$issue_d)
curCleaning$TERM <- str_replace_all(curCleaning$TERM, "months", "")
curCleaning$TERM <- as.numeric(curCleaning$TERM)
# A significant jump in defaults happened around here.
# With data so recent, 60 month can no longer be trained on.
print(paste0(nrow(curCleaning)," rows including pre-2014 and 60months"))
curCleaning <- subset(curCleaning, issue_d > "2014-09-01" & TERM < 60)
print(paste0(nrow(curCleaning)," rows EXcluding pre-2014 and 60months"))

curCleaning$REVOLVING_UTILIZATION <- str_replace_all(curCleaning$REVOLVING_UTILIZATION, "[%]", "")
curCleaning$REVOLVING_UTILIZATION <- as.numeric(curCleaning$REVOLVING_UTILIZATION)
curCleaning$EMPLOYMENT_LENGTH <- str_replace_all(curCleaning$EMPLOYMENT_LENGTH, "< 1 year", "0.5")
curCleaning$EMPLOYMENT_LENGTH <- str_replace_all(curCleaning$EMPLOYMENT_LENGTH, "n/a", "-1")
curCleaning$EMPLOYMENT_LENGTH <- str_replace_all(curCleaning$EMPLOYMENT_LENGTH, "[+]", "")
curCleaning$EMPLOYMENT_LENGTH <- str_replace_all(curCleaning$EMPLOYMENT_LENGTH, "10 years", "15")
curCleaning$EMPLOYMENT_LENGTH <- str_replace_all(curCleaning$EMPLOYMENT_LENGTH, " years", "")
curCleaning$EMPLOYMENT_LENGTH <- str_replace_all(curCleaning$EMPLOYMENT_LENGTH, " year", "")
curCleaning$EMPLOYMENT_LENGTH <- as.numeric(curCleaning$EMPLOYMENT_LENGTH)

curCleaning$loan_status <- str_replace_all(curCleaning$loan_status, "Does not meet the credit policy. Status:", "")

curCleaning$MTHS_SINCE_LAST_MAJOR_DEROG[which(is.na(curCleaning$MTHS_SINCE_LAST_MAJOR_DEROG))] <- 600
curCleaning$CHARGEOFF_WITHIN_12_MTHS[which(is.na(curCleaning$CHARGEOFF_WITHIN_12_MTHS))] <- 0
curCleaning$MONTHS_SINCE_LAST_DELINQUENCY[which(is.na(curCleaning$MONTHS_SINCE_LAST_DELINQUENCY))] <- 900
curCleaning$REVOLVING_UTILIZATION[which(is.na(curCleaning$REVOLVING_UTILIZATION))] <- 100

write.csv(curCleaning, file="cleaned_historical.csv", row.names=F)
