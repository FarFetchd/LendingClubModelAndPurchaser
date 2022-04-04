#ifndef LOANS_R_WRAPPER_H_
#define LOANS_R_WRAPPER_H_

#include "account_info.h"

void goTime(vector<AccountInfo>* all_accounts);
bool csvLineIsHeaderOrUnseen(const string& csvLine);

#endif // LOANS_R_WRAPPER_H_
