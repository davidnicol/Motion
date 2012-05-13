
package TipJar::Motion::stream;
=pod

unify access to streams, to allow persistence of
streams in ways that OS file handles don't.

Initially, just wrap Perl file handles, but
leave room for motion queues.

=cut
sub is_a_motion_stream { !0 };
sub UNIVERSAL::is_a_motion_stream { !1 };
sub streamify{

    my $unknown = shift;
    $unknown->is_a_motion_stream and return $unknown;

    # is it a perl file handle?


    # don't know how to streamify this

}


sub import{
  my $caller = caller;
  *{$caller.'::stream'} = \&streamify
}



1;
