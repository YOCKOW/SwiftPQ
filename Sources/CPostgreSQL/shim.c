/* *************************************************************************************************
 CPostgreSQL/shim.c
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#include "shim.h"
#include <internal/c.h>
#include <pg_config_manual.h>
#include <pgtypes_numeric.h>

bool _SwiftPQ_get_FLOAT8PASSBYVAL() {
  return (bool)FLOAT8PASSBYVAL;
}

int _SwiftPQ_get_NAMEDATALEN() {
  return NAMEDATALEN;
}

bool _SwiftPQ_numericSignIsPositive(int flag) {
  return (flag == NUMERIC_POS) ? true : false;
}

bool _SwiftPQ_numericSignIsNegative(int flag) {
  return (flag == NUMERIC_NEG) ? true : false;
}

bool _SwiftPQ_numericSignIsNaN(int flag) {
  return (flag == NUMERIC_NAN) ? true : false;
}
