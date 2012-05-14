
package TipJar::Motion::stream;
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
sub streamify{

    my $unknown = shift;
    $unknown->is_a_motion_stream and return $unknown;

    # is it a perl file handle?
    if (tell($unknown) > -1){
         my $stream = TipJar::Motion::Mote->new;
         bless $stream;
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



1;
