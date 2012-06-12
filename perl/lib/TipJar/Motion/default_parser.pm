
package TipJar::Motion::default_parser;
sub DEBUG(){0}
use TipJar::Motion::type 'PARSER';
use TipJar::Motion::configuration;
use parent TipJar::Motion::Mote;
sub import { *{caller().'::PARSER'} = \&type}
use strict;
use TipJar::Motion::lexicon;
use TipJar::Motion::list;
*lexicon = TipJar::Motion::configuration::accessor('parser-lexicon');
*prepend = TipJar::Motion::configuration::accessor('parser-prepend');

use TipJar::Motion::initial_lexicon;
sub init{
   my $P = shift;
   $P->lexicon($P->sponsor( TipJar::Motion::lexicon->new))->comment("parser_init");
# AddLex ads a copy of the named lexicon into the
# invocant's outer chain. It does not add the operand's outers too.
# each new one pushes the others farther out, so list them
# from the outside in.
   $P->lexicon ->AddLex(initial_lexicon);
   $P->prepend($P->sponsor(TipJar::Motion::list->new));
   $P
}
sub inner_scope{
  my $P = shift;
  my $new = $P->new;
  $new->lexicon->outer($P->lexicon);
  $new
}
sub Unshift { my $P = shift; unshift @{$P->prepend}, @_ }

=pod

this package demonstrates the interface for the motion parser.

The parser interface is called by the ENGINE.

head2 next_mote
C<next_mote(ENGINE)> returns a mote.
It does this by reading characters from the
engine's input character stream until it has enough
to specify a mote -- either a mote identifier, or a word
in the current lexicon -- and if that mote represents
an operator that takes operands, it gets those too,
and runs the operator on the operands, then returns
the result.

A read mote may replace the parser, or clear the lexicon,
or both.

By default, the parser reads a series of Crockford characters
(since that's what's in mote IDs) before consulting the lexicon.
=cut



my $depth = 0;
sub getargs{ my ($subparser, $engine, $wants) = @_;
      my @args;
      my $i; $depth++;
eval {
      for my $w (@$wants){ ++$i;
        warn ">>> $depth $i $w require operand ".readscalar($w);
        my $arg = $subparser->next_mote($engine);
        warn "<<< $depth $i $w got operand ".ref($arg);
        readscalar($w)->accept($arg) or die "ARG TYPE MISMATCH";
        push @args, $arg;
      };1
} or Carp::confess "getargs: $@";
      $depth--;
      @args
};


sub get_mote{ my $parser = shift; my $engine = shift;
    ref $parser or Carp::confess( "$parser is not a real parser object");
    my $lookup_result;
    DEBUG and warn "checkpoint";
    my $c;
    my $string = '';
    while(defined ($c = $engine->input->nextchar)){
        if($c =~ /\s/){
           length $string and last;
        }else{
           $string .= $c;
        };
    };
    length $string or return undef;
	my $orig_string = $string;
	$string = uc $string;
    # look up $string in lexicon or old mote table
       # DEBUG and
	   warn "input token: [$string]";
    $lookup_result = $parser->lexicon->lookup($string);
    warn "checkpoint";
    unless($lookup_result){
	    my $X = TipJar::Motion::configuration::OldMote($orig_string);
		if (not ref $X){
	       $X = TipJar::Motion::stringliteral->new;
		   $X->string($orig_string)
		}
 	    $lookup_result = $X
	};
	warn "get_mote returning $lookup_result";
	$lookup_result
}
sub next_mote{
    my $parser = shift;
    my $engine = shift;
    DEBUG and warn "checkpoint";
    my $prepend = $parser->prepend;
	# warn "prepend should be a list object. It's a ".ref($prepend);
    my $lookup_result = ( shift @$prepend or $parser->get_mote($engine) );
	$parser->sponsor($lookup_result);
      # DEBUG and
	  warn "found lookup_result $lookup_result";
	ref $lookup_result or die "NOT A MOTE";
    my $wants = $lookup_result->argtypelistref;
    DEBUG and warn "checkpoint";
    my @args;
    @$wants and @args = $lookup_result->parser($parser)->getargs($engine, $wants);
    DEBUG and warn "checkpoint";
    unshift @$prepend, $lookup_result->process($parser,@args);
    # warn "parser output list: [@$prepend]";
    DEBUG and warn "checkpoint. prepend is a ".ref $prepend;
    my $nextmote = shift @$prepend;  # "leftmost derivation"
	DEBUG and warn "returning $nextmote";
	$nextmote
}

1;
