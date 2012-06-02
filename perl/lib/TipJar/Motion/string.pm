
package TipJar::Motion::stringliteral;
our @ISA = qw/TipJar::Motion::string/;
use TipJar::Motion::type 'STRINGLIT';
sub argtypelistref {[]}
sub process {$_[0]}
sub accept { ref $_[1] eq __PACKAGE__ }

package TipJar::Motion::string;
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'STRING';
sub import  { *{caller().'::STRING'} = sub () { __PACKAGE__->type } }
use TipJar::Motion::configuration;
BEGIN { *string = accessor('string') }
use strict;

=head1 the STRING keyword allows the
following token to be read as a string literal.
This requires an alternative parser.


=cut
sub parser { 
    # warn "returning string parser package name";
    'TipJar::Motion::string::parser';

}

sub argtypelistref { [ TipJar::Motion::stringliteral->type ] }

sub process { my ($self, $parser, $S) = @_; $S }

sub yield_returnable { $_[0]->string }

sub become { $_[0] };

package TipJar::Motion::string::parser;
sub next_mote{
    my ($pack,$engine) = @_;
    
     my $c;
     my $string = '';
     # "defined" won't work because (uc undef) is '' not undef
     while(length ($c = $engine->input->nextchar)){
         # warn "string: [$string]";
         if($c =~ /\s/){
            length $string and last;
         }else{
            $string .= $c;
         };
     };
     my $S = TipJar::Motion::stringliteral->new;
     $S->string($string);

   $S
}

1; 
