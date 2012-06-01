package TipJar::Motion::workspace;
=pod

a persistent lexicon with the parser's scope as it's outer scope.

Replaces the parser's lexicon with itself.

the type mote sponsors the workspaces, so they don't get GCd

=cut

use parent TipJar::Motion::lexicon;
use TipJar::Motion::type 'WORKSPACE';

my $typemote = bless \ do { my $T = type() }, 'TipJar::Motion::Mote';

sub init {
  my $W = TipJar::Motion::lexicon::init(shift);
  $typemote->sponsor($W);
  $W
}

sub resign { $typemote -> unsponsor( shift ) }  # after this, should be cleaned on next GC

use strict;
sub process{ my ($W,$P) = @_;
   $W->comment("workspace within ".$P->lexicon->comment);
   $P->sponsor($W);
   $W->outer($P->lexicon);
   $P->lexicon($W);
   TipJar::Motion::null->new
}
package TipJar::Motion::workspace_constructor;
use TipJar::Motion::type 'WSCONS';
use parent 'TipJar::Motion::Mote';
sub process{ my ($self,$P) = @_;
    my $W = TipJar::Motion::workspace->new();
   $P->sponsor($W);
   $W->outer($P->lexicon);
   $P->lexicon($W);
   $W
}

1;
