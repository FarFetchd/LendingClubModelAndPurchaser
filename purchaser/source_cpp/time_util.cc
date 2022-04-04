#include "std_using.h"
#include <chrono>
#include <cstring>

#include "time_util.h"

uint64_t msSinceEpoch()
{
  std::chrono::milliseconds msse =
      std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::system_clock::now().time_since_epoch());
  return msse.count();
}
string curTimeStr()
{
  uint64_t msse = msSinceEpoch();
  int ms_part = msse % 1000;
  time_t sse = static_cast<time_t>((msse - ms_part) / 1000);
  struct tm tstruct = *localtime(&sse);

  char buf[80];
  memset(buf, 0, 80);
  strftime(buf, 79, "%Y-%m-%dT%H:%M:%S", &tstruct);
  return string(buf) + "." + std::to_string(ms_part);
}
string curTimeStrComma()
{
  uint64_t msse = msSinceEpoch();
  int ms_part = msse % 1000;
  time_t sse = static_cast<time_t>((msse - ms_part) / 1000);
  struct tm tstruct = *localtime(&sse);

  char buf[80];
  memset(buf, 0, 80);
  strftime(buf, 79, "%Y-%m-%d,%H:%M:%S", &tstruct);
  return string(buf) + "." + std::to_string(ms_part);
}
string curDateStr()
{
  uint64_t msse = msSinceEpoch();
  int ms_part = msse % 1000;
  time_t sse = static_cast<time_t>((msse - ms_part) / 1000);
  struct tm tstruct = *localtime(&sse);

  char buf[80];
  memset(buf, 0, 80);
  strftime(buf, 79, "%Y-%m-%d", &tstruct);
  return string(buf);
}

  void LocalTime::addMs(int ms_to_add)
  {
    ms += ms_to_add;
    doCarries();
  }
  void LocalTime::addSeconds(int seconds)
  {
    t.tm_sec += seconds;
    doCarries();
  }
  string LocalTime::toString()
  {
    char buf[80];
    memset(buf, 0, 80);
    strftime(buf, 79, "%Y-%m-%dT%H:%M:%S", &t);
    return string(buf);
  }
  void LocalTime::doCarries()
  {
    while (ms >= 1000)
    {
      ms -= 1000;
      t.tm_sec += 1;
    }
    while (ms < 0)
    {
      ms += 1000;
      t.tm_sec -= 1;
    }
    while (t.tm_sec >= 60)
    {
      t.tm_sec -= 60;
      t.tm_min += 1;
    }
    while (t.tm_sec < 0)
    {
      t.tm_sec += 60;
      t.tm_min -= 1;
    }
    while (t.tm_min >= 60)
    {
      t.tm_min -= 60;
      t.tm_hour += 1;
    }
    while (t.tm_min < 0)
    {
      t.tm_min += 60;
      t.tm_hour -= 1;
    }
  }

int64_t diffMsTimeOnly(LocalTime t1, LocalTime t2)
{
  return (t1.ms - t2.ms) +
         1000 * static_cast<int64_t>(t1.t.tm_sec - t2.t.tm_sec) +
         1000 * 60 * static_cast<int64_t>(t1.t.tm_min - t2.t.tm_min) +
         1000 * 60 * 60 * static_cast<int64_t>(t1.t.tm_hour - t2.t.tm_hour);
}
LocalTime curLocalTime()
{
  uint64_t msse = msSinceEpoch();
  int ms_part = msse % 1000;
  time_t sse = static_cast<time_t>((msse - ms_part) / 1000);
  LocalTime ret;
  ret.t = *localtime(&sse);
  ret.ms = ms_part;
  return ret;
}
