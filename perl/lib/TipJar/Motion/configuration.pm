
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
	
$DBI::errstr and die "DBI errstr: [$DBI::errstr]";
#BEGIN { warn "using sqlite version ",$dbh->{sqlite_version} }
sub ourVMid {
       "TEST=" # see TipJar::Motion::VMid. Change this to your PEN, if any
}

{  my $DEPTH = 0; 
END { $DEPTH and warn "DEPTH MISMATCH: $DEPTH" }
sub rd { Carp::carp ((caller(1))[3] . " transaction depth: $DEPTH") }
sub begin_work{ 0&&rd; $DEPTH++ or eval { $dbh->begin_work;1} or Carp::confess $dbh->errstr }
sub commit{     0&&rd; --$DEPTH or eval { $dbh->commit;1    } or Carp::confess $dbh->errstr }
sub rollback{   0&&rd; --$DEPTH or eval { $dbh->rollback;1  } or Carp::confess $dbh->errstr }
}  ## scope for $DEPTH

use TipJar::Motion::moteid_format;
$dbh->do('PRAGMA foreign_keys = ON');
$dbh->do(<<'SQL');
CREATE TABLE IF NOT EXISTS motes (    -- the motes, their capability key strings, and scalar data if any
  row integer primary key,            -- 63 bits
  moteid char(25) unique not null,    -- UNIQUE constraint adds an index.
  type integer references motes(row), -- row of the type of this mote
  scalar text,                        -- the scalar value, if any. For types, this is the perl package name.
  mark integer                        -- NULL or 1 for mark and sweep
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
   0&& warn "using existing database? ".$dbh->errstr
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
  unique (sponsor,sponsee) on conflict ignore  -- sponsor first because the common
                                               -- case should be, sponsor is deleted causing trigger
)
SQL
my $sponsor_sth = $dbh->prepare(<<'SQL');
insert into sponsorship values
( (select row from motes where moteid=?),(select row from motes where moteid=?) )
SQL
my $desponsor_sth = $dbh->prepare(<<'SQL');
delete from sponsorship
where sponsee = (select row from motes where moteid=?)
and   sponsor = (select row from motes where moteid=?) 
SQL

sub RegisterSponsorship{ my ($sponsor_mid, $sponsee_mid) = @_;
     $sponsor_sth->execute($sponsee_mid, $sponsor_mid);
}
sub RemoveSponsorship{ my ($sponsor_mid, $sponsee_mid) = @_;
   $desponsor_sth->execute($sponsee_mid, $sponsor_mid);
}
my $mark_1_sth = $dbh->prepare(<<'SQL');
update motes set mark = 1
where moteid in (select distinct v from bootstrap)
SQL

my $mark_2_sth = $dbh->prepare(<<'SQL');  ### repeat this until it doesn't affect any rows
update motes set mark = 1
where row in (
   select sponsee from
   sponsorship 
   join motes sor on sor.row = sponsor
   join motes see on see.row = sponsee
       where sor.mark IS NOT NULL     -- motes sponsored by marked motes
	   and see.mark IS NULL           -- that aren't marked already
)
SQL

my $sweep_sth = $dbh->prepare(<<'SQL');
delete from motes where mark IS NULL
SQL

my $clear_marks_sth = $dbh->prepare(<<'SQL');
update motes set mark = NULL
SQL
sub inspect_trash(){1}
sub mark_and_sweep{
   warn "GC";
   begin_work;
   my $r = $clear_marks_sth->execute;
   warn "reset mark on $r motes";
   $r = 
   $mark_1_sth->execute;
   warn "bootstrap $r motes";
   for(;;){
       $r = $mark_2_sth->execute;
	   warn "marked $r motes";
	   $r > 0 or last  ## successful execute modifying 0 rows returns "0E0"
   };
   inspect_trash and do {
            my $trash_arrayref = $dbh->selectall_arrayref(<<SQL);
select m.moteid, t.scalar from motes m, motes t
where m.mark is null and m.type = t.row

SQL
		    warn "@$_\n" for @$trash_arrayref
   };
   $r = $sweep_sth->execute;
   warn "deleted $r motes";
   $dbh->do(<<SQL);
update motes set mark = (select count(1) from sponsorship where sponsor = motes.row)
SQL
   commit;
   warn "WEIGHT: @$_\n" for @{$dbh->selectall_arrayref(<<SQL)};
select m.moteid, m.mark, t.scalar from motes m, motes t
where m.type = t.row
order by m.mark desc   
SQL
   
   

   
}
END {  ### tune the frequency
       rand(100) > 20 or mark_and_sweep
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
	looks_like_moteid($_[2]) and RegisterSponsorship($_[0],$_[2]);
    $aa_set_sth->execute($_[0],$_[1], $_[2]);
	$_[2]
}
my $aa_delete_sth = $dbh->prepare('delete from aadata where mote = (select row from motes where moteid=?) and k =?');
sub aa_delete($$){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    my $rows =
    $aa_delete_sth->execute($_[0],$_[1])
    ; warn "deleted $rows rows ($_[1])"
}
my $aa_clear_sth = $dbh->prepare('delete from aadata where mote = (select row from motes where moteid=?)');
sub aa_clear($){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    $aa_clear_sth->execute($_[0])
}
my $aa_listkeys_sth = $dbh->prepare('select k from aadata where mote = (select row from motes where moteid=?)');
sub aa_listkeys($){
    looks_like_moteid($_[0]) or Carp::confess('[$_[0]] does not look like a moteid');
    $aa_listkeys_sth->execute($_[0]);
	my $k;
	$aa_listkeys_sth->bind_col(1,\$k);
	my @keys;
	push @keys, $k while($aa_listkeys_sth->fetch);
	\@keys
}

