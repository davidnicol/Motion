
package TipJar::Motion::moteid_format;

=pod

Edit this file to change the format of mote IDs.

Utility functions concerning them.:

=cut
sub import{
  my $c = caller;
  *{join '::',$c,$_} = \&$_ for qw/
new_moteid
looks_like_moteid
normalize
/
}


use Encode::Base32::Crockford qw(:all);

=head2 new_moteid
Mote IDs are twentyfive characters long, representing
one hundred bits, formed by concatenating five
checksummed Crockford-encoded twenty-bit values.

The first is a time value that increments every 64 seconds, taking
just over two years to recycle.

The high fourteen bits of the second, and all of the third, and fifth are random.
The low six bits of the second (the 9th character, and the parity of the 8th)
are where we are in the 64 seconds.

The fourth is an organizational identifier to be used for routing
messages between Motion instances. It is defined in configuration.pm
and defaults to "TEST=".

=cut

my @Randoms;
sub new_moteid{
    # this is more complex than it has to be
    # please waste as little additional time on it as possible.
    if (@Randoms < (5 + rand 10)){
         # srand(rand(3000000000) + time + $$);
         push @Randoms, int rand(90000000) while ( rand(40) > 3);
         push @Randoms, int rand(200000000);
         push @Randoms, int rand(80000000) while ( rand(50) > 2);
         push @Randoms, int rand(100000000);
         push @Randoms, int rand(70000000) while ( rand(60) > 1);
         for my $i ( 0 .. $#Randoms){
             my $j = int rand @Randoms;
             @Randoms[$i,$j] = @Randoms[$j,$i]
         }
    };
    my ($r1,$r2,$r3) = splice @Randoms, 0, 3;
	my $t = time();
    my @X = ( $t >> 6, ($r1 & 0x0FFFFC0) | ($t & 0x0000003F), $r2, $r3 );
    foreach (@X){
	     # four 5-bit characters: 20 bits.
		 # adding 37 * 2 ^ 21 does not change the checksum and makes it 7 chars always.
         $_ = base32_encode_with_checksum( 0x02500000 + ( $_  & 0x000FFFFF ) );
		 s/^15// or die "UNEXPECTED b32 RESULT [$_]"
    };
	# 100 bits: 26 bits of timestamp,  54 bits of random, 20 bits of VMid
    join '',@X[0,1,2],TipJar::Motion::configuration::ourVMid(),$X[3]
}
sub looks_like_moteid($){
  my $candidate = shift;
  my @pieces = $candidate =~ /\A(.....)(.....)(.....)(.....)(.....)\Z/;
  eval { map { base32_decode_with_checksum($_) } @pieces }
};

1;
