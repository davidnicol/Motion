

/* this is switcheroos.h, with a named entry for every (or at least many)
   of the possible switcheroo functions. */
#ifndef SWITCHEROOS_H
#define SWITCHEROOS_H

#include "fundamental.h"

#define WS_CASES case ' ': case '\t': case '\f': case '\v': case '\n': case '\r':

void InitialSwitcheroo(TokenizerStateMachineObject *TSMO, octet c);
void WhitespaceSwitcheroo(TokenizerStateMachineObject *TSMO, octet c);
void SymbolSwitcheroo(TokenizerStateMachineObject *TSMO, octet c);



#endif
