

#ifndef FUNDAMENTAL_H
#define FUNDAMENTAL_H

/* 
Motion, intenally, deals with types derived from streams and strings.

Objects may be tagged with a type.

The output of the tokenizer will be tagged strings taken from the input stream.

The operation of the tokenizer will involve a state machine.

Each state is associated with a big case statement which will act based on the next octet from the input stream.

Firstly, the input gets classified as WHITESPACE or NON_WHITESPACE.

Whitespace tokens are boundaries

Additional zero-length boundaries may be inserted into non-ws symbols in later passes

*/

#include "tag_t.h"

typedef unsigned char octet;

struct TTT_t;
typedef struct TTT_t {

     octet *start;
     int  len;
     int line;
     tag_t tag; /* avoid type conversions by declaring all of these once, static */
     unsigned int flags;
     TTT_t *next;

} TokenizerTaggedToken;

TokenizerTaggedToken *NewTTT();

typedef struct {

   TokenizerTaggedToken *head;
   TokenizerTaggedToken *tail;

} TokenizerTaggedTokenList;


#include <stdio.h>
struct TSMO_t;
typedef void (*TokenizerState)(struct TSMO_t*,octet);
typedef struct TSMO_t {
    TokenizerState switcheroo;
    TokenizerTaggedTokenList TTTL;
} TokenizerStateMachineObject;

void TSMO_init(TokenizerStateMachineObject *TSMO);
void TSMO_dump(TokenizerStateMachineObject *TSMO);
void TSMO_accept(TokenizerStateMachineObject *TSMO, octet c);


#endif
