use Test::Base qw/no_plan/;
use Path::Class;

{
    package T;
    use Ark;
    use_plugins qw/Log::Dispatch/;

    package T::Controller::Root;
    use Ark 'Controller';
    has namespace => default => '';

    sub index :Path {
        my ($self, $c) = @_;

        $c->log->debug('hi');
        $c->res->body( 'hi' );
    }
}


use Ark::Test 'T', components => [
    qw/
        Controller::Root
        /
];

my ($res, $c) = ctx_request(GET => '/');
is($res->content, 'hi', 'hi');
isa_ok( $c->log, 'Log::Dispatch', 'log is Log::Dispatch' );

# logfile check and cleanup
my $logfile = file( 'log.txt' );
is( $logfile->slurp, 'hi', 'logfile ok' );

$logfile->remove if -e $logfile;
