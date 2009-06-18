use Test::Base qw/no_plan/;
use FindBin;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub wrapped :Local :Args(0) {
        my ($self, $c) = @_;
        $c->forward( $c->view('MTFile') );
    }

    package TestApp::View::MTFile;
    use Ark 'View::MTFile';

    has '+include_path' => default => sub { ["$FindBin::Bin/mt"] };
    has '+wrapper'      => default => sub { 'wrapper.mt'; };
}

{
    use Ark::Test 'TestApp',
        components => [qw/Controller::Root View::MTFile/];

    {
        my $content = get('/wrapped');
        is($content, '123[wrapped]456', 'wrapped ok');
    }
}
