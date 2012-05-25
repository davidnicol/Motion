
package TipJar::Motion::configuration;
=head1 local configuration

copy this file into a local library directory and
edit it.

=cut
use DBI;
## BEGIN{  # set the persistence up before using anything else
my $dbh;
BEGIN{
   $dbh  = DBI->connect("dbi:SQLite:dbname=PERSISTENT_DATA.sqlite","","",{
                             RaiseError => 1, AutoCommit => 1, PrintError => 0
    });
    warn "error: [$DBI::errstr]"
}
#BEGIN { warn "using sqlite version ",$dbh->{sqlite_version} }
sub ourVMid {
       "TEST=" # see TipJar::Motion::VMid. Change this to your PEN, if any
}

use TipJar::Motion::moteid_format;
$dbh->do('PRAGMA foreign_keys = ON');
$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS motes (    -- the motes, their capability key strings, and scalar data if any
  row integer primary key,            -- 63 bits
  moteid char(25) unique not null,    -- UNIQUE constraint adds an index.
  type integer , -- references motes(row), -- row of the type of this mote
  scalar text                         -- the scalar value, if any. For types, this is the perl package name.
)
SQL
$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS bootstrap (                       -- the mote IDs of base types
   k text unique on conflict replace,                        -- key
   v text                                                   -- value
)
SQL
if (eval {
### type is its own type.
my $nm = new_moteid();
local 
$dbh->do(<<'SQL',{},$nm);
insert into motes values (0,?,0,'TipJar::Motion::type')
SQL
### we didn't fail out of the eval, so we're adding things to a new database
$dbh->do(<<'SQL');
insert into bootstrap values (
'TYPE TYPE',(select moteid from motes where scalar = 'TipJar::Motion::type')
)
SQL
} ){
    warn "INITIALIZED NEW DATABASE"
}else{
   warn "using existing darabase"
};
my $bs_get_sth = $dbh->prepare('select v from bootstrap where k = ?');
sub bootstrap_get($){
    my $ary_ref = $dbh->selectrow_arrayref($bs_get_sth,{},shift);
	$ary_ref and $ary_ref->[0]
}
my $bs_set_sth = $dbh->prepare('insert into bootstrap values (?,?)');
sub bootstrap_set($$){
    $bs_set_sth->execute($_[0],$_[1])
}
$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS sponsorship (                    -- references tracked for GC purposes
  sponsee integer references motes (row) on delete cascade, -- the mote that does not get deleted because of this entry
  sponsor integer references motes (row) on delete cascade,  -- the mote that wants the beneficiary not to get deleted
  unique (sponsor,sponsee) on conflict ignore
)
SQL
$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS instancedata (                          -- entries created by accessors
   mote integer references motes (row) on delete cascade ,         -- the mote holding this instancedatum
   package text,                                                   -- the perl package defining this accessor
   slot integer,                                                   -- a package may declare multiple accessors
   value text ,                                                    -- the data. 
   unique (mote,package,slot) on conflict replace                  -- do all writes with INSERT
)
SQL
$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS aadata (                          -- key/value data
   mote integer references motes (row) on delete cascade ,   -- the mote owning this pair
   k text,                                                   -- key
   v text,                                                   -- value
   unique (mote,k) on conflict replace                       -- do all writes with INSERT
)
SQL

## no table for array data; use aadata for the index values and instancedata for offsets and such
  my $OldMotesth = $dbh->prepare(<<'SQL');
