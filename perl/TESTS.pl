$MRX = '[0-9A-Z*=~$]{25}';  # Moteid REGEX
@tests = (

              'enter workspace mote', $MRX,

              'string ThisIsaString', 'ThisIsaString',
              'another','another',
              'nothing','',
              "name p1 string persists p1", "persists",
              "p1 ", "p1",
# 6
              "name p2 string persists remember p2 p2", "persists",
              "p2","persists",
              "then forget p2 done","then done",
              "p2","p2" ,
              
 #10             
              
              'NewMOTE nm nm',$MRX,
              
              'newmote m setmote m abcd fetchmote m', 'abcd',

              'newmote m store m string def string abcd fetch m def', 'abcd',
      
              'newmote nm name m nm astore m string 5 string abcd afetch nm 5','abcd',
      


              'string string', 'string', # '"STRING" escapes reserved word'

               'heredoc x abc def x', 'abc def',
               #           name: 'GENSYM',
              ' Gensym',  'gs\\d+gs\\d+gs\\d+',
              
              'placeholder X','',  # placeholder outside macro-like fails
 #18    
                        
 #  define a sequence
 'name a string abcde name b bcdef name S sequence c a b c S perform S happy',"$MRX abcde bcdef happy",
 'sequence X nothing x', $MRX,
 # an empty sequence
 'sequence Y Y', $MRX,
 # a sequence with a placeholder
 'sequence Y placeholder Y', $MRX,
 # remember a sequence
 'forget sq1
  name sq1
       sequence voom placeholder voom
  sq1
  remember sq1', $MRX,
  # perform a remembered sequence
 'perform sq1 boing nothing','boing',
 
#           name: 'placeholder layering',
'name comma ,
 name is is name what what
 name t test
 name wg heredoc z we got z
 name s1 sequence x
    perform placeholder t wg
    x
 name inner sequence h
    :2 :1 comma :1 is what :2
    h
 perform s1 inner',
 'we got test , test is what we got',
 
 ##############
 #
 # MACROS CAN END WITH HEREDOC BRACKETS
 #
 ##############
 
'enter workspace 
   string newsyntax:
   name closer string */
   name /* macro XX
                     ignore heredoc closer
                 XX
   /* this is a comment */
   ta-daaaah ', 'newsyntax: ta-daaaah',
 
 ##############
 #
 #  WORKSPACES AND SAFE
 #
 ##############
 
 'workspace',$MRX,
              
 'arkle forget wsx blubb forget safe1 bleeb', 'arkle blubb bleeb',
 'name wsx workspace one remember wsx two enter wsx wsx three ' , "one two $MRX three",
 'name abc def enter wsx abc', 'abc', # on entering a ws, old symbols no longer available
 'name abc def name safe1 safe remember safe1 enter safe1 remember abc', 'remember def', # within safe, most names are lost
 'enter safe1 remember abc', 'remember def', # safes can be remembered
 'name abc def evalin wsx heredoc !!! name foo foostring remember foo !!! abc foo', 'def foo',
 'foo enter wsx foo forget foo foo ','foo foostring foo', # remember persists into workspace 
 'name abc def evalin wsx heredoc !!! name foo foostring !!! abc foo', 'def foo',
 'foo enter wsx foo','foo foo',  # name does not persist into workspace
 
 ###################
 #
 #  LIBRARIES, WHICH ARE NOT WORKSPACES
 #  the library name space is separate from the working workspace,
 #  or at least "remember" and "forget" skip libraries when identifying the outer scope
 #
 ###################
 ' enter workspace
     library math_lib
     times 3 5
     plus 99 4
     plus 99 negative 4
     forget cheeseburger
     times 27 cheeseburger', 'SKIP 15 103 95 NaN',
 ' arggh
   forget testlib
   name frib string boogaloo
   name testlib newlibrary
   testlib
   remember testlib
   endmarker', "arggh $MRX endmarker",
 ' arggh
   enter workspace
     library testlib
     frib snabz', 'arggh boogaloo snabz',
 ' enter testlib then do something', 'SKIP fail because testlib is not a workspace',
 ' library wsx then do something', 'SKIP fail because wsx is not a library', 
 

 ##############
 #
 #  EXCEPTIONS AND THEIR HANDLING
 #  see HandlingFailures.txt for details.
 #  
 #  New keywords: base_failure, fail, ignore, handle, failure
 #  are all defined in lib/TipJar/Motion/fail.pm
 #
 ##############
 
 #'moteid base_failure', "SKIP $MRX", # moteid is a primitive that yields its arg's mote id
 #'base_failure', $MRX, # base_failure is a type mote
 'fail base_failure', 'SKIP failure: unspecified failure', # that's what an unhandled base does

 'enter workspace
  name msg string abkeedeph
  handle
     base_failure
     sequence X
        ignore ? msg
  X
  fail base_failure', 'SKIP abkeedeph', # introduce "ignore" too, document amongst the ops 
 
  'enter workspace
  name before string before name afta string afta
  handle
     base_failure
     sequence X
        before ? afta
  X
  fail failure base_failure string the_arg', 'SKIP before the_arg afta', # mess goes to seq 

################
#
#  the "cell" keyword: sugar to create a membrane with enumerated pores
#  cell defines a new safe workspace including the provided list and returns it.
#
################

  ' enter workspace
    name one 1 name two 2 name three 3
    name allowed_words list heredoc LLL one three LLL
    name mycell cell allowed_words
    evalin mycell heredoc X one two three X , then
    enter mycell three two one ', 'SKIP 1 two 3 , then 3 two 1'

);

my @fails;
my @_tests = ( @ARGV ? @tests[map { (2*--$_, 2*$_ + 1) } @ARGV] : @tests);
while (@_tests){
    $counter++;
    my $input = shift @_tests;
    my $expected = shift @_tests;
    if($expected =~ /^SKIP /){ print "SKIPPING ",$counter,"\n"; next };
    my $output = `echo '$input' | /usr/bin/perl Motion.pl`;
    s/\s+/ /g for ($expected, $output);
    $output =~ m/^\s*$expected\s*$/ and next;
    push @fails, $counter;
    print "FAILED TEST $counter\n";
    print "INPUT    [$input]\n";
    print "EXPECTED [$expected]\n";
    print "     GOT [$output]\n";
};



print "failed ${\(0 + @fails)} of $counter: @fails\n"; 
