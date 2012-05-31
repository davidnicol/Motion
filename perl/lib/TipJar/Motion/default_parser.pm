
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
   $P->set_type(type());
   $P->lexicon(TipJar::Motion::lexicon->new)->comment("parser_init");
# AddLex ads a copy of the named lexicon into the
# invocant's outer chain. It does not add the operand's outers too.
# each new one pushes the others farther out, so list them
# from the outside in.
   $P->lexicon ->AddLex(initial_lexicon)
   ;
   $P->prepend(TipJar::Motion::list->new);
   $P
}

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


sub next_mote{
    my $parser = shift;
    my $engine = shift;
    my $lookup_result;
    DEBUG and warn "checkpoint";
    my $prepend = $parser->prepend;
	# warn "prepend should be a list object. It's a ".ref($prepend);
   if (@$prepend){
    DEBUG and warn "checkpoint";
         $lookup_result = shift @$prepend
   }else{
    DEBUG and warn "checkpoint";
    my $c;
    my $string = '';
    while(defined ($c = uc $engine->input->nextchar)){
        if($c =~ /\s/){
           length $string and last;
        }else{
           $string .= $c;
        };
    };
    length $string or return undef;
    #remove dashes if any
    $string =~ s/-//g;
    # look up $string in lexicon or old mote table
       # DEBUG and
	   warn "input token: [$string]";
    $lookup_result = $parser->lexicon->lookup($string);
   };
    DEBUG and warn "checkpoint";
    $lookup_result or die "TOKEN NOT FOUND IN LOOKUP\n";
      # DEBUG and
	  warn "found lookup_result $lookup_result";
	ref $lookup_result or die "NOT A MOTE";
    my $wants = $lookup_result->wants2;
    DEBUG and warn "checkpoint";
    my @args;
    if(@$wants){
      my $subparser = $lookup_result->parser($parser);  # used by STRING
      for my $w (@$wants){
        my $arg = $subparser->next_mote($engine)->become($w);
        readscalar($w)->accept($arg) or die "ARG TYPE MISMATCH";
        push @args, $arg;
      };
    };
    DEBUG and warn "checkpoint";
    unshift @$prepend, $lookup_result->process($parser,@args);
    # warn "parser output list: [@$prepend]";
    DEBUG and warn "checkpoint. prepend is a ".ref $prepend;
    my $nextmote = shift @$prepend;  # "leftmost derivation"
	DEBUG and warn "returning $nextmote";
	$nextmote
}
1;
