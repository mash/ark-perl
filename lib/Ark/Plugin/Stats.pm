package Ark::Plugin::Stats;
use Ark::Plugin;

has _debug_report => (
    is      => 'rw',
    isa     => 'Text::SimpleTable',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded('Text::SimpleTable');
        Text::SimpleTable->new([62, 'Action'], [9, 'Time']);
    },
);

has _debug_report_stack => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has _debug_stack_traces => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

around process => sub {
    my $next = shift;
    my ($self,) = @_;

    $self->ensure_class_loaded('Time::HiRes');
    my $start = [Time::HiRes::gettimeofday()];

    my $res = $next->(@_);

    my $elapsed = sprintf '%f', Time::HiRes::tv_interval($start);
    my $av      = $elapsed == 0 ? '??' : sprintf '%.3f', 1 / $elapsed;
    _log( debug =>
                  "Request took ${elapsed}s (${av}/s)\n%s", $self->_debug_report->draw);

    if (my @error = @{ $self->error }) {
        $self->_dump_stack_trace;
    }

    $res;
};

after prepare_action => sub {
    my $self = shift;
    my $req  = $self->request;

    if ( keys %{ $req->parameters } ) {
        $self->ensure_class_loaded('Text::SimpleTable');
        my $t = Text::SimpleTable->new( [ 35, 'Parameter' ], [ 36, 'Value' ] );
        for my $key ( sort keys %{ $req->parameters } ) {
            my $param = $req->parameters->{$key};
            my $value = defined($param) ? $param : '';
            $t->row( $key,
                ref $value eq 'ARRAY' ? ( join ', ', @$value ) : $value );
        }
        my $message = $t->draw;
        chomp $message;

        _log( debug => "Query Parameters are:\n$message" );
    }
    _log( debug => q/"%s" request for "%s" from "%s"/,
                $req->method, $req->path, $req->address );
};

around execute_action => sub {
    my $next = shift;
    my ($self, $obj, $method, @args) = @_;

    local $SIG{__DIE__} = sub {
        my ($reason) = @_;
        return if $reason =~ /^ARK_DETACH/;
        return if $^S; # see perldoc perlvar, true if executing an eval

        $self->ensure_class_loaded('Devel::StackTrace');
        my $trace = Devel::StackTrace->new(
            ignore_package => [
                qw/Ark::Core
                   Ark::Action
                   Ark::Context::Debug
                   Ark::Context
                   Ark::Plugin::Stats
                   HTTP::Engine::Middleware/, # be sure it's stable
            ],
            no_refs => 1,
        );
        $self->_debug_stack_traces([ $trace->frames ]);

        $self->_dump_stack_trace( $reason );
    };

    $self->ensure_class_loaded('Time::HiRes');
    $self->stack->[-1]->{start} = [Time::HiRes::gettimeofday()];

    my $res = $next->(@_);

    my $last    = $self->stack->[-1];
    my $elapsed = Time::HiRes::tv_interval($last->{start});

    my $name;
    if ($last->{obj}->isa('Ark::Controller')) {
        $name = $last->{obj}->namespace
            ? '/' . $last->{obj}->namespace . '/' . $last->{method}
            : '/' . $last->{method};
    }
    else {
        $name = $last->{as_string};
    }

    if ($self->depth > 1) {
        $name = ' ' x $self->depth . '-> ' . $name;
        push @{ $self->_debug_report_stack }, [ $name, sprintf("%fs", $elapsed) ];
    }
    else {
        $self->_debug_report->row( $name, sprintf("%fs", $elapsed) );
        while (my $report = shift @{ $self->_debug_report_stack }) {
            $self->_debug_report->row( @$report );
        }
    }

    $res;
};

sub _log {
    my ($type, $msg, @args) = @_;
    print STDERR sprintf("[%s] ${msg}\n", $type, @args);
}

sub _dump_stack_trace {
    my ($self, $reason) = @_;

    _log( error => "%s", $reason );

    for my $frame (@{ $self->_debug_stack_traces }) {
        last if $frame->package =~ /^HTTP::Engine::Role::Interface/;
        _log( error => "%s - line: %d\n%s", $frame->package, $frame->line, $self->debug_print_context( $frame->filename, $frame->line, 3 ) );
    }

}

# copied and filtered out html escape from Ark::Context::Debug
sub debug_print_context {
    my ($self, $file, $linenum, $context) = @_;

    my $code = q[];
    if (-f $file) {
        my $start = $linenum - $context;
        my $end   = $linenum + $context;
        $start = $start < 1 ? 1 : $start;
        if ( my $fh = IO::File->new( $file, 'r' ) ) {
            my $cur_line = 0;
            while ( my $line = <$fh> ) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                $code .= sprintf( '%5d: %s', $cur_line, $line );
            }
        }
    }
    return $code;
}

1;
