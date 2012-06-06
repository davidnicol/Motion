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
	   'ENDMACRO' => TipJar::Motion::endmacro->new,
	   'PLACEHOLDER' => TipJar::Motion::placeholder->new,
	   
	   
## the 2011 test suite:
#	       name: 'NEWMOTE [name] expands to NAME [name] MOTE',
#          input: 'NewMOTE nm nm',
#       expected: '\\d+[A-Za-z]+'
## defined below       'NEWMOTE' 
#      
#           name: 'MOTE as scalar container',
#          input: 'newmote m setmote m string abcd fetchmote m',
#       expected: 'abcd'
#      
#           name: 'MOTE as a-a container',
#          input: 'newmote m store m string def string abcd fetch m def',
#       expected: 'abcd'
#      
#           name: 'name creates alias to an already named thing',
#          input: 'newmote nm name m nm astore m string 5 string abcd afetch m 5',
#       expected: 'abcd'
#      
#           name: 'MOTE yields mote id',
#          input: 'MOTE',
#       expected: '\\d+[A-Za-z]+'
#      
#           name: 'MOTE as scalar container',
#          input: 'name m MOTE setmote m string abcd fetchmote m',
#       expected: 'abcd'
#      
#           name: 'MOTE as a-a container',
#          input: 'name m MOTE store m string def string abcd fetch m def',
#       expected: 'abcd'
#      
#           name: 'MOTE as array container',
#          input: 'name m MOTE astore m string 5 string abcd afetch m 5',
#       expected: 'abcd'
#      
#           name: 'NOTHING',
#          input: 'abc nothing def',
#       expected: 'abc def'
#      
#           name: 'placeholder is an error',
#          input: ' placeholder x',
#       expected: 'FAIL PLACEHOLDER_INVOKED_OUTSIDE_OF_SEQUENCE_DEFINITION x'
#      
#           name: 'GENSYM',
#          input: ' Gensym',
#       expected: 'gs\\d+gs\\d+gs\\d+'
#      
#           name: '"STRING" escapes reserved word',
#          input: 'string string',
#       expected: 'string'
#     
#           name: 'unknown keywords pass through unchanged',
#          input: 'abcd',
#       expected: 'abcd'
#     
#           name: 'heredoc',
#          input: 'heredoc x abc def x',
#       expected: 'abc def'
#     
#           name: 'only listed symbols are available within safe',
#          input: 'name a aa name b bb perform safe a begin a b end',
#       expected: 'aa b'
#     
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
#           name: 'perform a named sequence',
#          input: 'name q sequence x abcdef x perform Q',
#       expected: 'abcdef'
#     
#           name: 'placeholder in a sequence',
#          input: 'perform sequence x a placeholder a b A e x cd',
#       expected: 'a b cd e'
#     
#           name: 'placeholder layering',
#          input: 'name s1 sequence x placeholder S perform S test x name inner sequence h placeholder i we got i , i is what we got h perform s1 inner',
#       expected: 'we got test , test is what we got'
     
   
   
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