## no table for array data; use aadata for the index values and instancedata for offsets and such
  my $OldMotesth = $dbh->prepare(<<'SQL');
select scalar from motes
where row = (select type from motes where moteid = ?)
SQL
{my %SeenPacks;
  sub OldMote($){
     my $moteid;
     length $_[0] && do {
       $moteid = Encode::Base32::Crockford::normalize($_[0]);
	   looks_like_moteid($moteid)
	 } or return $_[0];
	 my ($package) = $dbh->selectrow_array($OldMotesth,{},$moteid);
	 $package or return bless \$moteid, __PACKAGE__.'::BOGUS';
	 # Carp::cluck "old mote package: $package";
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

sub usertype{ my $sponsor = shift; my $code = join "\n", @_;

    # obtain lock
    begin_work;
    
    # create a new mote to hold the code
    my $new = TipJar::Motion::configuration::base_obj();
    my $moteid1 = $$new;
    writescalar($moteid1, $code);
    
    # create a new type
    my $type = new_type( $moteid1 );
    
    # set the type
    set_type($new, $type);
    
    # prevent GC race
    RegisterSponsorship($$sponsor, $moteid1);
    RegisterSponsorship($moteid1, $type);
    for ( $code =~ m/OldMote\('(.+?)'\)/g ){
        RegisterSponsorship($moteid1, $_)
    };
    
    # release lock
    commit;
    
    # return OldMote run on the mote we just made 
    OldMote($moteid1)
}  
  
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
	   # Carp::cluck "creating accessor: $optional_comment:$package slot $slot";
	   my $writer = $dbh->prepare(<<SQL);
  insert into instancedata values ( ( select row from motes where moteid = ?), $package, $slot, ? )
SQL
	   my $reader = $dbh->prepare(<<SQL);
  select value from instancedata
  where mote = ( select row from motes where moteid = ?)
  AND package = $package AND slot = $slot
SQL
       sub {
              my $mote = shift;
	          # warn "accessing $package$slot $optional_comment: $mote : $$mote : @_\n";		  
              if(@_){
			      my $datum = shift;
				  # store motes by moteID
				  if (ref $datum){
              			eval { 
						       $datum = $datum->moteid ;
                               RegisterSponsorship($$mote,$datum);
						       1 
						}
						or Carp::confess "moteid on [$datum]: $@"
				  };
			      $writer->execute($$mote, $datum);
			  };
			  my ($ret) = $dbh->selectrow_array($reader,{},$$mote);
			  # warn "read from database: [$ret]";
			  # thaw motes
			  if (looks_like_moteid($ret)){
			      $ret = OldMote($ret);
			      #warn "returning [$ret]";
			  };
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
   *{caller().'::aa_listkeys'} = \&aa_listkeys;
   *{caller().'::bootstrap_set'} = \&bootstrap_set;
   *{caller().'::bootstrap_get'} = \&bootstrap_get;
   *{caller().'::new_type'} = \&new_type;
   *{caller().'::set_type'} = \&set_type;
   *{caller().'::usertype'} = \&usertype;
   *{caller().'::begin_work'} = \&begin_work;
   *{caller().'::commit'} = \&commit;
   *{caller().'::rollback'} = \&rollback;
   *{caller().'::RegisterSponsorship'} = \&RegisterSponsorship;
   *{caller().'::RemoveSponsorship'} = \&RemoveSponsorship;
}

###############################################
package TipJar::Motion::configuration::BOGUS; #
###############################################
#
#  specified in OldMote as the package
#  that well-formed Mote IDs not found in 
#  the database get blessed into.
#
#  Edit this to take appropriate action
#  such as blocking originating IP at firewall
#  for ten seconds or initiating an incident report.
#
###############################################
our $AUTOLOAD;
sub AUTOLOAD { Carp::confess "BOGUS MOTE ${$_[0]} ACCESSED $AUTOLOAD" }

1;
