/* *************************************************************************************************
 CPostgreSQL/shim.c
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#include "shim.h"
#include <internal/c.h>
#include <pg_config_manual.h>

bool _SwiftPQ_get_FLOAT8PASSBYVAL() {
  return (bool)FLOAT8PASSBYVAL;
}

int _SwiftPQ_get_NAMEDATALEN() {
  return NAMEDATALEN;
}
