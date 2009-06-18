use Test::Base qw/no_plan/;
use FindBin;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub forward :Local {
        my ($self, $c) = @_;
        $c->forward( $c->view('MTFile') );
    }

    sub render :Local {
        my ($self, $c) = @_;
        my $body = $c->view('MTFile')->render('render');
        $c->res->body($body);
    }

    sub template :Local {
        my ($self, $c) = @_;
        $c->view('MTFile')->template('forward');
        $c->forward('forward');
    }

    sub include :Local {
        my ($self, $c) = @_;
        $c->forward( $c->view('MTFile') );
    }

    package TestApp::View::MTFile;
    use Ark 'View::MTFile';

    has '+include_path' => default => sub { ["$FindBin::Bin/mt"] };
}

{
    use Ark::Test 'TestApp',
        components => [qw/Controller::Root View::MTFile/];

    {
        my $content = get('/forward');
        is($content, 'index mt', 'forward view ok');
    }

    {
        my $content = get('/render');
        is($content, 'render mt', 'render view ok');
    }

    {
        my $content = get('/template');
        is($content, 'index mt', 'set template view ok');
    }

    {
        my $content = get('/include');
        is($content, 'before included[foo,bar] after', 'include ok');
    }
}
