
package TipJar::Motion::demonstration_command_line;

use lib 'lib';
use TipJar::Motion::bootstrap;
use TipJar::Motion::stream;
use TipJar::Motion::engine;
use TipJar::Motion::default_parser;
my $input = streamify(\*STDIN);
my $output = streamify(\*STDOUT);
my $engine = TipJar::Motion::engine->new(
      $input,$output,TipJar::Motion::default_parser->new
);
while($engine->process()){
    if ($engine->failure){
         warn $engine->failure,"\n";
         $engine->failure('')
    }
};
$engine->failure and warn $engine->failure,"\n";
__END__

