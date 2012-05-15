
package TipJar::Motion::default_parser;
use parent TipJar::Motion::Mote;
sub type{'PARSER'};

{ my %L;
  sub lexicon{ my $P=shift; @_ and $L{$$P} = shift; $L{$$P} }
}

use TipJar::Motion::lexicon;

sub init{
   my $P = shift;
   $P->lexicon(TipJar::Motion::lexicon->new);
   $P->lexicon->AddTerms(TipJar::Motion::configuration::initial_lexicon());
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
    my $lexicon = $parser->lexicon;
    my $lookup_result = $lexicon->lookup($string);
    $lookup_result or die "TOKEN NOT FOUND IN LOOKUP\n";
    my $wants = $lookup_result->$wants;
    @$wants or return $lookup_result;
    my $subparser = $lookup_result->parser($parser);
    my @args;
    for my $w (@$wants){
        push @args, $subparser->next_mote($engine)->as($w)
    };
    $lookup_result->process(@args)
}
1;
