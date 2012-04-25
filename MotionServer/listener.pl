#!/usr/local/bin/perl

=pod

we want to open a listening unix socket at /motion/motionsocket
and respond to motion that occurs there.

=cut

use strict;
use JSON; my $json = new JSON; $json->indent; $json->allow_nonref;
$json->convert_blessed;
*UNIVERSAL::TO_JSON = sub {
       eval { $_[0]->MoteID } || {EPHEMERAL => "$_[0]"}
};

use lib 'lib';
use TipJar::motion;
use Socket;

my $NAME = "/motion/motionsocket";
my $uaddr = sockaddr_un($NAME);
socket(Server, PF_UNIX, SOCK_STREAM, 0) || die "socket: $!";
unlink($NAME);
bind  (Server, $uaddr)                  || die "bind: $!";
chmod 0777, $NAME;
listen(Server, SOMAXCONN)               || die "listen: $!";
    

### new process for every connection -- K.I.S.
$SIG{CHLD} = 'IGNORE';
fork;fork; # now we have four Listener processes waiting
for(;;){
             accept(Client, Server) or next; # accept can be interupted
             warn localtime." new connection";
             fork or last; # the child handles. The parent keeps listening.
             close Client;
};
close Server;
my $processor = TipJar::motion::NewEngine(*Client);
warn "using engine $processor";
my @response;
my $rcount = 0;
warn "alarm set; entering loop";
for(;;){
    warn "alarm cleared in loop";
    unless (eval { @response = $processor->dopending ;1 } ){
          warn "processor->dopending died";
          print Client "UNEXPECTED INTERNAL MOTION PROCESSOR ERROR: [$@]\n";
          exit
    };
    warn "got response: [@response]";
    $rcount += @response;
                   
    if (@response) {
            print Client ((ref $_ ? $json->encode($_) : $_ ),"\n") for @response;
            @response = ()
    };


   $processor->GetMoreInput() or exit

}


__END__


