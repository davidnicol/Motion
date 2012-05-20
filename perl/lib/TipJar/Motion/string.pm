package TipJar::Motion::string;
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'STRING';
sub import  { *{caller().'::STRING'} = sub () { __PACKAGE__->prototype } }
use TipJar::Motion::configuration;
BEGIN { *string = accessor }
use strict;

=head1 the STRING keyword allows the
following token to be read as a string literal.
This requires an alternative parser.


=cut
sub parser { 

    'TipJar::Motion::string::parser';

}

sub wants2 { [ __PACKAGE__->prototype ] }

sub process { my ($self, $parser, $S) = @_; $S }

sub yield_returnable { $_[0]->string }


package TipJar::Motion::string::parser;
sub next_mote{
    my ($pack,$engine) = @_;
    
     my $c;
     my $string = '';
     while(defined ($c = uc $engine->input->nextchar)){
         if($c =~ /\s/){
            length $string and last;
         }else{
            $string .= $c;
         };
     };
     length $string or return undef;
     my $S = TipJar::Motion::string->new;
     $S->string($string);

   $S
}

1; 
