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
#include <pgtypes_error.h>
#include <pgtypes_numeric.h>
#include <pgtypes_timestamp.h>

static inline void _SwiftPQ_PGTYPES_free_cString(char * _Nonnull string) {
  PGTYPESchar_free(string);
}

/// Returns `NULL` if `string` is invalid for timestamp.
static inline int64_t * _Nullable _SwiftPQ_PGTYPES_timestamp_from_cString(
  const char * _Nonnull string,
  int64_t * _Nonnull result
) {
  errno = 0;
  const int64_t timestamp = PGTYPEStimestamp_from_asc(string, NULL);
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
