
@tests = (

              'string ThisIsaString', 'ThisIsaString',
              'another','another',
              'nothing','',
              "name p1 string persists p1", "persists",
              "p1 ", "p1",

              "remember p2 string persists p2", "persists",
              "p2","persists",
              "then forget string p2 done","then done",
              "p2","p2" ,
              
              
              
              'NewMOTE nm nm','\S{25}',
              
              'newmote m setmote m abcd fetchmote m', 'abcd',


#           name: 'MOTE as a-a container',
 'newmote m store m string def string abcd fetch m def', 'abcd',
#      
#           name: 'name creates alias to an already named thing',
#          input: 'newmote nm name m nm astore m string 5 string abcd afetch m 5',
#       expected: 'abcd'
#      

);

$fails = 0;
while (@tests){

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