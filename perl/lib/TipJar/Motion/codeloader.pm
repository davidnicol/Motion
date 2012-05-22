package TipJar::Motion::codeloader;
=pod
this package provides a utility 'codeload'
that does string-eval, then returns its argument.

the reason for this is, so we can store packages in
the database instad of in @INC

=cut

sub codeload($){
   my $code = shift;
   eval "$code";
   $@ and die "SYNTAX ERROR:$@\nin\n$code\n";
   $code
};

sub import { *{caller().'::codeload'} = \&codeload }

1;
