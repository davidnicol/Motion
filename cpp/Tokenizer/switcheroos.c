

#include "switcheroos.h"
#include "currenttoken.h"

/*
   InitialSwticheroo decides which tag this token will have
   
   These switcheroos are concerned with how long the tag lasts.

*/

void WhitespaceSwitcheroo(TokenizerStateMachineObject *TSMO, octet c){

      switch (c) {
      
      /* more whitespace? */
    WS_CASES
          AppendToCurrentToken(c);
          return;
          
      /* something other than whitespace */
    default:
          FinalizeCurrentToken(TSMO);
          
          InitialSwitcheroo(TSMO,c);
    };
    
};


void SymbolSwitcheroo(TokenizerStateMachineObject *TSMO, octet c){

      switch (c) {
      
      /* whitespace? */
      WS_CASES
          
          FinalizeCurrentToken(TSMO);
          
          InitialSwitcheroo(TSMO,c);
          return;
          
      /* something other than whitespace */
    default:
    	  AppendToCurrentToken(c);
    };
    

};
