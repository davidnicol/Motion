
package TipJar::Motion::demonstration_command_line;

use lib 'lib';
use TipJar::Motion::Mote;
use TipJar::Motion::stream;
use TipJar::Motion::engine;
my $input = streamify(\*STDIN);
my $output = streamify(\*STDOUT);
my $engine = TipJar::Motion::engine->new($input,$output);
while($engine->process()){
    if ($engine->failure){
         warn $engine->failure,"\n";
         $engine->failure('')
    }
};
$engine->failure and warn $engine->failure,"\n";
__END__

