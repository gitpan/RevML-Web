
use Test::Simple tests => 7;

use RevML::Web;
ok(1);

my($main,$hub,$cmd,$db,$config,$template);

ok $main     = RevML::Web->new;
ok $hub      = $main->load_hub;
ok $cmd      = $hub->load_class('command');
ok $db       = $hub->load_class('database');
ok $config   = $hub->load_class('config');
ok $template = $hub->load_class('template');

