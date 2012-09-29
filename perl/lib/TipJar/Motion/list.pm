
=head1 ListOfMotes type is an immutable sequence

the LoM type is a virtual base class for implementing
macros, sequences, operand sets, and such.

It can be created, and expanded, or otherwise parsed by implementation
language code depending on the details of the child type.

It stores as whitespace-separated moteids.

=cut

package TipJar::Motion::ListOfMotes;
use parent TipJar::Motion::mote;
use TipJar::Motion::type 'LoM';
use TipJar::Motion::configuration;  ### get readscalar(MOTE)
sub LoM { map {OldMote $_} split /\s+/, readscalar shift }

package TipJar::Motion::ListOfMotesConstructor;
sub FactoryOutputType{ 'TipJar::Motion::ListOfMotes' } # what this factory produces
our @ISA = qw/TipJar::Motion::hereparser/;
use TipJar::Motion::type 'LoM Constructor';
use TipJar::Motion::anything;
use TipJar::Motion::configuration;  ### get writescalar(MOTE,STRING)
sub argtypelistref{ [PERLSTRING] }
sub process {
   my $constructor = shift;
   my $parser = shift;
   my $icode = ''.shift;
   my $buffer;
   my $count;
        
   while ($icode){ 
        $icode =~ s/\s*(\S+)// or last;
        my $token = $1;
        my $lr = $parser->lexicon->lookup(uc $token);
        $lr or Carp::confess "new barewords not allowed in mote lists: '$token' was not found";
        $buffer .= $$lr;
        $buffer .= (++$count %4 ? " " : "\n");        
   };
   chop $buffer; # lose final space-or-newline
   my $LoM = $constructor->FactoryOutputType->new;
    
   writescalar($$LoM,$buffer);
   $LoM
};


sub TipJar::Motion::arr_init{
   my $L = $_[0]->marrslot;
   $L and return $L;
   $_[0]->marrslot(TipJar::Motion::list->new)
}

package TipJar::Motion::astore;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'aSTORE';
use TipJar::Motion::string;
use TipJar::Motion::anything;
use TipJar::Motion::null;
sub argtypelistref{ [ANYTHING, STRING, ANYTHING] };
sub process{
  my ($op, $P, $mote, $index, $val) = @_;
  ${TipJar::Motion::arr_init($mote)}[int $index->string] = $val;
  retnull
}

package TipJar::Motion::afetch;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'aFETCH';
use TipJar::Motion::anything;
use TipJar::Motion::string;
sub argtypelistref{ [ANYTHING, STRING] };
sub process{
  my ($op, $P, $mote, $index) = @_;
  ${TipJar::Motion::arr_init($mote)}[int $index->string];
}

=head1 LIST type is like a perl array

the list type is a container that has full perl array semantics

=cut

package TipJar::Motion::list;
use TipJar::Motion::type 'LIST';
use parent TipJar::Motion::AA;
use TipJar::Motion::configuration;
BEGIN{
         *offset = accessor('list index offset');
		 *top = accessor('list index top')
};
use strict;
sub DEBUG(){0}
use overload '@{}' => sub { tie my @A, __PACKAGE__, $_[0]; \@A };
sub init{
   my $list = shift;
   @$list = ();
   $list
}
our $OnExit;
use Scope::local_OnExit;

sub TIEARRAY { $_[1] }

sub CLEAR{
   local $OnExit = sub { commit }; begin_work;
   my $list = shift;
   %{$list} = ();
   $list->offset(0);
   $list->top(0);
};

our ($OFFSET,$TOP);
sub normalize { my ($this, $key) = @_;
    $key = int $key;
	$TOP = $this->top;
    $key < 0 and $key += $TOP;
	$OFFSET = $this->offset;
    $key + $OFFSET
}
sub EXISTS { my ($this, $key) = @_;
    local $OnExit = sub { rollback }; begin_work;
    exists $this->{$this->normalize($key)}
}
sub FETCH { my ($this, $key) = @_;
    local $OnExit = sub { rollback }; begin_work;
    $this->{$this->normalize($key)}
}
sub DELETE { my ($this, $key) = @_;
    local $OnExit = sub { commit }; begin_work;
    my $N = $this->normalize($key);
	$N >= $TOP and return; ## out of range
	my $retval = delete $this->{$N};
    ### SIZE REDUCTION ON DELETION OF LAST ELEMENT:
    if ( (1+$N) == $TOP ){
	    while ($TOP-- > $OFFSET ){
		    exists $this->{--$N} and last;
		};
		$this->top($TOP)   
    };
	$retval
}

sub STORE { my ($this, $key, $value) = @_;
    local $OnExit = sub { commit }; begin_work;
    my $N = $this->normalize($key);
    $N < $OFFSET
        and Carp::croak "Modification of non-creatable array value attempted, subscript $key";
    $TOP > $N or $this->top($N+1);
    $this->{$N} = $value;
}
sub FETCHSIZE { my ($this) = @_;
    local $OnExit = sub { rollback }; begin_work;
    my $size = $this->top - $this->offset;
	DEBUG and warn "returning size $size";
	$size
}
sub STORESIZE { my ($this, $count) = @_;
       local $OnExit = sub { commit }; begin_work;
       $count = int $count;
       if($count <= 0){
         %{$this} = ();
         $this->offset(0);
         $this->top(0);
		 return
	   };
	   my $N = $this->normalize($count - 1);
       $TOP - $OFFSET == $count and return;  # no-op
       # delete [$count] and all elements north of it
       while ($N < $TOP){
           delete $this->{$N++};
	   };
       $this->top($OFFSET + $count);
}
sub    PUSH { my ($this, @LIST) = @_;
       local $OnExit = sub { commit }; begin_work;
       $TOP = $this->top;
       while (@LIST){
            $this->{$TOP++} = shift @LIST;
       };
	   $this->top($TOP)
}
sub    POP { my ($this) = shift;
        local $OnExit = sub {
        		$this->top($TOP);
				commit
		};
        begin_work;
        $TOP = $this->top;
		$TOP > $this->offset and return delete $this->{--$TOP}
}
sub    SHIFT { my ($this) = @_;
       local $OnExit = sub {
	       DEBUG and warn "checkpoint in scope-exit";
	       $this->offset($OFFSET);
    	   commit 
	   };
	   begin_work;
       $TOP = $this->top;
	   $OFFSET = $this->offset;
DEBUG and warn "checkpoint: $$this normalized range ($OFFSET .. $TOP)";
       $TOP == $OFFSET and return undef;
       delete $this->{$OFFSET++};
}

sub    UNSHIFT { my ($this, @LIST) = @_;
       local $OnExit = sub { commit }; begin_work;
	   $OFFSET = $this->offset;
       while (@LIST){
            $this->{--$OFFSET} = pop @LIST;
       };
	   DEBUG and warn "unshift changing offset to $OFFSET";
       $this->offset($OFFSET);
}
sub EXTEND {} ## AA has an autoload, so we need this even though it's a no-op
1;