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
use TipJar::Motion::name;
use TipJar::Motion::string;
use TipJar::Motion::workspace;
use TipJar::Motion::hereparser;
use TipJar::Motion::sequence;
sub load_IL{
   my $old = bootstrap_get("INITIAL LEX");
   $old and return OldMote($old);
   warn "constructing new initial lexicon\n";
   my $l = OldMote bootstrap_set("INITIAL LEX", TipJar::Motion::lexicon->new->moteid);
   $l->AddTerms(
       'NOTHING' => TipJar::Motion::null->new,        # a no-op mote, or empty return value
	   'STRING' => TipJar::Motion::string->new,       # the next ws-delim char seq becomes a string
	   # HERE <token> <text> <same token again> makes text a string
	   'HEREDOC' => TipJar::Motion::hereparser->new,
	   #NAME      op to associate a mote with a string key in the current lexicon
	   'NAME' =>  TipJar::Motion::name->new,
       'MOTE' => TipJar::Motion::Mote_constructor->new,
	   #REMEMBER  op to store a name into the immediately outer scope, same syntax as NAME
	   'REMEMBER' =>  TipJar::Motion::remember->new,
	   'FORGET'   => TipJar::Motion::forget->new,
	   #SEQUENCE  creates a new template that takes args
	   #PERFORM   fill and run a SEQUENCE
	   #TYPE      creates a new type
	   #MATH
	   #FAIL
	   #HANDLE
	   #LIBRARY op to insert a lexicon into the current lexicon chain (AddLex method)
	   #WORKSPACE op to construct a new workspace under the current one
	   'WS1' => TipJar::Motion::workspace->new,
	   'WORKSPACE' => TipJar::Motion::workspace_constructor->new,
	   #OUTER op to obtain the moteID of the outer workspace that REMEMBER saves names into
	   #SAFE  op to create a limited workspace
	   'SAFE' => TipJar::Motion::safe->new,
	   #MACRO prepends several motes into the stream, for arg lists
	   #USERPACK op to define a perl package in the implementation language (perl, for now)
	   ############ USERPACK is not safe and should only be included in "wet" trusted workspaces

	   ## the NEWMOTE macro definition is:
	   ##    remember newmote macro name placeholder mote endmacro
	   ### requiring:
	   'MACRO'    => TipJar::Motion::macro->new,
	   'SEQUENCE'    => TipJar::Motion::sequence->new,
	   'PERFORM'    => TipJar::Motion::perform->new,
	   'PLACEHOLDER' => TipJar::Motion::placeholder->new,
	   'SETMOTE' => TipJar::Motion::setmote->new,
	   'FETCHMOTE' => TipJar::Motion::fetchmote->new,
	   'STORE' => TipJar::Motion::store->new,
	   'FETCH' => TipJar::Motion::fetch->new,
	   'ASTORE' => TipJar::Motion::astore->new,
	   'AFETCH' => TipJar::Motion::afetch->new,
	   'GENSYM' => TipJar::Motion::gensym->new,
	   
	   
## the 2011 test suite is slowly getting deleted from here as it moves to TESTS.pl


#           name: 'safe syntax',
#          input: 'name a aa name b bb perform safe a begin a b',
#       expected: '[\\s\\S]+SYNTAX[\\s\\S]+'
#     
#           name: 'safe syntax',
#          input: 'name a aa name b bb perform safe a b',
#       expected: '[\\s\\S]+SYNTAX[\\s\\S]+'
#     
#           name: 'names are case-insensitive',
#          input: 'name q heredoc x abc def x Q',
#       expected: 'abc def'
#     
#           name: 'ephemeral mote identifiers include type',
#          input: 'sequence x abcdef x ',
#       expected: '\\d+SEQUENCE'
#     
#           name: 'name nothing fail',
#          input: 'a name a',
#       expected: 'a fail name_missing_thing'
#     
#           name: 'name noname fail',
#          input: 'a name',
#       expected: 'a fail name_missing_name'
#     

     
   
   
   );
   ##### initial motes defined in terms of core motes
   $l->ParseString(<<PHASE2);
remember newmote macro X name placeholder mote X
PHASE2
   $l
}

my $IL;
sub initial_lexicon{
   $IL ||= load_IL;
};

no strict 'refs';

sub import { *{caller().'::initial_lexicon'} = \&initial_lexicon }

1;
