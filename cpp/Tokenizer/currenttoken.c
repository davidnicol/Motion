
/* methods for adding an octet to the current token, and getting its length and starting
address when it is finalized with its trailing null

Should we be so moved we may change this to track offsets inside big buffers
instead of mallocing each token, but for now that should work.

*/

#include "currenttoken.h"
#include <string.h>
#include <stdlib.h>


static int LineCounter;
static int Buffersize;
static unsigned char *Buffer;
static int size;

void CurrentTokenInit(){
  LineCounter = 1;
  Buffersize = 65000;
  Buffer = (unsigned char*) malloc(Buffersize);  
  size = 0;
};

void AppendToCurrentToken(unsigned char c){
    if ( c == '\n' ) LineCounter++;
    Buffer[size++] = c;
    if (size >= Buffersize){
          Buffersize *= 1.7;
          Buffer = (unsigned char*) realloc(Buffer, Buffersize);
    }
};

void FinalizeCurrentToken(TokenizerStateMachineObject *TSMO){
    unsigned char *FinalBuffer;
    AppendToCurrentToken('\0');
    TSMO->TTTL.tail->len = size - 1;
    TSMO->TTTL.tail->start = FinalBuffer = (unsigned char*) malloc(size);
    memcpy(FinalBuffer, Buffer, size);
    size = 0;
    
};

int CurrentTokenLine(){ return LineCounter ;}
