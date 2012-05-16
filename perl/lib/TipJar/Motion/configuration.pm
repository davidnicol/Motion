
package TipJar::Motion::configuration;

=head1 local configuration

copy this file into a local library directory and
edit it.

=cut


sub VMid {
       "TEST=" # see TipJar::Motion::VMid. Change this to your PEN, if any
}

sub initial_lexicon {
       # matched key value pairs to be added to the default parser's lexicon
       {
            NOTHING => sub { use TipJar::Motion::null; TipJar::Motion::null->new },

       }
}

### edit this to tie %PL into a persistence infrastructure
### capable of holding perl objects and their types
### and sponsorship relationships (for GC.)
{ my %PL; sub persistent_lexicon { \%PL } }
1;
