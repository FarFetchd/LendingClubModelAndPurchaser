#ifndef LOANS_PURCHASE_REQ_RES_H_
#define LOANS_PURCHASE_REQ_RES_H_

struct LoanFromR
{
public:
  int loan_id_;
  double interest_rate_;
  double prob_bad_;
  int duration_years_;

  LoanFromR(int id, double int_rate, double prob_bad, int dur_yr)
  : loan_id_(id), interest_rate_(int_rate),
    prob_bad_(prob_bad), duration_years_(dur_yr) {}
  LoanFromR() = delete;
};

struct PurchaseRequest
{
public:
  int loan_id_;
  int amount_to_invest_;

  PurchaseRequest(int loan_id, int amount_to_invest)
      : loan_id_(loan_id), amount_to_invest_(amount_to_invest) {}
  PurchaseRequest() = delete;
};

struct PurchaseResult
{
public:
  int64_t id;
  long amount_confirmed_;
  long amountRequested;
  PurchaseResult(int64_t i, long c, long r) : id(i), amount_confirmed_(c),
                                              amountRequested(r) {}
};

#endif // LOANS_PURCHASE_REQ_RES_H_
