
package TipJar::Motion::hereparser;
use strict;
# use parent 'TipJar::Motion::default_parser';
our @ISA = qw'TipJar::Motion::default_parser';
use TipJar::Motion::type 'HEREPARSER';
sub process {  #### override this. The important action happens in  parser()
    my ($me, $parser, $string) = @_;
	my $mote;
	$parser->sponsor(
	  $mote = TipJar::Motion::stringliteral->new
	);
	$mote->string($string);
	$mote
}
sub DEBUG(){1}
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

sub get_token($){my $I = shift;

  my ($c,$ws,$ret);
  while(length ($c = $I->nextchar)){
         if($c =~ /\s/){
			$ws .= $c;
            length $ret and last;
         }else{
            $ret .= $c;
         };
  };
  DEBUG and warn "token: [$ret]";
  ($ws,$ret)
}

sub next_mote{

    my ($pack,$engine) = @_;
    
    my ($ws,$brax);
    $brax = shift @{$engine->parser->prepend};
    if ($brax){
        $brax = $brax->string;
    }else{
        ($ws,$brax) = get_token($engine->input);
    };
    
    DEBUG and warn "bracket token: [$brax]";
	$brax = uc $brax;
    my ($token,$retstring);
    for (;;){
	    ($ws,$token) = get_token($engine->input);
		length $ws or die "HERE: OUT OF DATA LOOKING FOR [$brax]\n";
		$retstring .= $ws;
		$brax eq uc $token and last;
		$retstring .= $token
	};
	$retstring
}

1; 
