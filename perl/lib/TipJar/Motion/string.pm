
package TipJar::Motion::stringliteral;
our @ISA = qw/TipJar::Motion::string/;
use TipJar::Motion::type 'STRINGLIT';
sub argtypelistref {[]}
sub process {$_[0]}
sub is_a_string { 1 }

package TipJar::Motion::gensym;  # symbol creator
our @ISA = qw/TipJar::Motion::Mote/;
use TipJar::Motion::type 'GENSYM';
sub argtypelistref {[]}
sub process {
     my ($A,$B,$C) = map{ int(99999 + rand(9999999)) }(1,2,3);
     my $r = TipJar::Motion::stringliteral->new;
     $r->string("gs${A}gs${B}gs${C}");
     $r
}


sub UNIVERSAL::is_a_string { 0 }
package TipJar::Motion::string;
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'STRING';
sub import  { *{caller().'::STRING'} = sub () { __PACKAGE__->type } }
use TipJar::Motion::configuration;
BEGIN { *string = accessor('string') }
use strict;
sub accept { my $ret; eval {$ret = $_[1]->is_a_string;1} or Carp::confess $@; $ret }

=head1 the STRING keyword allows the
following token to be read as a string literal.
This requires an alternative parser.


=cut
sub parser { my ($op, $parser) = @_; 
    # leave a prepend stack alone
    $parser->prepend->[0] and return $parser;
    # warn "returning string parser package name";
    'TipJar::Motion::string::parser';

}

sub argtypelistref { [ TipJar::Motion::stringliteral->type ] }

sub process { my ($self, $parser, $S) = @_; $S }

sub yield_returnable { $_[0]->string }

sub become { $_[0] };

package TipJar::Motion::string::parser;
use parent 'TipJar::Motion::default_parser';
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
