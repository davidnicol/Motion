
package TipJar::Motion::anything;
use parent TipJar::Motion::Mote;
use strict;
use TipJar::Motion::type 'ANYTHING';

sub import  { 
  no strict 'refs';
  *{caller().'::ANYTHING'} = sub () { __PACKAGE__->type }
}


=pod

A class that accepts any type
and doesn't do anything else

=cut
sub process { die "NOT AN OP" }
sub become { die "NOT AN ARG" }
sub accept { $_[0] }
sub yield_returnable { die "NOT A RESULT" }
1;
