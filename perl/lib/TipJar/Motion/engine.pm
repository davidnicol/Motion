
package TipJar::Motion::engine;
use TipJar::Motion::default_parser;
use Carp;
use parent TipJar::Motion::Mote;
{ # inside-out object
my %INPUT; sub input{my $s=shift; @_ and $INPUT{$$s} = shift; $INPUT{$$s}}
my %OUTPUT; sub output{my $s=shift; @_ and $OUTPUT{$$s} = shift; $OUTPUT{$$s}}
my %PARSER; sub parser{my $s=shift; @_ and $PARSER{$$s} = shift; $PARSER{$$s}}
my %FAILURE; sub failure{my $s=shift; @_ and $FAILURE{$$s} = shift; $FAILURE{$$s}}
}
sub type { 'ENGINE' }
sub wants { [qw/STREAM STREAM/] }
sub init{
    my $self = shift;
    $self->input(shift);
    $self->output(shift);
    $self->parser(TipJar::Motion::default_parser->new);
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
    my $self = shift;
    @_ and carp "process method called with args";
    my $input = $self->input;
    my $output = $self->output;
    eval {
          my $this = $self->parser->next_mote($self);
          my $retval = $this->yield_returnable;
          defined $retval and do {
              $output->enqueue( $retval );
          };
      1
    } or die "ENGINE: $@";
    ! $input->done
}

1;
