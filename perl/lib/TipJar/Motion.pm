
package TipJar::Motion;
=pod

this is the base package for the release version -- the reference implementation -- of the Motion virtual machine and virtual machine language.

In "Motion" all objects are subclassed from the "Mote" base type

In "Motion" all objects are subclassed from the "Mote" base type

The syntax is like assembly language, in that operators take 
a fixed number of operands, depending on the operator

The paradigm is message passing

Motes persist

Motes have type

messages are in the form of streams of characters

Motes control the interpretation of their own input

The motion language is concerned with the definition of new motes

functionality outside the scope of definition of new motes is provided
by "adapters"

In this reference implementation, the base mote type is L<TipJar::Motion::mote>
and message passing is done via a L<TipJar::Motion::engine> which holds
references to the input and output file handles.

=cut

sub __my_stack_trace{
    my $level = 1;
    my $result = '';
    my @c;
    while(@c = caller($level++)){
       $result .= join '|', @c[0..7],"\n"
    };
    $result
}
sub AUTOLOAD{

    die __PACKAGE__
        . " is documentation only.\n$AUTOLOAD(@_) stack trace:\n"
        . __my_stack_trace

}



1;





1;
