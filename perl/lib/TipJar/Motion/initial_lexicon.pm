package TipJar::Motion::initial_lexicon;
use strict;
=pod
this package provides a function for use by the default parser
object that identifies and returns the initial lexicon.

In a fresh installation, the lexicon will be created.

=cut

use TipJar::Motion::configuration;
use TipJar::Motion::lexicon;
use TipJar::Motion::null;
sub load_IL{
   my $old = bootstrap_get("INITIAL LEX");
   $old and return OldMote($old);
   my $l = OldMote bootstrap_set("INITIAL LEX", TipJar::Motion::lexicon->new->moteid);
   $l->AddTerms(
       'NOTHING' => TipJar::Motion::null->new,
   
   )
}

my $IL;
sub initial_lexicon{
   $IL ||= load_IL;   
};

no strict 'refs';

sub import { *{caller().'::initial_lexicon'} = \&initial_lexicon }

1;
