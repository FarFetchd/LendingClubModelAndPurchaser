#ifndef LOANS_REST_CLIENT_H_
#define LOANS_REST_CLIENT_H_

#include "std_using.h"

#include "purchase_req_res.h"

const bool MANUALLY_CONFIRM_PURCHASES = false;
const bool DO_FAKE_PURCHASE = false;

vector<string> queryNewLoansNormal(string authCode);

double queryCashAvailable(int acctId, string authCode);

vector<PurchaseResult>
purchaseLoans(const vector<PurchaseRequest>& newLoans,
              int portfolioId, string authCode, int acctID);

#endif // LOANS_REST_CLIENT_H_
