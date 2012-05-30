
package TipJar::Motion::configuration;
use strict;
=head1 local configuration

copy this file into a local library directory and
edit it.

=cut
use Carp ();
use DBI;
### all access to the $dbh should be within the BEGIN block our $dbh;
 my $dbh;
 sub reconnect{
    undef($dbh);
    $dbh  = DBI->connect("dbi:SQLite:dbname=PERSISTENT_DATA.sqlite","","",{
                             RaiseError => 1, AutoCommit => 1, PrintError => 0
    }) or Carp::confess "DBI: $DBI::errstr";
 }
 reconnect;
	
    warn "dbh: [$dbh] errstr: [$DBI::errstr]";
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
  type integer references motes(row), -- row of the type of this mote
  scalar text,                        -- the scalar value, if any. For types, this is the perl package name.
  mark integer                        -- unix timestamp / 8, for mark and sweep
)
SQL
my $readscalar_sth = $dbh->prepare('select scalar from motes where moteid = ?');
sub readscalar($){
    my $ary_ref = $dbh->selectrow_arrayref($readscalar_sth,{},shift);
	$ary_ref and $ary_ref->[0]
}
my $writescalar_sth = $dbh->prepare('update motes set scalar = ? where moteid = ?');
sub writescalar($$){
    looks_like_moteid($_[0]) or Carp::confess "USAGE: scalar moteid, value; not $_[0]";
    $writescalar_sth->execute($_[1],"$_[0]")
}
$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS bootstrap (                       -- the mote IDs of base types
   k text unique on conflict replace,                        -- key
   v text                                                   -- value
)
SQL
if (eval {
### type is its own type.
my $nm = new_moteid();
$dbh->do(<<'SQL',{},$nm);
insert into motes values (0,?,0,'TipJar::Motion::type',strftime('%s','now'))
SQL
### we didn't fail out of the eval, so we're adding things to a new database
$dbh->do(<<'SQL',{},$nm); 1
insert into bootstrap values ( 'TYPE TYPE', ? )
SQL
} ){
    warn "INITIALIZED NEW DATABASE"
}else{
   warn "using existing darabase? ".$dbh->errstr
};
my $bs_get_sth = $dbh->prepare('select v from bootstrap where k = ?');
sub bootstrap_get($){
    my $ary_ref = $dbh->selectrow_arrayref($bs_get_sth,{},shift);
	$ary_ref and $ary_ref->[0]
}
my $bs_set_sth = $dbh->prepare('insert into bootstrap values (?,?)');
sub bootstrap_set($$){
    $bs_set_sth->execute($_[0],$_[1]);
	$_[1]
}
=pod

marking starts with the boostrap table, then goes through the sponsorship table.
sweeping is done using the "mark" field in the motes table.

The latest generation of mark is the mark in row zero.

=cut

$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS sponsorship (                    -- references tracked for GC purposes
  sponsee integer references motes (row) on delete cascade, -- the mote that does not get deleted because of this entry
  sponsor integer references motes (row) on delete cascade,  -- the mote that wants the beneficiary not to get deleted
  unique (sponsor,sponsee) on conflict ignore
)
SQL

my $mark_1_sth = $dbh->prepare(<<'SQL');
update motes set mark = strftime('%s','now')
where moteid in (select distinct v from bootstrap)
SQL

my $mark_2_sth = $dbh->prepare(<<'SQL');  ### repeat this until it doesn't affect any rows
update motes set mark = (select mark from motes where row = 0)
where row in (
   select sponsee from sponsorship join motes on row = sponsor
       where mark >= (select mark from motes where row = 0)     -- motes sponsored by marked motes
   except
     select row from motes                                      -- that are not already marked
       where mark = (select mark from motes where row = 0)
)
SQL

my $sweep_sth = $dbh->prepare(<<'SQL');
delete from motes where mark < (select mark from motes where row = 0)
SQL

sub mark_and_sweep{
   warn "GC";
   $dbh->begin_work;
   my $m1 = 
   $mark_1_sth->execute;
   warn "bootstrap mark: $m1 rows";
   for(;;){
       my $m2rows = $mark_2_sth->execute;
	   warn "marked $m2rows rows";
	   $m2rows or last
   };
   $sweep_sth->execute;
   $dbh->commit;
}
END {  ### tune the frequency
       $$ % 5 or mark_and_sweep
} 

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

