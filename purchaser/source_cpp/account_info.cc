#include <cmath>

#include "account_info.h"

#include "file_io.h"
#include "rest_client.h"
#include "time_util.h"

double findInterestRate(int loan_id, vector<LoanFromR> const& haystack)
{
  for (auto const& x : haystack)
    if (x.loan_id_ == loan_id)
      return x.interest_rate_;
  return -123.456;
}

bool AccountInfo::init(string state_dir_path, string account_nick)
{
  string account_path = state_dir_path + "/" + account_nick;
  try
  {
    auth_code_ = readStringFile(account_path+"/authCode.txt");
    account_id_ = readIntFile(account_path+"/accountId.txt");
    account_nick_ = account_nick;
    portfolio_id_ = readIntFile(account_path+"/portfolioId.txt");
    cash_per_note_ = readIntFile(account_path+"/cashPerNote.txt");
    prob_bad_cutoff_ = readDoubleFile(account_path+"/probBadCutoff.txt");
    interest_floor_ = readDoubleFile(account_path+"/interestFloor.txt");
    interest_ceiling_ = readDoubleFile(account_path+"/interestCeiling.txt");
    expected_roi_ = readDoubleFile(account_path+"/curSpendrateExpectedROI.txt");
    expected_spendrate_ = readDoubleFile(account_path+"/curExpectedSpendrate.txt");
  }
  catch (const std::exception& e)
  {
    cerr << "init " << account_path << " failed: " << e.what() << endl;
    return false;
  }
  return true;
}

string AccountInfo::chosenParamsString()
{
  return "dynamicinvest, probBad=" + std::to_string(prob_bad_cutoff_) +
        ", intFloor=" + std::to_string(interest_floor_) +
        string(", intCeil=IGNORED") //+ std::to_string(interest_ceiling_) +
        + ", expectedROI=" + std::to_string(expected_roi_) +
        ", expectedSpendrate=" + std::to_string(expected_spendrate_);
}

void AccountInfo::chooseAndMakePurchases(const vector<LoanFromR>& cur_r_output)
{
  // Decide which loans this account wants...
  double expected_new_cash_available = cash_available_;
  vector<PurchaseRequest> loans_to_purchase;
  int num_loans_wanted = 0;
  double want_to_spend = 0;
  for (auto const& cur_loan : cur_r_output)
  {
    if(cur_loan.prob_bad_ <= prob_bad_cutoff_ &&
        cur_loan.interest_rate_ >= interest_floor_ &&
        //cur_loan.interest_rate_ <= interest_ceiling_ &&
        cur_loan.duration_years_ == 3)
    {
      num_loans_wanted++;
      want_to_spend += cash_per_note_;
      loans_to_purchase.emplace_back(cur_loan.loan_id_, cash_per_note_);
    }
  }
  if (want_to_spend > expected_new_cash_available)
  {
    want_to_spend = trimDownPurchase(loans_to_purchase, want_to_spend,
                                    expected_new_cash_available);
  }
  expected_new_cash_available -= want_to_spend;

  if(num_loans_wanted != 0)
  {
    cerr << curTimeStr() << ": " << account_nick_ << " wants "
          << num_loans_wanted << ", can afford to purchase "
          << loans_to_purchase.size() << " of " << cur_r_output.size()
          << " loans!" << endl;
  }
  if(loans_to_purchase.size() == 0)
    return;

  // ...and buy those wanted loans.
  vector<PurchaseResult> purchase_res = purchaseLoans(
      loans_to_purchase, portfolio_id_, auth_code_, account_id_);

  //Now we know how much we actually invested, update cash_available_ accordingly.
  for (auto const& purchased : purchase_res)
    cash_available_ -= purchased.amount_confirmed_;

  string result_summary = (curTimeStr() +
                    ": purchase results (account "+account_nick_+"): \n");
  for (auto const& purchased : purchase_res)
  {
    result_summary +=
        ("    Got $"+std::to_string(purchased.amount_confirmed_)+
          " of $"+std::to_string(purchased.amountRequested)+
          " for loan "+std::to_string(purchased.id)+
          " (interest rate "+std::to_string(findInterestRate(purchased.id,
                                                            cur_r_output))+
          ")\n");
  }
  cerr << result_summary;
}

float AccountInfo::trimDownPurchase(vector<PurchaseRequest>& loans_to_purchase,
                        float want_to_spend,
                        float expected_new_cash_available)
{
  float deficit = want_to_spend - expected_new_cash_available;
  float deficitPer = deficit / static_cast<float>(loans_to_purchase.size());
  long roundedDownPer = lround(floor(deficitPer / 25.0) * 25.0);
  for (auto& cur_loan : loans_to_purchase)
  {
    int reduceBy = cur_loan.amount_to_invest_ <= roundedDownPer
        ? cur_loan.amount_to_invest_
        : roundedDownPer;
    cur_loan.amount_to_invest_ -= reduceBy;
    deficit -= reduceBy;
  }
  // may be a little deficit left; take 25 from each (that arent yet 0) until gone
  while (true)
  {
    bool progressMade = false;
    for (auto& cur_loan : loans_to_purchase)
    {
      if (deficit < 0.1)
        break;
      if (cur_loan.amount_to_invest_ >= 25)
      {
        cur_loan.amount_to_invest_ -= 25;
        deficit -= 25.0;
        progressMade = true;
      }
    }
    if (deficit < 0.1 || !progressMade)
      break;
  }

  float updated_want_to_spend = 0.0;
  // remove from array any that became 0
  vector<PurchaseRequest> nonzero;
  for (auto const& l : loans_to_purchase)
  {
    if (l.amount_to_invest_ > 0)
    {
      nonzero.push_back(l);
      updated_want_to_spend += l.amount_to_invest_;
    }
  }
  loans_to_purchase = nonzero;
  return updated_want_to_spend;
}

// Looks in dirpath 'state_path'. For each dir found within, tries to make an
// AccountInfo out of that dir's contents (see init()).
vector<AccountInfo> loadAllAccountState(const string& state_path)
{
  // Dynamically choose spendrate params
  system("/usr/bin/Rscript --vanilla set_spend_params.r");
  // NOTE: loadAllAccountState() relies on what set_spend_params.r writes!

  // TODO multiaccount actually read the dir names
  vector<string> dirs;
  dirs.push_back("EXAMPLEACCOUNT");

  vector<AccountInfo> ret;
  for (auto const& d : dirs)
  {
    AccountInfo temp;
    if (temp.init(state_path, d))
      ret.push_back(temp);
  }
  return ret;
}
