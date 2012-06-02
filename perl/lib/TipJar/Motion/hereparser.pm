
package TipJar::Motion::hereparser;
use strict;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'HEREPARSER';
sub process {
    my ($me, $parser, $string) = @_;
	my $mote;
	$parser->sponsor(
	  $mote = TipJar::Motion::stringliteral->new
	);
	$mote->string($string);
	$mote
}
sub accept { 
  not ref $_[1] # we want a string scalar not a mote
}

=head1 hereparser

this package is used as a base class
for packages that take variadic arguments.

The immediately following token serves as both
the begin and end token around the body.

The text between the identical bracketing tokens
is provided to the subclass's process method as
a string argument.

Without a subclass, its process method takes
that string argument and returns a string mote.


=cut
sub parser { 
    __PACKAGE__;
}

sub argtypelistref { [ type() ] } # we accept only unblessed strings

sub yield_returnable { die "nonreturnable type" }

package TipJar::Motion::string::parser;

sub get_token($){my $I = shift

  my ($c,$ws,$ret);
  while(length ($c = $engine->input->nextchar)){
         if($c =~ /\s/){
            length $ret and last;
			$ws .= $c
         }else{
            $ret .= $c;
         };
  };
  ($ws,$ret)
}

sub next_mote{

    my ($pack,$engine) = @_;
    
    my ($ws,$brax) = get_token($engine->input);
	$brax = uc $brax;
    my ($token,$retstring);
    for (;;){
	    ($ws,$token) = get_token($engine->input);
		length $ws or die "HERE: OUT OF DATA LOOKING FOR [$brax]\n";
		$retstring .= $ws;
		$brax eq uc $token and last;
		$restring .= $token
	};
	$retstring
}

1; 
