#include "std_using.h"
#include <sys/inotify.h>
#include <unistd.h>
#include <iterator>
#include <fstream>
#include <unordered_set>

#include "account_info.h"
#include "file_io.h"
#include "purchase_req_res.h"
#include "rest_client.h"
#include "time_util.h"

bool csvLineIsHeaderOrUnseen(const string& csvLine)
{
  static std::unordered_set<string> seen_ids;
  if(csvLine.length() < 20)
    return false; //blank or malformed line; ignore

  string start = csvLine.substr(0, 20);
  //the very first line, with the headers, always gets written.
  if (start.find("LOAN_ID") != string::npos)
    return true;

  return seen_ids.insert(start).second;
}

void sendCSVLinesToR(vector<string> writeTheseCSVLines)
{
  std::ofstream tempHack("tmpRtoD/temp_to_r.csv");
  for(auto const & csvLineToWrite : writeTheseCSVLines)
    tempHack<<csvLineToWrite<<"\n";
  tempHack.close();

  if (rename("tmpRtoD/temp_to_r.csv", "tmpRtoD/finished/temp_to_r.csv") !=0)
    perror("rename failed");
}

LoanFromR parseLoanFromRFromStringSpaces(const string& toParse)
{
  int id = -123;
  float interestRate = -999.99;
  float probBad = 8888.88;
  int durationYears = 123;
  sscanf(toParse.c_str(), "%d,%f,%f,%d", &id, &interestRate,
         &probBad, &durationYears);
  if (id == -123 || interestRate == -999.99 ||
      probBad == 8888.88 || durationYears == 123)
  {
    cerr << "parseLoanFromRFromStringSpaces sscanf failed on "<< toParse <<endl;
  }
  return LoanFromR(id, interestRate, probBad, durationYears);
}

vector<LoanFromR> parseLoanLinesFromR()
{
  vector<LoanFromR> ret;
  {
    std::ifstream in("tmpRtoD/r_finished/from_r.txt");
    for (string line; std::getline(in, line); )
      if (line[0] != 't') // skip header
        ret.push_back(parseLoanFromRFromStringSpaces(line));
  }
  if (unlink("tmpRtoD/r_finished/from_r.txt") !=0)
    perror("unlink from_r failed");
  return ret;
}

void inotifyWaitForMoveIn(std::string input)
{
  int inotify_fd = inotify_init();
  if (inotify_fd < 0)
  {
    perror("inotify_init failed");
    return;
  }

  // rather than IN_MOVED_TO could do IN_ALL_EVENTS
  int watch_descriptor =
      inotify_add_watch(inotify_fd, input.c_str(), IN_MOVED_TO);
  if (watch_descriptor < 0)
  {
    perror("inotify_add_watch failed!!\n");
    return;
  }

  while (true)
  {
    char buf[4096];
    if (read(inotify_fd, buf, 4096) < 1)
    {
      perror("inotify read");
      return;
    }
    struct inotify_event* in_ev = (struct inotify_event*)buf;
    if ((in_ev->mask & IN_MOVED_TO) != 0)
    {
      inotify_rm_watch(inotify_fd, watch_descriptor);
      close(inotify_fd);
      return; // yay!
    }
  }
}

void goTime(vector<AccountInfo>* all_accounts)
{
  int zero_count = 0;
  int prev_retrieved_loans = 0;
  vector<string> csv_lines;
  vector<int> loans_total_per_query;
  vector<int> loans_new_per_query;
  do
  {
    prev_retrieved_loans = csv_lines.size();

    cerr << curTimeStr() << ": D about to queryNewLoans()" << endl;

    // Query...
    csv_lines = queryNewLoansNormal((*all_accounts)[0].auth_code_);
    cerr << curTimeStr() << ": queryNewLoans() done: read "
         << csv_lines.size() - 1 << " loans from the server " << endl;
    loans_total_per_query.push_back(csv_lines.size() - 1);

    // ...build the strings to write to R...
    vector<string> write_these_csv_lines;
    for (auto const& csv_line : csv_lines)
      if (csvLineIsHeaderOrUnseen(csv_line))
        write_these_csv_lines.push_back(csv_line);

    loans_new_per_query.push_back(write_these_csv_lines.size() - 1);

    if(write_these_csv_lines.size() <= 1) // no new loans seen
    {
      zero_count++;
      continue;
    }//this continue guarantees csv_lines.length > 0 after here

    // ============R COMMUNICATION!============================
    sendCSVLinesToR(write_these_csv_lines);
    inotifyWaitForMoveIn("tmpRtoD/r_finished/");
    vector<LoanFromR> cur_r_output = parseLoanLinesFromR();
    if (unlink("tmpRtoD/finished/temp_to_r.csv") !=0)
      perror("unlink temp_to_r failed");
    // ============R COMMUNICATION!============================

    // TODO multiaccount
    // randomShuffle(all_accounts);
    // for(int i=0; i<all_accounts->size();i++)
    {
      int i = 0;
      double cash_available_before = all_accounts->at(i).cash_available_;
      all_accounts->at(i).chooseAndMakePurchases(cur_r_output);
      double cash_available_after = all_accounts->at(i).cash_available_;
      double spent = cash_available_before - cash_available_after;
      appendStringFile((string(LOANS_DIRPATH)+"/monitor/data/spent.csv"),
                       curTimeStrComma()+","+std::to_string(spent)+"\n");
    }

  } while(csv_lines.size() > prev_retrieved_loans ||
          csv_lines.size()==0 && zero_count<7);

  cerr << curTimeStr() << ": Our queries got loan lists of lengths {";
  std::copy(loans_total_per_query.begin(), loans_total_per_query.end(),
            std::ostream_iterator<int>(cerr, ","));
  cerr << "}, of which {";
  std::copy(loans_new_per_query.begin(), loans_new_per_query.end(),
            std::ostream_iterator<int>(cerr, ","));
  cerr << "} were new" << endl;

  int loans_seen_this_round = 0;
  for (int x : loans_new_per_query)
    loans_seen_this_round += x;

  appendStringFile((string(LOANS_DIRPATH)+"/monitor/data/loans_seen.csv"),
                  curTimeStrComma()+","+std::to_string(loans_seen_this_round)+"\n");
}
