#ifndef TIME_UTIL_H_
#define TIME_UTIL_H_

#include "std_using.h"

uint64_t msSinceEpoch();

string curTimeStr();

string curTimeStrComma();

string curDateStr();

class LocalTime
{
public:
  struct tm t;
  int ms;
  void addMs(int ms_to_add);
  void addSeconds(int seconds);
  string toString();
private:
  void doCarries();
};

int64_t diffMsTimeOnly(LocalTime t1, LocalTime t2);

LocalTime curLocalTime();

#endif // TIME_UTIL_H_
