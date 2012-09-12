package TipJar::Motion::name;
use strict;
=head1

this package is an OP that takes two arguments, the first
a STRING and the second is ANYTHING.

The ANYTHING gets stored in the parser's lexicon under the name.

=cut

use parent 'TipJar::Motion::Mote';
use strict;
use TipJar::Motion::type 'NAME';
use TipJar::Motion::string;
use TipJar::Motion::anything;
use TipJar::Motion::null;

sub argtypelistref{ [STRING, ANYTHING] };

sub process { my ($op, $parser, $name, $thing) = @_;
  my $lex = $parser->lexicon;
  my $name = uc $name->string;
  warn "adding thing $thing to lex [".$lex->comment."] as name $name";
  ${$lex->aa}{$name} = $thing;
  retnull
}

package TipJar::Motion::remember;
use TipJar::Motion::string;
sub argtypelistref{ [STRING] };

use TipJar::Motion::type 'REMEMBER';
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::null;
sub process { my ($op, $parser, $name) = @_;
  $name = uc $name->string;
  exists ${$parser->lexicon->aa}{$name} or die "ATTEMPT TO REMEMBER NONEXISTENT NAME [$name]";
  ${$parser->lexicon->outer->aa}{$name} = ${$parser->lexicon->aa}{$name};
  retnull
}

package TipJar::Motion::forget;
use TipJar::Motion::type 'FORGET';
our @ISA = qw'TipJar::Motion::remember';
use TipJar::Motion::null;
use TipJar::Motion::string;
use TipJar::Motion::anything;
sub argtypelistref{ [STRING] };
sub process { my ($op, $parser, $name) = @_;
  $name = uc $name->string;
  delete ${$parser->lexicon->outer->aa}{$name};
  delete ${$parser->lexicon->aa}{$name};
  retnull
}

package TipJar::Motion::pull; 
use TipJar::Motion::type 'PULL OP';
our @ISA = qw'TipJar::Motion::remember';
use TipJar::Motion::null;
use TipJar::Motion::string;
use TipJar::Motion::anything;
sub process { my ($op, $parser, $name) = @_;
  $name = uc $name->string;
  my $LR = $parser->lexicon->outer->lookup($name);
  $LR or die "ATTEMPT TO PULL NONEXISTENT NAME [$name]";
  ${$parser->lexicon->aa}{$name} = $LR;
  retnull
}
package TipJar::Motion::pullas; 
use TipJar::Motion::type 'PULLAS OP';
our @ISA = qw'TipJar::Motion::Mote';
use TipJar::Motion::null;
use TipJar::Motion::string;
sub argtypelistref{ [STRING,STRING] };
sub process { my ($op, $parser, $alias, $name) = @_;
  $name = uc $name->string;
  $alias = uc $alias->string;
  my $LR = $parser->lexicon->outer->lookup($name);
  $LR or die "ATTEMPT TO PULL NONEXISTENT NAME [$name]";
  ${$parser->lexicon->aa}{$alias} = $LR;
  retnull
}

package TipJar::Motion::moteid_op; 
use TipJar::Motion::type 'moteid OP';
our @ISA = qw'TipJar::Motion::Mote';
use TipJar::Motion::null;
use TipJar::Motion::string;
use TipJar::Motion::anything;
sub argtypelistref{ [ANYTHING] };
sub process { my ($op, $parser, $arg) = @_;
     my $moteid = $$arg;
     warn "op: $op";
     warn "parser: $parser";
     warn "arg: $arg";
     warn "moteid: $moteid";
     my $r = TipJar::Motion::stringliteral->new;
     $r->string(" $moteid ");
     $r
}

1;

