/* *************************************************************************************************
 CPostgreSQL/include/shim.h
   © 2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

#ifndef yCPostgreSQL
#define yCPostgreSQL
// Can't put here `#include` headers that are outside of general include directories.
// Rational: https://github.com/swiftlang/swift-package-manager/issues/7850

#include <stdbool.h>

bool _SwiftPQ_get_FLOAT8PASSBYVAL();
int _SwiftPQ_get_NAMEDATALEN();

bool _SwiftPQ_numericSignIsPositive(int flag);
bool _SwiftPQ_numericSignIsNegative(int flag);
bool _SwiftPQ_numericSignIsNaN(int flag);

#endif
