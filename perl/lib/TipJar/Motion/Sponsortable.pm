package TipJar::Motion::Sponsortable;
use TipJar::Motion::configuration;
use Exporter;
our @EXPORT = qw/Sponsortable/;


=pod

for production, this needs to be rewritten according to your persistence system

or at least changed into coroutines that do small batches every so often, 
like while tearing down engines

=cut



{my $ST; sub Sponsortable{
    $ST ||= TipJar::Motion::configuration::sponsortable
} }

sub add{
    my ($T, $sponsor, $sponsee, $duration) = @_;
    $duration ||= TipJar::Motion::configuration::min_age();
    
    $T->{$$sponsee}{ $$sponsor} = time() + $duration;
}

sub del{
    my ($T, $sponsor, $sponsee) = @_;
    delete $T->{$$sponsee}{ $$sponsor};
}

sub MarkAndSweep{
    my $T = shift;
    my $Generation = time;

    # only run once per min_age
    $Generation < TipJar::Motion::configuration::generation() + TipJar::Motion::configuration::min_age() and return;

    # mark
    TipJar::Motion::configuration::generation($Generation);
    my %marks;
    my $M = TipJar::Motion::configuration::persistent_lexicon()->{marks} ||= {};
    my $last;
    for my $k ( sort keys %$T){
        $k =~ /^(\S+)/ or die "BAD KEY IN SPONSOR TABLE [$k]";
        $last eq $k and next;
        $M->{$k} = $Generation;
        $last = $k
    };

    # sweep motes 
    my @deletia = grep {
             $M->{$_} < $Generation
    } keys %{ TipJar::Motion::configuration::persistent_lexicon()->{motes} ||= {} };
    delete @{TipJar::Motion::configuration::persistent_lexicon()->{motes}}{@deletia};


};


1;

