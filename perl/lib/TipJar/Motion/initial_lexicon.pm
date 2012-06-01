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
use TipJar::Motion::string;
sub load_IL{
   my $old = bootstrap_get("INITIAL LEX");
   $old and return OldMote($old);
   my $l = OldMote bootstrap_set("INITIAL LEX", TipJar::Motion::lexicon->new->moteid);
   $l->AddTerms(
       'NOTHING' => TipJar::Motion::null->new,        # a no-op mote, or empty return value
	   'STRING' => TipJar::Motion::string->new,       # the next ws-delim char seq becomes a string
	   #HERE      # HERE <token> <text> <same token again> makes text a string
	   #SAFE      creates a limited local scope
	   #NAME      associate a mote with a string
	   #REMEMBER  store a name into the immediately outer scope
	   #SEQUENCE  creates a new template that takes args
	   #PERFORM   fill and run a SEQUENCE
	   #TYPE      creates a new type
	   #MATH
	   #FAIL
	   #HANDLE
	   #LIBRARY
	   #WORKSPACE
	   #MACRO prepends several motes into the stream, for arg lists
	   
	   
   
   )
}

my $IL;
sub initial_lexicon{
   $IL ||= load_IL;   
};

no strict 'refs';

sub import { *{caller().'::initial_lexicon'} = \&initial_lexicon }

1;
