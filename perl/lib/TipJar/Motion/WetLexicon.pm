
package TipJar::Motion::WetLexicon;
use parent TipJar::Motion::lexicon;

=pod

this package provides a initial lexicon of basic types
and basic functions which are not intended to be
exported into user workspaces.

=cut

my $L = __PACKAGE__->new;

sub WetLexicon { $L };


$L->AddTerms(
   MOTETYPE => \&TipJar::Motion::Mote::prototype,
   map { 

        (uc($_).'TYPE' => \&{"TipJar::Motion::".$_."::prototype"} )

   } qw/ default_parser engine lexicon null stream type /

);


1;
