
package TipJar::Motion::anything;
use parent TipJar::Motion::Mote;
use strict;
use TipJar::Motion::type 'ANYTHING';

sub import  { 
  no strict 'refs';
  *{caller().'::ANYTHING'} = sub () { __PACKAGE__->type };
  *{caller().'::PERLSTRING'} = sub () { TipJar::Motion::perlstring->type }
}


=pod

A class that accepts any type
and doesn't do anything else

=cut
sub process { die "NOT AN OP" }
sub become { die "NOT AN ARG" }
sub accept { 1 }
sub yield_returnable { die "NOT A RESULT" }

package TipJar::Motion::perlstring;
our @ISA = qw/TipJar::Motion::anything/;
use TipJar::Motion::type 'PERLSTRING';
sub accept { not ref $_[1] }


1;
