
package TipJar::Motion::stream;
use TipJar::Motion::Mote;
use parent TipJar::Motion::Mote;
=pod

unify access to streams, to allow persistence of
streams in ways that OS file handles don't.

Initially, just wrap Perl file handles, but
leave room for motion queues.

=cut
sub type { 'STREAM' };
{
  my %FH;
sub fh{ my $s = shift; @_ and $FH{$$s} = shift; $FH{$$s} }
}
sub done {  my $s = shift; eof $s->fh }

=head2 streamify
make a stream out of the argument. Does nothing if the argument
is already a stream.

Currently uses C<tell> to determine if the argument is an
input/output handle

Currently doesn't know how to streamify anything else.
=cut

sub aeJ56DEXSRo{ 1 }  # Why does Check::ISA have to be difficult to build?
sub streamify{

    my $unknown = shift;
    eval { $unknown->aeJ56DEXSRo } and return $unknown;

    # is it a perl file handle?
    if (tell($unknown) > -1){
         my $stream = bless (TipJar::Motion::Mote->new);
         $stream->fh($unknown);
         return $stream;
    };

    # don't know how to streamify this
    die "NOT A FILE HANDLE\n";
}

sub import{
  my $caller = caller;
  *{$caller.'::streamify'} = \&streamify
}

sub nextchar{
  my $self = shift;
  my $c;
  read($self->fh, $c, 1);
  $c
};

1;
