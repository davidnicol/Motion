

package TipJar::Motion::list;
use TipJar::Motion::type 'LIST';
use parent TipJar::Motion::AA;
use TipJar::Motion::configuration;
BEGIN{
         *offset = accessor('list index offset');
		 *top = accessor('list index top')
};
use strict;

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
	delete $this->{$N};
    ### SIZE REDUCTION ON DELETION OF LAST ELEMENT:
    if ( (1+$N) == $TOP ){
	    while ($TOP-- > $OFFSET ){
		    exists $this->{--$N} and last;
		};
		$this->top($TOP)   
    };
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
    $this->top - $this->offset
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
	       $this->offset($OFFSET);
    	   commit 
	   };
	   begin_work;
       $TOP = $this->top;
	   $OFFSET = $this->offset;

       $TOP == $OFFSET and return undef;
       delete $this->{$OFFSET++};
}

sub    UNSHIFT { my ($this, @LIST) = @_;
       local $OnExit = sub { commit }; begin_work;
	   $OFFSET = $this->offset;
       while (@LIST){
            $this->{--$OFFSET} = pop @LIST;
       };
       $this->offset($OFFSET);
}
sub EXTEND {} ## AA has an autoload, so we need this even though it's a no-op
1;