select t.scalar
from motes m left join motes t
on m.type = t.row
where m.moteid = ?  
SQL
                                           {my %SeenPacks;
  sub OldMote($){
     $_[0] or Carp::confess "OldMote called without mote id";
     my $moteid = Encode::Base32::Crockford::normalize($_[0]);
     $OldMotesth->execute($moteid);
	 my $ary_ref = $OldMotesth->fetch; $OldMotesth->finish;
	 $ary_ref or die "MOTEID $moteid NOT FOUND\n";
	 my ($package) = @$ary_ref;
     my $alpha = $package;
	 if (looks_like_moteid($package)){
		$alpha =~ s/\W//g;
		$SeenPacks{$alpha}++ or do {
		     die "FIXME load and eval code from usertype accessor"
		};
		$alpha = "TipJar::Motion::usertype::$alpha";
	 };
	 bless \$moteid, $alpha  
  }
                                          };
  
  
  
  our $TYPEBASE = OldMote (bootstrap_get 'TYPE TYPE');

  my %AccessorSlotsByPackage;
  sub accessor(;$){
       ### support inside-out objects via these
       my $package = $dbh->quote(caller());
	   my $slot = $AccessorSlotsByPackage{$package}++;
	   my $optional_comment = shift;
	   my $writer = $dbh->prepare(<<SQL);
  insert into instancedata values ( ( select row from motes where moteid = ?), $package, $slot, ? )
SQL
	   my $reader = $dbh->prepare(<<SQL);
  select value from instancedata
  where mote = ( select row from motes where moteid = ?)
  AND package = $package AND slot = $slot
SQL
       sub (;$){
	          warn "accessing $package$slot $optional_comment: @_\n";
              my $mote = shift;
              my $id = $mote->row_id;
              @_ and $writer->execute($$mote, shift);
			  $dbh->selectrow_array($reader,{},$$mote)
       }
  };
  {  my $dummyU = 'a';
  my $dummy_insert_sth = $dbh->prepare('insert into motes (moteid, type) VALUES ( ? || ? || ?, 0 )');
  my $set_moteid_sth = $dbh->prepare('update motes set moteid = ? where row = ?');
  sub base_obj() {
    $dummy_insert_sth->execute($$,time(),$dummyU++);
	my $row = dbh->last_insert_id(undef,undef,undef,undef);
	my $scalar = moteid_format($row);
	$set_moteid_sth->execute($scalar,$row);
    \$scalar;
  }
  }
=head1 new_type
take a perl package as argument, return a type mote that maps to it.
=cut
  sub new_type($) {
      my $package = shift;
	  my $type_obj = base_obj;
	  set_scalar($type_obj, $package);
	  $type_obj
  }
{
  my $set_type_sth = $dbh->prepare( <<'SQL');
update motes
   set type = ( select row from motes where moteid = ? )
where moteid = ?
SQL
  sub set_type{
      my ($object,$type) = @_;
	  $set_type_sth->execute( $$type,  $$object )
  }
};
##}
die 'smiling'
__END__ 

sub persistent_AA { $PBT->{core_names}||={}  } 
sub persistent_lexicon {
    $P8T->{p8t_lexobj} and return $P8T->{p8t_lexobj};
    $P8T->{p8t_lexobj} = TipJar::Motion::lexicon->new;
    $P8T->{p8t_lexobj}->lexicon(persistent_AA);
    $P8T->{p8t_lexobj}->comment("PersistentLexicon");
    $P8T->{p8t_lexobj}
};
sub initial_AA { $P8T->{i_AA} ||= {} }
sub initial_lexicon {
    $P8T->{i5l_lexobj} and return $P8T->{i5l_lexobj};
    $P8T->{i5l_lexobj} = TipJar::Motion::lexicon->new;
    $P8T->{i5l_lexobj}->lexicon(initial_AA);
    $P8T->{i5l_lexobj}->comment("InitialLexicon");
    $P8T->{i5l_lexobj}
}
sub fresh_rowid{
   ++$PBT->{rowcounter}
} 
use TipJar::Motion::lexicon;

### the time an unspponsored mote is allowed to persist;
### ths wait between garbage collections
### in seconds
sub min_age() { 37 }

sub import{
   no strict 'refs';
   *{caller().'::OldMote'} = \&OldMote;
   *{caller().'::accessor'} = \&accessor;
   *{caller().'::bootstrap_set'} = \&bootstrap_set;
   *{caller().'::bootstrap_get'} = \&bootstrap_get;
   *{caller().'::new_type'} = \&new_type;

}
$SIG{__DIE__} = sub {Carp::cluck $@};

eval <<\abcde;
use TipJar::Motion::null;
use TipJar::Motion::string;
use TipJar::Motion::workspace;
use TipJar::Motion::anything;
use TipJar::Motion::name;
1
abcde
# the eval ends true
