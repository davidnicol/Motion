

package TipJar::Motion::list;
use parent TipJar::Motion::AA;
use TipJar::Motion::configuration;
BEGIN{
         *offset = accessor('list index offset');
		 *top = accessor('list index top')
};
use strict;

sub init{
   my $list = shift;
   @$list = ();
   $list
}
use overload '@{}' => sub { tie my @A, __PACKAGE__, $_[0]; \@A };

sub TIEARRAY { $_[1] }

sub CLEAR{
   my $list = shift;
   %{$list} = ();
   $list->offset(0);
   $list->top(0);
};

sub normalize { my ($this, $key) = @_;
    $key = int $key;
    $key < 0 and $key += $this->top;
    $key + $this->offset;
}
sub EXISTS { my ($this, $key) = @_;
    exists $this->{$this->normalize($key)}
}
sub FETCH { my ($this, $key) = @_;
    $this->{$this->normalize($key)}
}
sub DELETE { my ($this, $key) = @_;
    my $N = $this->normalize($key);
    ### SIZE REDUCTION ON DELETION OF LAST ELEMENT:
    if ( (1+$N) == $this->top ){

	I STOPPED HERE

	$N == $this->[sortedkeys]->[-1] and pop @{$this->[sortedkeys]};
       my $newtop = $this->[sortedkeys]->[-1];
       if (defined $newtop){
           $this->[top] = 1+$newtop
       }else{
           $this->[top] = $this->[offset]
       }
    } else {
       exists $this->[data]->{$N}
       and splice @{$this->[sortedkeys]}, $this->LocateKey($N), 1;
    }
    delete $this->[data]->{$N};
}
sub LocateKey{ my ($this, $N) = @_; # return an OFFSET for splice in DELETE and STORE
   my ($lower, $upper) = (0, $#{$this->[sortedkeys]});

   while ($lower < $upper){
      my $guess = int (( 1+ $lower + $upper) / 2);
      
      my $val = $this->[sortedkeys]->[$guess];
      $val == $N and return $guess;
      if ($val > $N){
           $upper = $guess - 1;
      }else{
           $lower = $guess;
      }

   };
   $lower

}

sub    STORE { my ($this, $key, $value) = @_;
    my $N = $this->normalize($key);
    $N < $this->[offset] 
        and Carp::croak "Modification of non-creatable array value attempted, subscript $key";
    unless (exists $this->[data]->{$N}){
         my $location = 1+$this->LocateKey($N);
         splice @{$this->[sortedkeys]}, $location, 0,$N;
         $this->[top] > $N or $this->[top] = ($N+1);
    };
    $this->[data]->{$N} = $value;
}
sub    FETCHSIZE { my ($this) = @_;
       $this->[top] - $this->[offset]
}
sub    STORESIZE { my ($this, $count) = @_;
       $count = int $count;
       $count <= 0 and return $this->CLEAR;
       my $before = $this->FETCHSIZE;
       $before == $count and return;  # no-op
       if ($before < $count){ # extend the apparent length
             $this->[top] = $this->[offset]+$count;
             return
       };
       # delete [$count] and all elements north of it
       my $N = $this->normalize($count - 1);
       while ($this->[sortedkeys]->[-1] > $N ){
            my $nn = pop @{$this->[sortedkeys]};
            delete $this->[data]->{$nn};
       }
       $this->[top] = $this->[offset]+$count;
}
sub    PUSH { my ($this, @LIST) = @_;
       while (@LIST){
            $this->[data]->{$this->[top]} = shift @LIST;
            push @{$this->[sortedkeys]}, $this->[top]++
       };
}
sub    POP { my ($this) = @_;
       if (exists $this->[data]->{--$this->[top]}){
                pop @{$this->[sortedkeys]};
                return delete $this->[data]->{$this->[top]}
       }
}
sub    SHIFT { my ($this) = @_;
       $this->[top] == $this->[offset] and return undef;
       $this->[sortedkeys]->[0] == $this->[offset] and shift @{$this->[sortedkeys]};
       delete $this->[data]->{$this->[offset]++};
}

sub    UNSHIFT { my ($this, @LIST) = @_;
       my $offset = $this->[offset];
       while (@LIST){
            $this->[data]->{--$offset} = pop @LIST;
            unshift @{$this->[sortedkeys]}, $offset
       };
       $this->[offset] = $offset;
}








