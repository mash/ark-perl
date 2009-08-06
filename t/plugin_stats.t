use Test::Base qw/no_plan/;

{
    package TestApp;
    use Ark;
    use_plugins qw/Stats/;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub auto :Private {
        my ($self, $c) = @_;
        return 1;
    }

    sub index :Path :Args(0) {
        my ($self, $c) = @_;

        $c->res->body('hi');
    }
}

use Ark::Test 'TestApp',
    components => [
        qw/
            Controller::Root
            /
    ];
use HTTP::Request::Common;

{
    my $output;
    open my $OUT, '>', \$output;
    local *STDERR = *$OUT;

    my $res = request( GET => '/?foo=bar');
    like( $output, qr( Action[ ]+\| Time ), 'Action, Time ok' );
    like( $output, qr(\/auto[ ]+| [\.0-9]+s), 'auto action measured' );
    like( $output, qr(\/index[ ]+| [\.0-9]+s), 'index action measured' );
    like( $output, qr(foo.+bar), 'foo,bar param dumped' );

    close($OUT);
}

{
    my $output;
    open my $OUT, '>', \$output;
    local *STDERR = *$OUT;

    my $req = POST '/', [ foo => 'bar' ];
    my $res = request( $req );
    like( $output, qr( Action[ ]+\| Time ), 'Action, Time ok' );
    like( $output, qr(\/auto[ ]+| [\.0-9]+s), 'auto action measured' );
    like( $output, qr(\/index[ ]+| [\.0-9]+s), 'index action measured' );
    like( $output, qr(foo.+bar), 'foo,bar param dumped' );

    close($OUT);
}
