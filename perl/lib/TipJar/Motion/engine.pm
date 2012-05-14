
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
    $self->parser(default_parser());
    $self->failure('');
    $self
}
sub process{
    my $self = shift;
    @_ and carp "process method called with args";
    my $input = $self->input;
    my $output = $self->output;
    eval {
       for (;;){
          my $this = $self->parser->next_mote($self);
          my $retval = $this->yield_returnable;
          $retval and do {
              $output->enqueue( $retval );
          };
          $input->done and last;
       };
       1
    } or die "ENGINE: $@";
}

1;
