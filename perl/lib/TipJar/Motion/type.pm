
package TipJar::Motion::type;
use parent TipJar::Motion::Mote;
use strict;
use TipJar::Motion::default_parser;
sub import{
  my $caller = caller;
  my $pack = shift;
  my $typename = shift;
  $typename or die "import called with no argument";
  @_ and die "import called with extra arguments";
  { no strict 'refs';
  *{$caller.'::typename'} = sub { $typename };
  }
  
}
__PACKAGE__->import( 'TYPE' );

=pod
this package declares C<type> methods in callers when used 
with an argument.

types are strings. The core types are English words, and user
types are mote-ids with the non-alphas stripped out.
=cut

sub asSTRING {
   my $id = $$_[0];
   $id =~ s/[^A-Z0-9]//g;
   $id
}

1;
