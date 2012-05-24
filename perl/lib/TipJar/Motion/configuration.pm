
package TipJar::Motion::configuration;
=head1 local configuration

copy this file into a local library directory and
edit it.

=cut
sub ourVMid {
       "TEST=" # see TipJar::Motion::VMid. Change this to your PEN, if any
}

my $P8T;  # all persistent data goes in here
END{
   use Data::Dumper;
   $Data::Dumper::Purity = 1;
   $Data::Dumper::Sortkeys = 1;  # minimize diffs between runs
   open P, '>', "PERSISTENT_DATA" or warn "could not open p-file: $!";
   print P Dumper($P8T);
}
BEGIN{
   if (open P, '<', "PERSISTENT_DATA"){
       $P8T = eval join '', '{ my ',<P>, ';$VAR1}';
       $@ and die $@;
       close P;
   }else{
       warn "persistent data file: $!";
   };
}



### edit this to tie %P8T into a persistence infrastructure
### capable of holding perl objects and their types
### and sponsorship relationships for GC.
### the requirements are somewhat subtle and the
### demonstration will include a working persistence
### layer (which the author has, from the previous draft,
### but doesn't want to release yet.)
{ 
  $P8T->{motes} ||= {};
  sub OldMote($){$P8T->{motes}{$_[0]}}
  $P8T->{data} ||= {};
  sub accessor(;$){
       ### support inside-out objects via these
       my $unique = shift || join ':', (caller)[1,2] ; 
       $P8T->{data}{$unique} = {};
       sub {
	          warn "accessing $unique: @_\n";
              my $mote = shift;
              $P8T->{motes}{$mote->moteid} eq $mote or die "MOTEID ODDNESS";
              unless($mote->VMid eq ourVMid()){
                  warn "accessing $$mote with VMid ".$mote->VMid;
                  warn "which differs from our VMid ".ourVMid();
                  die "CLOUD MOTE ACCESS PROXY NEEDED";
              };
              my $id = $mote->row_id;
              @_ and $P8T->{data}{$unique}{$id} = shift;
              $P8T->{data}{$unique}{$id}
       }
  };
  # this will be its own database table
  # with two indexed columns and an expiration column
  sub sponsortable { $P8T->{sponsorships} ||= {} }

### to make all motes blessed references to
### something relating with the persistence
### framework, change this. Library code expects
### to do scalar dereference on mote objects to
### recover mote identifier strings.
  sub base_obj($) {
    my $scalar = shift;
    exists $P8T->{motes}{$scalar} and Carp::confess( "ATTEMPTED REUSE OF MOTE-ID [$scalar]");
    $P8T->{motes}{$scalar} = bless \$scalar, $scalar;
  }
  sub generation { if (@_){
                     $P8T->{generation} = shift
                   }else{
                     $P8T->{generation}
                   }
  }
}
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