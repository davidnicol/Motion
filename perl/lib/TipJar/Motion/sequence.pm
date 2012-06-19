

=pod

this file contains constructors for macros and sequences.

Syntactically, both macros and sequences are defined between matching
tokens, as HERE strings, with the PLACEHOLDER mote
to specify the argument list they require. They are both compiled as far as
is possible without the placeholders.

Semantically, they are different:

Macros expand immediately and their bodies are prepended to the parser's mote stream.

Sequences are are macros that can be treated as objects. Like macros, they take zero
or more args and their results are prepended to the parser's mote stream. Unlike
macros, they must be activated by the "PERFORM" operator.

Without "PERFORM" they evaluate to their moteids.

Also, where Macros save names to the immediate lexicon,
Sequences save to their own local scope, and remember to the scope where they were
defined.

As Macros have immediate effect, they cannot be passed as arguments, while
sequences can. So Macros have definite types for their arg lists, and Sequences
only know they number of their arg types.

Internally, the results of these constructors are user types, with package
names based on their moteIDs, and package code strings that are evalled
at thaw time.

PLACEHOLDER does not take an arg like in the previous prototype:
it works like a ? in a SQL statement definition. if you want to name it, do something
like C<name arg1 placeholder> and then use it as C<arg1>.

=cut

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

package TipJar::Motion::sequencetype; # a type for perform to require
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'SEQTYPE';
sub UNIVERSAL::is_a_sequence{0}
sub accept {  $_[1]->is_a_sequence  } # $_[0] got us here


package TipJar::Motion::perform; # PERFORM: op to perform a sequence
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'PERFORM OP';
use TipJar::Motion::null;  ### retnull
use TipJar::Motion::scopeutil;  ### PUSHSCOPE, POPSCOPE
sub argtypelistref{ [TipJar::Motion::sequencetype::type()] }
sub process{ my ($op, $P, $Seq) = @_;
    my $wants = $Seq->PerformTime_argtypelistref;
    warn "Performing sequence, want [@$wants]";
    my @args = $P->getargs($TipJar::Motion::Global::engine,$wants);
    @args == @$wants or die "required [@$wants] but got [@args]";
    warn "got sequence args [@args]";
    my @Filled = $Seq->perform(@args);
    warn "perform yielded [@Filled]";
    $P->Unshift(PUSHSCOPE,@Filled,POPSCOPE);
    retnull
}


### VERY SIMILAR TO MACRO DEFINED ABOVE BUT WITH SOME DIFFERENCES
package TipJar::Motion::sequence;
use strict;
use parent 'TipJar::Motion::hereparser';
use TipJar::Motion::type 'SEQ CONS';

use TipJar::Motion::anything;  ### ANYTHING and PERLSTRING types
sub argtypelistref{ [PERLSTRING] }
sub process {
   my $constructor = shift;
   my $parser = shift;
   my $icode = ''.shift;
   my @SPONSORME;

   my $ocode = <<'PREAMBLE';

use strict;
our @ISA = qw'TipJar::Motion::Mote';
sub is_a_sequence{1}
use TipJar::Motion::configuration;  ### OldMote
sub accept{0};  ### sequence definitions are not usable as types at this time
sub perform{ my ($self, @args) = @_;         # support PERFORM verb
   my @Motes;
PREAMBLE

   my $icode2 = $icode;
   $icode2 =~ s/^/###   /mg;
   $ocode .= <<SOURCE;
### SOURCE:
$icode2   
SOURCE

   my @ARGTYPELIST;
   my ($i,$max_i);
   while ($icode){  # the RAMBLE
        $icode =~ s/\s*(\S+)// or last;
        my $token = $1;
        warn "seq cons got token [$token]";
      if ($token =~ /^:(\d+)$/){
               $i = $1 - 1;
               $i > $max_i and $max_i = $i;
               $ocode .= "push \@Motes, \$args[$i];\n";
        
      }else{
        warn "looking up token [$token]";
        $token = uc $token;
        my $lr = $parser->lexicon->lookup($token);
        warn "seq cons got mote [$lr]";
        ref $lr or Carp::confess "barewords not allowed in sequences: '$token' was not found";
        if ($lr->is_placeholder){
               push @ARGTYPELIST, ANYTHING;
               $ocode .= "push \@Motes, shift \@args;\n";
        }else{
               push @SPONSORME, $lr;
               $ocode .= "push \@Motes, OldMote('$$lr');\n";
               $ocode .= "warn qq{ after including $$lr, retlist now [\@Motes]};\n";
        };
      }
   };
   if (defined $i){
       @ARGTYPELIST and die "PLACEHOLDER STYLES MAY NOT MIX";
       @ARGTYPELIST = (ANYTHING) x (1 + $max_i)
   };
   $ocode .= <<'POSTAMBLE';
 @Motes  # the PERFORM verb unshifts this into parser->prepend
}
POSTAMBLE
    $ocode .= "sub PerformTime_argtypelistref { [ qw/@ARGTYPELIST/ ] }\n";
    my $newSeq = TipJar::Motion::configuration::usertype( $parser, $ocode);
    warn "source code for $newSeq is:\n$ocode\n--";
    $newSeq->sponsor($_) for @SPONSORME;
    $newSeq;
}

1;
