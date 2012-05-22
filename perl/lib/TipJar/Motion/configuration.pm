
package TipJar::Motion::configuration;
=head1 local configuration

copy this file into a local library directory and
edit it.

=cut
sub ourVMid {
       "TEST=" # see TipJar::Motion::VMid. Change this to your PEN, if any
}

sub persistify; # defined at bottom
sub depersistify(); # defined at bottom
INIT{depersistify}; # load persistent data before any other INIT blocks



### edit this to tie %PL into a persistence infrastructure
### capable of holding perl objects and their types
### and sponsorship relationships for GC.
### the requirements are somewhat subtle and the
### demonstration will include a working persistence
### layer (which the author has, from the previous draft,
### but doesn't want to release yet.)
{ my %PL;
  persistify \%PL, ;
  $PL{motes} ||= {};
  sub OldMote($){$PL{motes}{$_[0]}}
  $PL{data} ||= [];
  sub accessor(){
       $callr =join ':', (caller)[1,2] ;
       ### support inside-out objects via these
       my $unique = $$PL{callrz}{$callr} ||= $$PL{column}++;
       $PL{data}[$unique] = {};
       sub {
              my $mote = shift;
              $PL{motes}{$mote->moteid} = $mote;
              unless($mote->VMid eq ourVMid()){
                  warn "accessing $$mote with VMid ".$mote->VMid;
                  warn "which differs from our VMid ".ourVMid();
                  die "CLOUD MOTE ACCESS PROXY NEEDED";
              };
              my $id = $mote->row_id;
              @_ and $PL{data}[$unique]{$id} = shift;
              $PL{data}[$unique]{$id}
       }
  };
  # use something
  # tie %PAA, something => ...
  our %PAA;
  sub persistent_AA { $PL{motes} ||= \%PAA } 
  # this will be its own database table
  # with two indexed columns and an expiration column
  sub sponsortable { $PL{sponsorships} ||= {} }

### to make all motes blessed references to
### something relating with the persistence
### framework, change this. Library code expects
### to do scalar dereference on mote objects to
### recover mote identifier strings.
  sub base_obj($) {
    my $scalar = shift;
    exists $PL{motes}{$scalar} and Carp::confess( "ATTEMPTED REUSE OF MOTE-ID [$scalar]");
    $PL{motes}{$scalar} = bless \$scalar, $scalar;
  }
  sub generation { if (@_){
                     $PL{generation} = shift
                   }else{
                     $PL{generation}
                   }
  }
}
INIT { eval <<\abcde or die $@ }
use TipJar::Motion::null;
use TipJar::Motion::string;
use TipJar::Motion::workspace;
1
abcde
;
my $PL_lex;
persistify(\$PL_lex);
sub persistent_lexicon {
    $PL_lex and return $PL_lex;
    $PL_lex = TipJar::Motion::lexicon->new;
    $PL_lex->lexicon(persistent_AA);
    $PL_lex
};
my $IL;
persistify(\$IL);
sub initial_lexicon {
     $IL and return $IL;
     $IL = TipJar::Motion::lexicon->new;
     $IL->lexicon(
       # matched key value pairs to be added to the default parser's lexicon
       {
            ### core types are now added to the persistent
            ### lexicon by type's import function, and no longer
            ### need be listed here. This may change with
            ### addition or persistence to this rewrite.

            ### NOTHING => TipJar::Motion::null->new,

            #### the core types. After arranging
            #### a persistence system, add the wet lexicon
            #### to it and create dry environments
            #### within SAFE sequences.
            # TipJar::Motion::WetLexicon::WetLexicon()->explode, 

       }
     );
     $IL->outer(persistent_lexicon);
     $IL
}
sub initial_AA { initial_lexicon->lexicon }
{ my $DummyTopRow; sub fresh_rowid{
   ++$DummyTopRow
} }
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
# register variable reference as a persistence key
my @Persistents;
my $MARKER = 'MARKER';
BEGIN{ $MARKER = 'MARKER'};
sub persistify{
    warn "marker is $MARKER";
    push @Persistents, @_, $MARKER++;
    
}
END{
   use Data::Dumper;
   $Data::Dumper::Purity = 1;
   $Data::Dumper::Sortkeys = 1;  # minimize diffs between runs
   open P, '>', "PERSISTENT_DATA" or warn "could not open p-file: $!";
   print P Dumper(\@Persistents);
}
sub depersistify(){
   unless (open P, '<', "PERSISTENT_DATA"){
       warn "persistent data file absent";
       return
   };
   my $P = eval join '', '{ my ',<P>, ';$VAR1}';
   close P;
   for ( @Persistents ){
       my $this = shift @$P;
       defined $this or die "persistence underflow";
       # markers
       if (!ref $_){
           $_ eq $this or die "marker mismatch: [$_] ne [$this]";
           warn "read  marker $_";
       }elsif( ref $_ eq 'HASH' ){
           %$_ = %$this
       }elsif( ref $_ eq 'REF' ){
           $$_ = $$this
       }elsif( ref $_ eq 'SCALAR' ){
           $$_ = $$this
       }elsif( ref $_ eq 'ARRAY' ){
           @$_ = @$this
       }else{
           die "don't know how to depersistify $_";
       };
   }
}
1;
