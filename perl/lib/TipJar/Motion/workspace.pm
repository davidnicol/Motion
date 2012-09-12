package TipJar::Motion::workspace;
=pod

a persistent lexicon with the parser's scope as it's outer scope.

Replaces the parser's lexicon with itself.

=cut

use parent TipJar::Motion::lexicon;
use TipJar::Motion::type 'WORKSPACE TYPE';

sub argtypelistref { [ ] }
sub process { $_[0] }
sub UNIVERSAL::is_workspace{0}
sub is_workspace{1}
sub accept { $_[1]->is_workspace() }


package TipJar::Motion::library;

=pod

an associative array, not a lexicon.
Copied into the current scope with the LIBRARY operator.
Includes the same things that would be included in a SAFE.

=cut

use parent TipJar::Motion::lexicon;
use TipJar::Motion::type 'LIBRARY TYPE';
sub argtypelistref { [ ] }
sub process { $_[0] }
sub UNIVERSAL::is_library{0}
sub is_library{1}
sub accept { $_[1]->is_library() }


package TipJar::Motion::workspace_enter_op;
use strict;
use TipJar::Motion::type 'WS ENTER OP';
use parent 'TipJar::Motion::Mote';
sub argtypelistref { [ TipJar::Motion::workspace::type() ] }
sub process{ my ($op,$P,$W) = @_; # overwrite parser's workspace
   $P->sponsor($W);
   $P->lexicon($W); # overwrite previous workspace
   TipJar::Motion::null->new
}
package TipJar::Motion::library_op;
use strict;
use TipJar::Motion::type 'LIBRARY OP';
use parent 'TipJar::Motion::Mote';
sub argtypelistref { [ TipJar::Motion::library::type() ] }
sub process{ my ($op,$P,$L) = @_; # copy terms from $L into current space
   my @terms = keys %{$L->aa};
   warn "importing [@terms] from library";
   @{$P->lexicon->aa}{@terms} = @{$L->aa}{@terms};
   warn "$_ is a ". ref $P->lexicon->aa->{$_} for @terms;
   TipJar::Motion::null->new
}

package TipJar::Motion::evalin_op;
use TipJar::Motion::type 'WS EVALIN OP';
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::string;
use TipJar::Motion::null;
use TipJar::Motion::fail;
sub argtypelistref { [ TipJar::Motion::workspace::type(), STRING ] }
sub process{ my ($op,$P,$WS,$string) = @_; # overwrite parser's workspace
   my @results = eval { ( $WS->ParseString( $string->string ), retnull ) };
   @results or Mthrow("EVALIN: $@");
   $P->sponsor($_) for @results;
   @results
}

package TipJar::Motion::workspace_constructor;
use TipJar::Motion::type 'WSCONS';
use parent 'TipJar::Motion::Mote';
sub process{ my ($self,$P) = @_;  # create a new workspace linked to current 
   my $W = TipJar::Motion::workspace->new();
   $W->comment("workspace within ".$P->lexicon->comment);
   $P->sponsor($W);
   $W->outer($P->lexicon);
   $W
}

package TipJar::Motion::safe;
# constructor mote for a safe environment.
use TipJar::Motion::type 'SAFECONS OP';
use parent 'TipJar::Motion::Mote';
sub process{ my ($self,$P) = @_;  # create a new workspace linked to current 
   my $W = TipJar::Motion::workspace->new();
   my $Plexaa;
   my @terms = keys %{$Plexaa = $P->lexicon->aa};
   $W->comment("SAFE containing @terms");
   $P->sponsor($W);
   @{$W->aa}{@terms} = @{$Plexaa}{@terms};
   $W
}

package TipJar::Motion::newlibrary_op;
# constructor mote for a safe environment.
use TipJar::Motion::type 'LIBRARY CONS OP';
use parent 'TipJar::Motion::Mote';
sub process{ my ($self,$P) = @_;  # create a new library containing current terms 
   my $L = TipJar::Motion::library->new();
   $P->sponsor($L);
   %{$L->aa} = %{$P->lexicon->aa};
   my @terms = keys %{$L->aa};
   $L->sponsor($L->aa->{$_}) for @terms;
   warn "NEW LIB CONTAINS: @terms";
   $L
}


1;
