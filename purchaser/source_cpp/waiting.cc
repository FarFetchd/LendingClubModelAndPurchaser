#include <chrono>
#include <thread>

#include "waiting.h"

//new loans: 6AM, 10AM, 2PM, 6PM Pacific time
//which is: 8AM, noon, 4PM, 8PM Central
//which is: 9AM, 1PM, 5PM, 9PM Eastern
const int FIRST_HOUR = 9;
const int SECOND_HOUR = 13;
const int THIRD_HOUR = 17;
const int FOURTH_HOUR = 21;

//and we want to prepareR() 120 seconds prior:
//7:58AM, 11:58AM, 3:58PM, 7:58PM Central
//8:58AM, 12:58AM, 4:58PM, 8:58PM Eastern

void sleepMaybeNegative(int64_t ms)
{
  if(ms > 0)
    std::this_thread::sleep_for(std::chrono::milliseconds(ms));
}

//NOTE: USING EASTERN TIME
// Assumes that from now to next go time will never straddle a midnight!!!
// (meaning it never sets the date component)
LocalTime getNextGoTime()
{
  LocalTime next_go_time = curLocalTime();
  int cur_hour = next_go_time.t.tm_hour;

  if(cur_hour < FIRST_HOUR || cur_hour >= FOURTH_HOUR)
  {
    next_go_time.t.tm_hour = FIRST_HOUR;
    next_go_time.t.tm_min = 0;
    next_go_time.t.tm_sec = 0;
    next_go_time.ms = 0;
  }
  else if(cur_hour >= FIRST_HOUR && cur_hour < SECOND_HOUR)
  {
    next_go_time.t.tm_hour = SECOND_HOUR;
    next_go_time.t.tm_min = 0;
    next_go_time.t.tm_sec = 0;
    next_go_time.ms = 0;
  }
  else if(cur_hour >= SECOND_HOUR && cur_hour < THIRD_HOUR)
  {
    next_go_time.t.tm_hour = THIRD_HOUR;
    next_go_time.t.tm_min = 0;
    next_go_time.t.tm_sec = 0;
    next_go_time.ms = 0;
  }
  else
  {
    next_go_time.t.tm_hour = FOURTH_HOUR;
    next_go_time.t.tm_min = 0;
    next_go_time.t.tm_sec = 0;
    next_go_time.ms = 0;
  }
  return next_go_time;
}

// Doesn't set the date component, so next_prep_time should not be relied on
// to handle the sleep that straddles midnight.
LocalTime getNextPrepTime()
{
  LocalTime next_prep_time = curLocalTime();
  int cur_hour = next_prep_time.t.tm_hour;
  int cur_min = next_prep_time.t.tm_min;

  if(cur_hour < FIRST_HOUR-1 || cur_hour >= FOURTH_HOUR ||
     cur_hour == FIRST_HOUR-1 && cur_min < 58)
  {
    //set FIRST_HOUR:58AM
    next_prep_time.t.tm_hour = FIRST_HOUR-1;
    next_prep_time.t.tm_min = 58;
    next_prep_time.t.tm_sec = 0;
    next_prep_time.ms = 0;
  }
  else if(cur_hour < SECOND_HOUR-1 || cur_hour == SECOND_HOUR-1 && cur_min < 58)
  {
    next_prep_time.t.tm_hour = SECOND_HOUR-1;
    next_prep_time.t.tm_min = 58;
    next_prep_time.t.tm_sec = 0;
    next_prep_time.ms = 0;
  }
  else if(cur_hour < THIRD_HOUR-1 || cur_hour == THIRD_HOUR-1 && cur_min < 58)
  {
    next_prep_time.t.tm_hour = THIRD_HOUR-1;
    next_prep_time.t.tm_min = 58;
    next_prep_time.t.tm_sec = 0;
    next_prep_time.ms = 0;
  }
  else
  {
    next_prep_time.t.tm_hour = FOURTH_HOUR-1;
    next_prep_time.t.tm_min = 58;
    next_prep_time.t.tm_sec = 0;
    next_prep_time.ms = 0;
  }
  return next_prep_time;
}

bool areWeThereYet(const LocalTime& next_prep_time)
{
  LocalTime now = curLocalTime();
  // We ignore / don't keep accurate the date component of the LocalTimes we're
  // working with. So, avoid cross-day comparison by just sleeping until morning
  // once we're right after the last loan period.
  if (now.t.tm_hour == FOURTH_HOUR && (now.t.tm_min > 0 || now.t.tm_sec > 1))
  {
    std::this_thread::sleep_for(std::chrono::hours(10));
    return false;
  }
  else if (now.t.tm_hour > FOURTH_HOUR)
  {
    std::this_thread::sleep_for(std::chrono::hours(7));
    return false;
  }
  // Assumes no midnight wraparound! (Taken care of by the above).
  int64_t remaining_ms = diffMsTimeOnly(next_prep_time, now);

  if(remaining_ms >= 60 * 60 * 1000)
  {
    std::this_thread::sleep_for(std::chrono::minutes(59));
    return false;
  }
  else if(remaining_ms >= 10 * 60 * 1000)
  {
    std::this_thread::sleep_for(std::chrono::minutes(9));
    return false;
  }
  else if(remaining_ms >= 60 * 1000)
  {
    std::this_thread::sleep_for(std::chrono::seconds(49));
    return false;
  }
  else if(remaining_ms >= 2000)
  {
    std::this_thread::sleep_for(std::chrono::seconds(1));
    return false;
  }
  else if(remaining_ms > 0)
  {
    sleepMaybeNegative(remaining_ms);
    return true;
  }
  return true;
}

bool atTheRealThing(const LocalTime& next_go_time, int query_offset_msecs)
{
  LocalTime now = curLocalTime();
  LocalTime awaited_time = next_go_time;
  awaited_time.addMs(query_offset_msecs);

  int64_t remaining_ms = diffMsTimeOnly(awaited_time, now);

  if(remaining_ms >= 200)
  {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    return false;
  }
  else if(remaining_ms >= 1)
  {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
    return false;
  }
  return true;
}

bool atTheRealThingMinus10Sec(const LocalTime& next_go_time,
                              int query_offset_msecs)
{
  LocalTime now = curLocalTime();
  LocalTime awaited_time = next_go_time;
  awaited_time.addMs(query_offset_msecs - 10 * 1000);

  int64_t remaining_ms = diffMsTimeOnly(awaited_time, now);

  if(remaining_ms >= 300)
  {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    return false;
  }
  sleepMaybeNegative(remaining_ms);
  return true;
}
