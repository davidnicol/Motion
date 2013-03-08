/*


this is main.c, which contains the main routine for the tokenizer.

We're just taking input from stdin, so we can use getchar instead
of opening files and such.

*/

#include "fundamental.h"


int main(){
       TokenizerStateMachineObject TSMO;
       int c  = getchar_unlocked();
       for(TSMO_init(&TSMO); c!=EOF; c = getchar_unlocked()){
            if(c){
               TSMO_accept(&TSMO,c);
            }else{
               /* handle null byte in input by converting it to UTF-8 zero char */
               TSMO_accept(&TSMO,0xC0);
               TSMO_accept(&TSMO,0x80);
            };
       };
       TSMO_accept(&TSMO,'\0'); /* will be interpreted as end-of-stream */
       TSMO_dump(&TSMO);
}
