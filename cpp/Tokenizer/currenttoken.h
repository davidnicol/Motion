#ifndef CURRENTTOKEN_H
#define CURRENTTOKEN_H
#include "fundamental.h"

/* methods for adding an octet to the current token, and getting its length and starting
address when it is finalized with its trailing null */

void FinalizeCurrentToken(TokenizerStateMachineObject *TSMO);
int CurrentTokenLen();
int CurrentTokenLine();
char *CurrentTokenStart();
void AppendToCurrentToken(unsigned char);
void CurrentTokenInit();

#endif