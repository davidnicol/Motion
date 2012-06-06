
package TipJar::Motion::stream;
use parent TipJar::Motion::Mote;

=pod
unify access to streams, to allow persistence of
streams in ways that OS file handles don't.

Initially, just wrap Perl file handles, but
leave room for motion queues.
=cut

use TipJar::Motion::type 'STREAM' ;

{
  my %FH;
  sub fh{ my $s = shift; 
        # warn "local access for stream $$s";
        @_ and $FH{$$s} = shift;
		# warn "returning $FH{$$s}";
		$FH{$$s} }
}
sub done {  my $s = shift; eof $s->fh }

=head2 streamify
make a stream out of the argument. Does nothing if the argument
is already a stream.

Currently uses C<tell> to determine if the argument is an
input/output handle

Currently doesn't know how to streamify anything else.
=cut

sub is_motion_stream{ 1 }  # Why does Check::ISA have to be difficult to build?
sub UNIVERSAL::is_motion_stream{0}
sub streamify{

    my $unknown = shift;
    $unknown->is_motion_stream and return $unknown;

    # is it a perl file handle?
    if (tell($unknown) > -1){
         my $stream = __PACKAGE__->new($unknown);  ### Mote::new sets type based on package
         return $stream;
    };

    # don't know how to streamify this
    die "NOT A FILE HANDLE\n";
}

use TipJar::Motion::anything;
sub wants{ [ANYTHING] }
sub init{
   my ($self, $arg) = @_;
   my $ref = ref $arg;
   my $fh;
   if (!$ref){
        open $fh, '<', \$arg
   }elsif($ref eq 'SCALAR'){
        open $fh, '>',  $_[1]
   }else{
        $fh = $arg;
   };
   $self->fh($fh);
   $self
}

sub import{
  my $caller = caller;
  *{$caller.'::streamify'} = \&streamify;
  *{$caller.'::STREAM'} = \&type;
}

sub nextchar{
  my $tries;
  my $self = shift;
  my $c;
 while ($tries++ < 4){
  read($self->fh, $c, 1);
  # warn "read from input: [$c]\n"; 
  length $c and return $c;
  sleep 1
 };
 Carp::confess "TIMEOUT WAITING FOR NEXTCHAR";
};
sub enqueue{
   my $self = shift;
   while (@_){
       print { $self->fh } shift,"\n"
   }
}


1;
