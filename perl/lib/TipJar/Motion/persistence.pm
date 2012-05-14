package TipJar::Motion::persistence;
=head1 TipJar::Motion::persistence
this package is concerned with the framework for persisting motes.

For production, replace it with a working persistence framework.


head2 method fresh_rowid
returns an integer that has been reserved in the database system.
This value's least significant twenty bits are used as the middle
of the five pieces of a moteid.
=cut

my $DummyTopRow;
sub fresh_rowid{
   ++$DummyTopRow
}
1;
