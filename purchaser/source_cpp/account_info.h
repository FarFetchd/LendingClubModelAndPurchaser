#ifndef LOANS_ACCOUNT_INFO_H_
#define LOANS_ACCOUNT_INFO_H_

#include "std_using.h"

#include "purchase_req_res.h"

#define LOANS_DIRPATH "/home/pi/loans"

class AccountInfo
{
public:
  bool init(string state_dir_path, string account_nick);

  string chosenParamsString();

  void chooseAndMakePurchases(const vector<LoanFromR>& cur_r_output);

  float trimDownPurchase(vector<PurchaseRequest>& loans_to_purchase,
                         float want_to_spend,
                         float expected_new_cash_available);

  string auth_code_;
  int account_id_;
  string account_nick_;
  int portfolio_id_;
  int cash_per_note_ = 25; // safe default
  double prob_bad_cutoff_ = 0.02; // safe default
  double interest_floor_ = 0.08; // safe default
  double interest_ceiling_ = 0.16; // safe default
  double cash_available_ = 0.0;
  double expected_roi_ = 0.0;
  double expected_spendrate_ = 0.0;
};

// Looks in dirpath 'state_path'. For each dir found within, tries to make an
// AccountInfo out of that dir's contents (see init()).
vector<AccountInfo> loadAllAccountState(const string& state_path);

#endif // LOANS_ACCOUNT_INFO_H_
