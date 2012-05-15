
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
       (
            NOTHING => sub { TipJar::Motion::null->new },

       )
}

1;
