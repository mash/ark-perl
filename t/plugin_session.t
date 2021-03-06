use Test::Base;

{
    package TestApp;
    use Ark;

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory
        /;

    conf 'Plugin::Session::State::Cookie' => {
        cookie_expires => '+3d',
    };

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test_set :Local {
        my ($self, $c) = @_;
        $c->session->set('test', 'dummy');
    }

    sub test_get :Local {
        my ($self, $c) = @_;
        $c->res->body( $c->session->get('test') );
    }

    sub incr :Local {
        my ($self, $c) = @_;

        my $count = $c->session->get('count') || 0;
        $c->session->set( count => ++$count );

        $c->res->body( $count );
    }
}

plan 'no_plan';

use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

{
    my $res = request(GET => '/test_set');
    like( $res->header('Set-Cookie'), qr/testapp_session=/, 'session id ok');

    is(get('/test_get'), 'dummy', 'session get ok');
}

{
    is(get('/incr'), 1, 'increment first ok');
    is(get('/incr'), 2, 'increment second ok');
    reset_app;

    is(get('/incr'), 1, 're-increment first ok'); # XXX: this is test for Ark::Test: should be sepalate test.
    is(get('/incr'), 2, 're-increment second ok');
}
