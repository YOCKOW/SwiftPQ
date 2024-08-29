/* *************************************************************************************************
 CLibECPG/shim.h
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#ifndef yCLibECPG
#define yCLibECPG
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <pgtypes_date.h>
#include <pgtypes_error.h>
#include <pgtypes_numeric.h>
#include <pgtypes_timestamp.h>

typedef struct {
  int year;
  int month;
  int day;
} _SwiftPQ_PGTYPES_YMD;

static inline int32_t * _Nullable _SwiftPQ_PGTYPES_date_from_cString(const char * _Nonnull string,
                                                                     int32_t * _Nonnull result) {
  errno = 0;
  const int32_t pgDate = PGTYPESdate_from_asc((char *)string, NULL);
  if (errno != 0) {
    return NULL;
  } else {
    *result = pgDate;
    return result;
  }
}

static inline void _SwiftPQ_PGTYPES_date_from_ymd(const _SwiftPQ_PGTYPES_YMD * _Nonnull ymd,
                                                  int32_t * _Nonnull result) {
  int mdy[3] = {ymd->month, ymd->day, ymd->year};
  date pgDate = 0;
  PGTYPESdate_mdyjul(mdy, &pgDate);
  *result = (int32_t)pgDate;
}

static inline void _SwiftPQ_PGTYPES_date_to_ymd(int32_t pgDate,
                                                _SwiftPQ_PGTYPES_YMD * _Nonnull result) {
  int mdy[3] = {0};
  PGTYPESdate_julmdy((date)pgDate, mdy);
  result->year = mdy[2];
  result->month = mdy[0];
  result->day = mdy[1];
}

static inline char * _Nonnull _SwiftPQ_PGTYPES_date_to_cString(int32_t pgDate) {
  return PGTYPESdate_to_asc((date)pgDate);
}

static inline void _SwiftPQ_PGTYPES_free_cString(char * _Nonnull string) {
  PGTYPESchar_free(string);
}

/// Returns `NULL` if `string` is invalid for timestamp.
static inline int64_t * _Nullable _SwiftPQ_PGTYPES_timestamp_from_cString(
  const char * _Nonnull string,
  int64_t * _Nonnull result
) {
  errno = 0;
  const int64_t timestamp = PGTYPEStimestamp_from_asc((char *)string, NULL);
  if (errno == PGTYPES_TS_BAD_TIMESTAMP) {
    return NULL;
  } else {
    *result = timestamp;
    return result;
  }
}

static inline char * _Nonnull _SwiftPQ_PGTYPES_timestamp_to_cString(int64_t timestamp) {
  return PGTYPEStimestamp_to_asc(timestamp);
}

#endif
