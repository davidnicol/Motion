$MRX = '\\b[0-9A-Z*=~$]{25}\\b';  # Moteid REGEX
@tests = (

              'mote', $MRX,

              'string ThisIsaString', 'ThisIsaString',
              'another','another',
              'nothing','',
              "name p1 string persists p1", "persists",
              "p1 ", "p1",
# 6
              "remember p2 string persists p2", "persists",
              "p2","persists",
              "then forget string p2 done","then done",
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
 
#           name: 'perform a named sequence',
 'name q sequence x abcdef x perform Q', 'abcdef',
#     
#           name: 'placeholder in a sequence',
 'perform sequence x a name a placeholder b A e x cd', 'a b cd e',

#           name: 'placeholder layering',
'name s1 sequence x
    perform placeholder test
    x
 name inner sequence h
    name i placeholder i we got i , i is what we got h perform s1 inner',
 'we got test , test is what we got',
 
 
              # 'only listed symbols are available within safe',
              'name a alpha name b zzz perform safe a begin a b end', 'alpha b',
#     


);

$fails = 0;
while (@tests){
    $counter > 20 and last;
    my $input = shift @tests;
    my $expected = shift @tests;
    my $output = `echo $input |/usr/bin/perl Motion.pl`;
    s/\s+/ /g for ($expected, $output);
    $counter++;
    $output =~ m/^\s*$expected\s*$/ and next;
    $fails++;
    print "FAILED TEST $counter\n";
    print "INPUT    [$input]\n";
    print "EXPECTED [$expected]\n";
    print "     GOT [$output]\n";
};



print "failed $fails of $counter\n"; 