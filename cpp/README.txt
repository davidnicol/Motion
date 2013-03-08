
the Tokenizer directory contains the beginning of Motion in C++.

The program there divides its stdin into whitespace and symbols,
essentially doing


    local $/=undef;
    @Input = split /(\s+)/, (<STDIN>);

and dumping the results. Plus, of course, which line each item
started at.
 
