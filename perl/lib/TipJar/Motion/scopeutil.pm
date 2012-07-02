package TipJar::Motion::scopeutil;
use strict;
use TipJar::Motion::lexicon;
use parent 'TipJar::Motion::Mote';
sub accept { die "NOT AVAILABLE AS AN ARG TYPE" }
sub import {
   no strict 'refs';
   *{caller().'::PUSHSCOPE'} = \&TipJar::Motion::scopeutil::pushscope::cache;
   *{caller().'::POPSCOPE'} = \&TipJar::Motion::scopeutil::popscope::cache;
};


package TipJar::Motion::scopeutil::pushscope;
use parent 'TipJar::Motion::scopeutil';

### begin Singleton stuff turnable into singleton boilerplate

use TipJar::Motion::configuration;
use feature 'state';
sub type{
  state $T;
  $T ||=
  (        bootstrap_get("PUSHSCOPE")
     ||    bootstrap_set("PUSHSCOPE", new_type __PACKAGE__)
  )
}
sub cache{ state $M; $M ||= do {
   my $MID =
            bootstrap_get("PUSHSCOPE singleton")
         || bootstrap_set("PUSHSCOPE singleton", __PACKAGE__->new->moteid);
   OldMote($MID)
}}

### end Singleton stuff

use TipJar::Motion::null;
sub process { my ($op, $parser) = @_ ;
   my $new = TipJar::Motion::lexicon->new;
   $parser->sponsor($new);
   $new->outer( $parser->lexicon );
   $parser->lexicon($new);
   retnull
};

package TipJar::Motion::scopeutil::popscope;
use parent 'TipJar::Motion::scopeutil';

### begin Singleton stuff turnable into singleton boilerplate

use TipJar::Motion::configuration;
use feature 'state';
sub type{
  state $T;
  $T ||=
  (        bootstrap_get("POPSCOPE")
     ||    bootstrap_set("POPSCOPE", new_type __PACKAGE__)
  )
}
sub cache{ state $M; $M ||= do {
   my $MID =
            bootstrap_get("POPSCOPE singleton")
         || bootstrap_set("POPSCOPE singleton", __PACKAGE__->new->moteid);
   OldMote($MID)
}}

### end Singleton stuff

use TipJar::Motion::null;
sub process { my ($op, $parser) = @_ ;
   my $doomed =  $parser->lexicon;
   my $outer =  $doomed->outer;
   $outer or die "SCOPE OVERPOP";
   $parser->lexicon($outer);
   $parser->unsponsor($doomed);
   retnull
};

1;