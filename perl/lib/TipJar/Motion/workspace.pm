package TipJar::Motion::workspace;
=pod

a persistent lexicon with the parser's scope as it's outer scope.

Replaces the parser's lexicon with itself.


=cut

use parent TipJar::Motion::lexicon;
use TipJar::Motion::type 'WORKSPACE';
use strict;
sub process{ my ($W,$P) = @_;
   $W->comment("workspace within ".$P->lexicon->comment);
   $W->outer($P->lexicon);
   $P->lexicon($W);
   $P
}

1;
