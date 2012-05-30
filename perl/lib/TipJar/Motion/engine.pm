
package TipJar::Motion::engine;
use TipJar::Motion::default_parser;
use TipJar::Motion::stream;
use TipJar::Motion::configuration;
use Carp;
use parent TipJar::Motion::Mote;
## { # inside-out object
## my %INPUT; sub input{my $s=shift; @_ and $INPUT{$$s} = shift; $INPUT{$$s}}
## my %OUTPUT; sub output{my $s=shift; @_ and $OUTPUT{$$s} = shift; $OUTPUT{$$s}}
## my %PARSER; sub parser{my $s=shift; @_ and $PARSER{$$s} = shift; $PARSER{$$s}}
## my %FAILURE; sub failure{my $s=shift; @_ and $FAILURE{$$s} = shift; $FAILURE{$$s}}
## }
*input = accessor('engine input');
*output = accessor('engine output');
*parser= accessor('engine parser');
*failure = accessor('engine failure');
use TipJar::Motion::type  'ENGINE' ;
sub import  { *{caller().'::ENGINE'} = sub () { __PACKAGE__->type } }

sub wants { [STREAM, STREAM, PARSER] }
sub init{
    my ($self,$I,$O,$P) = shift;
    $self->input($I);
    $self->output($O);
    $self->parser($P);
    $self->failure('');
    $self
}
=head2 process

the process method reads the next mote from
the input stream, prints the result of running
its "yield_returnable" method to the output
stream, and returns a boolean indicating if
there is more to read from the input stream.

=cut

sub process{
    my ($self) = shift;
    @_ and carp "process method called with args";
    my $input = $self->input;
    my $output = $self->output;
    my $parser = $self->parser;
	warn "using parser [$parser]";
    eval {
          my $this = $parser->next_mote($self);
          my $retval = $this->yield_returnable;
          defined $retval and do {
              $output->enqueue( $retval );
          };
      1
    } or Carp::confess "ENGINE: $@";
    ! $input->done
}

1;
