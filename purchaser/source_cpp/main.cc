#include "std_using.h"
#include <thread>
#include <signal.h>

#include "account_info.h"
#include "file_io.h"
#include "R_wrapper.h"
#include "rest_client.h"
#include "time_util.h"
#include "waiting.h"

LocalTime next_prep_time;
int query_offset_msecs = 50;
LocalTime next_go_time;

void doEternalMainLoopIteration();
void waitUntilPrepTime();

int main(int argc, char** argv)
{
  // startnow true ==> get current loans and (maybe) buy some right away
  //          false ==> get current loans right now, but don't buy; just get
  //                    them to recognize that they're stale in the future.
  bool start_now = false;
  if (argc > 1 && string(argv[1]) == "startnow")
    start_now = true;

  if (signal(SIGCHLD, SIG_IGN) == SIG_ERR)
    perror("couldn't set child processes to be auto-reaped");

  cerr << "=================LENDING CLUB REST INVESTOR STARTED!================"
       << endl;
  if(MANUALLY_CONFIRM_PURCHASES || DO_FAKE_PURCHASE)
  {
    string warningStr =
  "AT LEAST ONE OF MANUALLY_CONFIRM_PURCHASES OR DO_FAKE_PURCHASE IS ENABLED.\n"
  "If you are not starting this program for debugging, you should set these\n"
  "both to false and recompile, or else NO LOANS WILL EVER GET BOUGHT!!!!!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "WARNING: NO LOANS WILL EVER BE BOUGHT IN THIS RUN OF THE PROGRAM\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n"
  "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!\n";
    cerr << warningStr << endl;
  }

  if(start_now)
  {
    cerr << "You asked me to start now; I will do a query+purchase cycle right "
         << "now!"<<endl<<"(And then go into the normal eternal loop, waiting "
         << "for 8AM/12PM/4PM/8PM.)"<<endl;
    next_prep_time = curLocalTime();
    next_prep_time.addMs(50);
    next_go_time = next_prep_time;
    next_go_time.addSeconds(15);
    doEternalMainLoopIteration();
  }
  else
  {
    cerr << "You did not pass --startnow=true, so not starting now. Instead, "
         <<"I will"<<endl<<"query the current period's new loans, "
         <<"and put them all into seenIDsSet[]." << endl;
    std::vector<AccountInfo> all_accounts =
        loadAllAccountState(string(LOANS_DIRPATH)+"/purchaser/state");
    vector<string> new_loans = queryNewLoansNormal(all_accounts[0].auth_code_);
    for (auto const& line : new_loans)
      csvLineIsHeaderOrUnseen(line);
    next_prep_time = getNextPrepTime();
  }

  while(true)
  {
    waitUntilPrepTime();
    doEternalMainLoopIteration();
  }
}

int readOffset()
{
  try
  {
    return readIntFile("state/manualTimingOffsetMs.txt");
  }
  catch (std::exception e)
  {
    cerr << "Problem reading int from state/manualTimingOffsetMs.txt" << endl;
    exit(1);
  }
}

void waitUntilPrepTime()
{
  cerr
  <<"======================================================================\n"
  <<"/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\"
  <<"/\\/\\/\\/\\/\\/\\/\n"
  <<"======================================================================\n"
  <<curTimeStr() << ": waiting until next prep time ("
  << next_prep_time.toString() << ")" << endl;

  while(!areWeThereYet(next_prep_time))
  {}
  next_go_time = getNextGoTime();
  query_offset_msecs = readOffset();
  cerr << "                             Will use a go-time offset of "
       << query_offset_msecs << "ms." << endl;
  cerr << "              ****2 MINUTES OUT****" << endl;
}

void doEternalMainLoopIteration()
{
  std::vector<AccountInfo> all_accounts =
        loadAllAccountState(string(LOANS_DIRPATH)+"/purchaser/state");

  // Display available cash and the just-chosen dynamically chosen spendrate params
  string avail_cash_str = curTimeStr() + ": available:  ";
  for(int i=0; i<all_accounts.size(); i++)
  {
    all_accounts[i].cash_available_ = queryCashAvailable(
        all_accounts[i].account_id_, all_accounts[i].auth_code_);
    avail_cash_str += (all_accounts[i].account_nick_ + ":$" +
                       std::to_string(all_accounts[i].cash_available_) + "  ");
    // TODO multiaccount: currently assuming only 1; if there
    //      was more than 1, this output would get messy
    appendStringFile(
        (string(LOANS_DIRPATH)+"/monitor/data/available_cash.csv"),
        curDateStr()+","+std::to_string(all_accounts[i].cash_available_)+"\n");
    // TODO multiaccount: currently assuming only 1; if there
    //      was more than 1, this output would get messy
    avail_cash_str += "  " + all_accounts[i].chosenParamsString();
  }
  cerr << avail_cash_str << endl;

  while(!atTheRealThingMinus10Sec(next_go_time, query_offset_msecs))
  {}
  while(!atTheRealThing(next_go_time, query_offset_msecs))
  {}
  goTime(&all_accounts);
  std::this_thread::sleep_for(std::chrono::seconds(1));
  cerr << curTimeStr() << ": first query offset was " << query_offset_msecs
       << " ms." << endl;
  std::this_thread::sleep_for(std::chrono::seconds(7));
  next_prep_time = getNextPrepTime();
}
