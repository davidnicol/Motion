

=pod

this file contains constructors for macros and sequences.

Syntactically, both macros and sequences are defined between matching
tokens, as HERE strings, with the PLACEHOLDER mote
to specify the argument list they require. They are both compiled as far as
is possible without the placeholders.

Semantically, they are different:

Macros expand immediately and their bodies are prepended to the parser's mote stream.

Sequences are compound ops, which take zero or more args and give one mote, when activated
by the "PERFORM" operator. Otherwise, they evaluate to their moteids.

Macros save names to the immediate lexicon.

Sequences save to their own local scope, and remember to the scope where they were
defined.

Internally, the results of these constructors are user types, with package
names based on their moteIDs, and package code strings that are evalled
at thaw time.

=cut

my @Scopes; # strictly a compile-time construct, need not persist


package TipJar::Motion::placeholder;
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'PLACEHOLDER';
sub is_placeholder{1};
sub UNIVERSAL::is_placeholder{0};
sub accept { 0 }
sub process { Carp::confess "placeholder processed in non-placeholder-aware context" }


package TipJar::Motion::macro;
use parent TipJar::Motion::hereparser;
use TipJar::Motion::type 'MAC CONS';

=pod
we interpret the macro and placeholders into a user type that will
be loaded by the configuration::OldMote function.

the important parts are the parent, the process function, and the argtypearrayref function.
Also, it takes two motes: one mote to be the type of the macro, and another
mote to hold the code.

=cut

use TipJar::Motion::anything;
sub argtypelistref{ [PERLSTRING] }
sub process {
   my $constructor = shift;
   my $parser = shift;
   my $icode = ''.shift;
   my @ArgTypes;  ### will be the argtypelistref of the created type
   my $ocode = <<\PREAMBLE;

use parent 'TipJar::Motion::Mote';
use TipJar::Motion::null;  ### retnull
use TipJar::Motion::configuration;  ### OldMote
sub accept{0};  ### macro definitions are not usable as types at this time
sub process{ my ($self, $P, @args) = @_;
     my @Motes;
PREAMBLE

   my @ARGTYPELIST;
   while ($icode){  # the RAMBLE
        $icode =~ s/\s*(\S+)// or last;
        my $token = $1;
        my $lr = $parser->lexicon->lookup(uc $token);
        $lr or Carp::confess "barewords not allowed in macros; '$token' was not found";
        if (@ARGTYPELIST){
        # we are processing an operand list, placeholders are good here
           my $arg = $lr;
           if ($arg->is_placeholder){
               push @ArgTypes, $ARGTYPELIST[0];
               $ocode .= "push \@Motes, shift \@args;\n";
           }else{
               $ocode .= "push \@Motes, OldMote('$$arg');\n";
           };
           
           shift @ARGTYPELIST;
          
        }else{
        # want an op
          my $op = $lr;
          $ocode .= "push \@Motes, OldMote('$$op');\n";
          @ARGTYPELIST = @{$op->argtypelistref}
        
        }
   
   };
   @ARGTYPELIST and Carp::confess "MACRO DEFINITION ENDS INSIDE OPERAND LIST";
   $ocode .= <<\POSTAMBLE;
    $P->Unshift(  @Motes  );
    retnull
}
POSTAMBLE
    $ocode .= "sub argtypelistref { [ qw/@ArgTypes/ ] }\n";
    TipJar::Motion::configuration::usertype( $parser, $ocode);
    
}

package TipJar::Motion::sequence;
use parent TipJar::Motion::hereparser;
use TipJar::Motion::type 'SEQ CONS';


1;
