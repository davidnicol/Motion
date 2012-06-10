$MRX = '\\b[0-9A-Z*=~$]{25}\\b';  # Moteid REGEX
@tests = (

              'mote', $MRX,

              'string ThisIsaString', 'ThisIsaString',
              'another','another',
              'nothing','',
              "name p1 string persists p1", "persists",
              "p1 ", "p1",

              "remember p2 string persists p2", "persists",
              "p2","persists",
              "then forget string p2 done","then done",
              "p2","p2" ,
              
              
              
              'NewMOTE nm nm',$MRX,
              
              'newmote m setmote m abcd fetchmote m', 'abcd',

              'newmote m store m string def string abcd fetch m def', 'abcd',
      
              'newmote nm name m nm astore m string 5 string abcd afetch nm 5','abcd',
      


              'string string', 'string', # '"STRING" escapes reserved word'

               'heredoc x abc def x', 'abc def',
               #           name: 'GENSYM',
              ' Gensym',  'gs\\d+gs\\d+gs\\d+',


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