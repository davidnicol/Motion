
package TipJar::Motion::engine;
use TipJar::Motion::default_parser;
use TipJar::Motion::stream;
use Carp;

sub IFH() { 0 }
sub OFH() { 1 }
sub PARSER() { 2 }
sub FAILURE() { 4 }

sub new{
    my $pack = shift;
    my %args = @_;
    $args{parserstack} ||= [];
    bless [
        stream($args{input}),   # IFH
        stream($args{output}),  # OFH
        $args{parser} || default_parser(),
        ''              # FAILURE
    ], ref $pack || $pack
}
sub process{
    my $self = shift;
    @_ and carp "process method called with args";
    my $input = $self->[INPUT];
    my $output = $self->[OUTPUT];
    eval {
       for (;;){
          my $this = $self->[PARSER]->next_mote($self);
          my $retval = $this->yield_returnable;
          $retval and do {
              $output->enqueue( "$retval\n" );
          };
          $input->done and last;
       };
       1
    } or $output->enqueue( "\nFAIL\n$$self[FAILURE]");
    $@ and warn $@;
}
sub input{ $_[0]->[INPUT] }
sub failure { 
       my $self = shift;
       $self->[FAILURE] .= join "\n",@_,''
}

1;