my $aa_exists_sth = $dbh->prepare('select exists ( select 1 from aadata join motes on mote = row where moteid = ? and k = ? )');
sub aa_exists($$){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    my $ary_ref = $dbh->selectrow_arrayref($aa_exists_sth, {}, $_[0], $_[1]);
	$ary_ref and $ary_ref->[0]
}
my $aa_get_sth = $dbh->prepare('select v from aadata join motes on mote = row where moteid = ? and k = ?');
sub aa_get($$){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    my $ary_ref = $dbh->selectrow_arrayref($aa_get_sth, {}, $_[0], $_[1]);
	$ary_ref and $ary_ref->[0]
}
my $aa_set_sth = $dbh->prepare('insert into aadata values ( (select row from motes where moteid=?),?,?)');
sub aa_set($$$){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    $aa_set_sth->execute($_[0],$_[1], $_[2]);
	$_[2]
}
my $aa_delete_sth = $dbh->prepare('delete from aadata where mote = (select row from motes where moteid=?) and k =?');
sub aa_delete($$){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    $aa_delete_sth->execute($_[0],$_[1])
}
my $aa_clear_sth = $dbh->prepare('delete from aadata where mote = (select row from motes where moteid=?)');
sub aa_clear($){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    $aa_clear_sth->execute($_[0])
}


## no table for array data; use aadata for the index values and instancedata for offsets and such
  my $OldMotesth = $dbh->prepare(<<'SQL');
select t.scalar
from motes m left join motes t
on m.type = t.row
where m.moteid = ?  
SQL
                                           {my %SeenPacks;
  sub OldMote($){
     $_[0] or return undef;
     my $moteid = Encode::Base32::Crockford::normalize($_[0]);
     $OldMotesth->execute($moteid);
	 my $ary_ref = $OldMotesth->fetch; $OldMotesth->finish;
	 $ary_ref or die "MOTEID $moteid NOT FOUND\n";
	 my ($package) = @$ary_ref;
     my $alpha = $package;
	 if (looks_like_moteid($package)){
	    $alpha =~ s/\W//g;
		$SeenPacks{$package}++ or do {
		    my $code = readscalar($package);
		    eval <<"CODE"
package TipJar::Motion::usertype::$alpha;
$code
;1;
CODE
            or die "user code loading failed: $@";
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
	   $dbh or do {
	        Carp::cluck('reconnecting database');
			reconnect;
	   };
       my $package = $dbh->quote(scalar caller());
	   my $slot = $AccessorSlotsByPackage{$package}++;
	   my $optional_comment = shift;
	   0 and
	   Carp::cluck "creating accessor: $optional_comment:$package slot $slot";
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
              if(@_){
			      my $datum = shift;
				  # store motes by moteID
				  if (ref $datum){
              			eval { $datum = $datum->moteid ; 1 }
						or Carp::confess "moteid on [$datum]: $@"
				  };
			      $writer->execute($$mote, $datum);
			  };
			  my ($ret) = $dbh->selectrow_array($reader,{},$$mote);
			  # thaw motes
			  looks_like_moteid($ret)
			  ?
			     OldMote($ret)
			  :
			     $ret
       }
  };
  {  my $dummyU = 'a';
  my $dummy_insert_sth = $dbh->prepare('insert into motes (moteid, type) VALUES ( ? || ? || ?, 0 )');
  my $set_moteid_sth = $dbh->prepare('update motes set moteid = ? where row = ?');
  sub base_obj() {
    $dummy_insert_sth->execute($$,time(),$dummyU++);
	my $row = $dbh->last_insert_id(undef,undef,undef,undef);
	my $scalar = new_moteid;
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
	  writescalar($$type_obj, $package);
	  $$type_obj
  }
{
  my $set_type_sth = $dbh->prepare( <<'SQL');
update motes
   set type = ( select row from motes where moteid = ? )
where moteid = ?
SQL
  sub set_type{
      my ($object,$type) = @_;
	  $set_type_sth->execute( $type,  $$object )
  }
};

sub begin_work{ $dbh->begin_work or die $dbh->errstr }
sub commit{     $dbh->commit   or die $dbh->errstr   }
sub rollback{   $dbh->rollback   or die $dbh->errstr }


sub import{
   no strict 'refs';
   *{caller().'::OldMote'} = \&OldMote;
   *{caller().'::accessor'} = \&accessor;
   *{caller().'::readscalar'} = \&readscalar;
   *{caller().'::writescalar'} = \&writescalar;
   *{caller().'::aa_get'} = \&aa_get;
   *{caller().'::aa_set'} = \&aa_set;
   *{caller().'::aa_exists'} = \&aa_exists;
   *{caller().'::aa_delete'} = \&aa_delete;
   *{caller().'::aa_clear'} = \&aa_clear;
   *{caller().'::bootstrap_set'} = \&bootstrap_set;
   *{caller().'::bootstrap_get'} = \&bootstrap_get;
   *{caller().'::new_type'} = \&new_type;
   *{caller().'::begin_work'} = \&begin_work;
   *{caller().'::commit'} = \&commit;
   *{caller().'::rollback'} = \&rollback;

}

1;
