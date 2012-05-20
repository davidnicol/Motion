
package TipJar::Motion::configuration;
=head1 local configuration

copy this file into a local library directory and
edit it.

=cut
sub ourVMid {
       "TEST=" # see TipJar::Motion::VMid. Change this to your PEN, if any
}

### edit this to tie %PL into a persistence infrastructure
### capable of holding perl objects and their types
### and sponsorship relationships for GC.
### the requirements are somewhat subtle and the
### demonstration will include a working persistence
### layer (which the author has, from the previous draft,
### but doesn't want to release yet.)
{ my %PL;
  my $column = 0;
  $PL{motes} = {};
  $PL{data} = [];
  sub accessor(){
       ### support inside-out objects via these
       my $unique = $column++;
       $PL{data}[$unique] = [];
       sub {
              my $mote = shift;
              unless($mote->VMid eq ourVMid()){
                  warn "accessing $$mote with VMid ".$mote->VMid;
                  warn "which differs from our VMid ".ourVMid();
                  die "CLOUD MOTE ACCESS PROXY NEEDED";
              };
              my $id = $mote->row_id;
              @_ and $PL{data}[$unique][$id] = shift;
              $PL{data}[$unique][$id]
       }
  };
  # use something
  # tie %PL, something => ...
  sub persistent_AA { $PL{motes} ||= {} } 
  sub sponsortable { $PL{sponsorships} ||= {} }

### to make all motes blessed references to
### something relating with the persistence
### framework, change this. Library code expects
### to do scalar dereference on mote objects to
### recover mote identifier strings.
  sub base_obj($) {
    my $scalar = shift;
    exists $PL{motes}{$scalar} and Carp::confess( "ATTEMPTED REUSE OF MOTE-ID [$scalar]");
    $PL{motes}{$scalar} = [];
    \$scalar
  }
  sub generation { if (@_){
                     $PL{generation} = shift
                   }else{
                     $PL{generation}
                   }
  }
}

use TipJar::Motion::null;
use TipJar::Motion::string;
my $PL_lex;
sub persistent_lexicon {
    $PL_lex and return $PL_lex;
    $PL_lex = TipJar::Motion::lexicon->new;
    $PL_lex->lexicon(persistent_AA);
    $PL_lex
};
my $IL;
sub initial_lexicon {
     $IL and return $IL;
     $IL = TipJar::Motion::lexicon->new;
     $IL->lexicon(
       # matched key value pairs to be added to the default parser's lexicon
       {
            NOTHING => TipJar::Motion::null->new,
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
   *{caller().'::accessor'} = \&accessor
}
1;
