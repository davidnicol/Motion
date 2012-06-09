
@tests = (
              'string ThisIsaString', 'ThisIsaString',
              'another','another',
              'nothing',' ',
              "name p1 string persists p1", "persists",
              "p1 ", "p1",

              "remember p2 string persists p2", "persists",
              "p2","persists",
              "then forget string p2 done","then done",
              "p2","p2" 



);

$fails = 0;
while (@tests){

    my $input = shift @tests;
    my $expected = shift @tests;
    my $output = `echo $input |/usr/bin/perl Motion.pl`;
    s/\s+/ /g for ($expected, $output);
    s/^\s+// for ($expected, $output);
    s/\s+\z//g for ($expected, $output);
    $counter++;
    $expected eq $output and next;
    $fails++;
    print "FAILED TEST $counter\n";
    print "EXPECTED [$expected]\n";
    print "     GOT [$output]\n";
};



print "failed $fails of $counter\n"; 