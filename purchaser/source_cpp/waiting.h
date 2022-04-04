#ifndef LOANS_WAITING_H_
#define LOANS_WAITING_H_

#include "time_util.h"

LocalTime getNextGoTime();

LocalTime getNextPrepTime();

bool areWeThereYet(const LocalTime& next_prep_time);

bool atTheRealThing(const LocalTime& next_go_time, int query_offset_msecs);

bool atTheRealThingMinus10Sec(const LocalTime& next_go_time,
                              int query_offset_msecs);

#endif // LOANS_WAITING_H_
