#include <cmath>
#include <sstream>
#include <thread>
#include <curl/curl.h>

#include "rest_client.h"
#include "waiting.h"

#include "json.hpp"

void waitForRESTCooldown()
{
  static uint64_t last_rest_query_time_msse = 0;

  const uint64_t WAIT_DUR_MS = 995;
  uint64_t cur_msse = msSinceEpoch();
  uint64_t diff = cur_msse - last_rest_query_time_msse;
  if (diff < WAIT_DUR_MS)
    std::this_thread::sleep_for(std::chrono::milliseconds(WAIT_DUR_MS - diff));
  last_rest_query_time_msse = cur_msse;
}

std::vector<PurchaseResult> parsePurchaseResult(string resultStr)
{
  if(MANUALLY_CONFIRM_PURCHASES)
  {
    cerr << "\n=====================\n"
         << "DEBUG: HERE IS THE JSON RESPONSE FOR OUR PURCHASE:\n"
         << resultStr << "\n=====================" << endl;
  }
  nlohmann::json purchaseResJ;
  try
  {
    purchaseResJ = nlohmann::json::parse(resultStr);
  }
  catch(const std::exception& e)
  {
    cerr << "exception parsing JSON in parsePurchaseResult: "
         << e.what() << "\n raw JSON reply was: " << resultStr << endl;
    return {};
  }

  std::vector<PurchaseResult> purchaseRes;
  for (auto const& loanRes : purchaseResJ["orderConfirmations"])
  {
    purchaseRes.emplace_back(loanRes["loanId"].get<uint64_t>(),
                             lround(loanRes["investedAmount"].get<float>()),
                             lround(loanRes["requestedAmount"].get<float>()));
  }
  return purchaseRes;
}

bool confirmPurchase(nlohmann::json buyJson)
{
  if(MANUALLY_CONFIRM_PURCHASES)
  {
    cerr << "WILL SEND THIS JSON: " << buyJson.dump() << "\n\nOK?(y/n)" << endl;
    std::string answer;
    std::getline(std::cin, answer);
    if (answer[0] != 'y')
    {
      cerr << "Purchase aborted." << endl;
      return false;
    }
  }
  return true;
}

nlohmann::json constructBuyJson(const std::vector<PurchaseRequest>& newLoans,
                                int portfolioId, int acctID)
{
  nlohmann::json newLoansJson = nlohmann::json::array();
  for (auto const& loan : newLoans)
  {
    nlohmann::json loanJson;
    loanJson["loanId"] = (DO_FAKE_PURCHASE ? 123 : loan.loan_id_);
    loanJson["requestedAmount"] = loan.amount_to_invest_;
    if(portfolioId > 0)
      loanJson["portfolioId"] = portfolioId;
    newLoansJson.push_back(loanJson);
  }
  nlohmann::json buyJson;
  buyJson["aid"] = acctID;
  buyJson["orders"] = newLoansJson;
  return buyJson;
}

static size_t WriteCallback(void* data, size_t size, size_t nmemb, void* usr)
{
  ((std::string*)usr)->append((char*)data, size * nmemb);
  return size * nmemb;
}

std::vector<std::string> queryNewLoansNormal(std::string authCode)
{
  CURL* curl = curl_easy_init();
  if (!curl)
  {
    cerr << "curl_easy_init() in queryNewLoansNormal() failed!" << endl;
    return {};
  }

  std::string response_body;
  std::string auth_header = "Authorization: " + authCode;

  struct curl_slist* list = NULL;
  list = curl_slist_append(list, "Accept: text/plain");
  list = curl_slist_append(list, auth_header.c_str());

  curl_easy_setopt(curl, CURLOPT_URL,
                   "https://api.lendingclub.com/api/investor/v1/loans/listing");
  curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_body);

  waitForRESTCooldown();
  CURLcode res = curl_easy_perform(curl);
  curl_easy_cleanup(curl);
  curl_slist_free_all(list);

  std::stringstream ss(response_body);
  std::string line;
  std::vector<std::string> lines;
  while (std::getline(ss, line, '\n'))
    lines.push_back(line);

  return lines;
}

double queryCashAvailable(int acctId, std::string authCode)
{
  CURL* curl = curl_easy_init();
  if (!curl)
  {
    cerr << "curl_easy_init() in queryCashAvailable() failed!" << endl;
    return 0.11111;
  }

  std::string response_body;
  std::string auth_header = "Authorization: " + authCode;

  struct curl_slist* list = NULL;
  list = curl_slist_append(list, "Accept: application/json");
  list = curl_slist_append(list, auth_header.c_str());

  std::string url = "https://api.lendingclub.com/api/investor/v1/accounts/" +
                    std::to_string(acctId)+"/availablecash";
  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_body);

  waitForRESTCooldown();
  CURLcode res = curl_easy_perform(curl);
  curl_easy_cleanup(curl);
  curl_slist_free_all(list);

  try
  {
    nlohmann::json temp = nlohmann::json::parse(response_body);
    return temp["availableCash"].get<double>();
  }
  catch(const std::exception& e)
  {
    cerr << "exception parsing JSON in queryCashAvailable: "
         << e.what() << "\n raw JSON reply was: " << response_body << endl;
    return 0.22222;
  }
}

std::vector<PurchaseResult>
purchaseLoans(const std::vector<PurchaseRequest>& newLoans,
              int portfolioId, std::string authCode, int acctID)
{
  if(newLoans.size() == 0)
    return {};

  nlohmann::json buyJson = constructBuyJson(newLoans, portfolioId, acctID);
  if(!confirmPurchase(buyJson))
    return {};
  std::string buy_string = buyJson.dump();
  std::string response_body;

  CURL* curl = curl_easy_init();
  if (!curl)
  {
    cerr << "curl_easy_init() in curlPurchaseLoans() failed!" << endl;
    return {};
  }

  curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, buy_string.length());
  curl_easy_setopt(curl, CURLOPT_POSTFIELDS, buy_string.c_str());

  std::string url = "https://api.lendingclub.com/api/investor/v1/accounts/" +
                    std::to_string(acctID)+"/orders";
  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_body);

  std::string auth_header = "Authorization: " + authCode;
  struct curl_slist* list = NULL;
  list = curl_slist_append(list, "Content-Type: application/json");
  list = curl_slist_append(list, "Accept: application/json");
  list = curl_slist_append(list, auth_header.c_str());
  curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);

  waitForRESTCooldown();
  CURLcode res = curl_easy_perform(curl);
  curl_easy_cleanup(curl);
  curl_slist_free_all(list);

  return parsePurchaseResult(response_body);
}
