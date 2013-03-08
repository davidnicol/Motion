

/* TSMO.c  utilities for interfacing with the state machine */
#include "fundamental.h"
#include "switcheroos.h"
#include "currenttoken.h"
#include <stdlib.h>

TokenizerTaggedToken* NewTTT(){
    TokenizerTaggedToken *TTT;
    TTT = (TokenizerTaggedToken*) malloc(sizeof(TokenizerTaggedToken));
    TTT->len = 0;
    TTT->next = NULL;
    TTT->line = CurrentTokenLine();
    return TTT;
}


void InitialSwitcheroo(TokenizerStateMachineObject *TSMO, octet c){

    TokenizerTaggedToken *TTT;
    TTT = NewTTT();
    TSMO->TTTL.tail->next = TTT;
    TSMO->TTTL.tail = TTT;
    /* printf(" Initial switcheroo received octet '%i'\n", 0x00FF & c); */
    switch(c){
    case '\0':
          TTT->tag = TagEndOfStream;
          return;
    WS_CASES
          TSMO->switcheroo = WhitespaceSwitcheroo;
          TTT->tag = TagWhiteSpace;
          break;
    default:
          TSMO->switcheroo = SymbolSwitcheroo;
          TTT->tag = TagSymbol;
    };
    TSMO->switcheroo(TSMO,c);
};
void TSMO_init(TokenizerStateMachineObject *TSMO){
   CurrentTokenInit();
   TSMO->switcheroo = InitialSwitcheroo;
   TSMO->TTTL.head = NewTTT();
   TSMO->TTTL.head->tag = TagBeginStream;
   TSMO->TTTL.tail = TSMO->TTTL.head;
   
};
 
void TSMO_dump(TokenizerStateMachineObject *TSMO){

    TokenizerTaggedToken *TTT;

    for (TTT = TSMO->TTTL.head; TTT; TTT = TTT->next){
         printf(" line %05d: %4d octets of %s: '%s'\n", TTT->line, TTT->len, TAG_TO_STRING(TTT->tag), TTT->start);

    };

};
 
void TSMO_accept(TokenizerStateMachineObject *TSMO, octet c){

      TSMO->switcheroo(TSMO,c);

};

