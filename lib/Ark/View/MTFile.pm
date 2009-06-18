package Ark::View::MTFile;
use Ark 'View::MT';

has wrapper      => ( is => 'rw', isa => 'Str', lazy => 1, default => sub { ''; }, );
has wrapper_pre  => ( is => 'rw', isa => 'Str', lazy => 1, default => sub {
                          my $self = shift;
                          return '<? $__mt->wrapper_file(\'' . $self->wrapper . "')->( sub {?>";
                      } );
has wrapper_post => ( is => 'rw', isa => 'Str', default => sub { "<? })?>"; } );

has '+mt' => (
    is      => 'rw',
    isa     => 'Text::MicroTemplate::File',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->ensure_class_loaded('Text::MicroTemplate::File');
        Text::MicroTemplate::File->new(
            package_name => __PACKAGE__,
            %{ $self->options }
        );
    },
);

has +options => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        +{
            include_path => $self->include_path,
        };
    },
);

=item render

render with wrapper

=cut

sub render {
    my $self     = shift;
    my $template = shift;

    $template ||= $self->context->stash->{__view_mt_template}
              || $self->context->request->action->reverse
                  or return;

    my $renderer = $self->build_template_with_wrapper($template . $self->extension);
    $renderer->($self->context, @_)->as_string;
}

=item include

do <?=r $self->include('include_target', 'foo', 'bar'); ?>
to include another mt file with some arguments.

dont use <?=r $self->render('include_target') ?>
cause this uses your wrapper.

=cut

sub include {
    my $self     = shift;
    my $template = shift;

    $template ||= $self->context->stash->{__view_mt_template}
              || $self->context->request->action->reverse
                  or return;

    my $renderer = $self->build_template($template . $self->extension);
    $renderer->($self->context, @_)->as_string;
}

sub build_template_with_wrapper {
    my ($self, $template) = @_;

    # return cached entry
    if ($self->use_cache == 2) {
        if (my $e = $self->cache->{$template}) {
            return $e->[1];
        }
    }

    # iterate
    for my $path (@{ $self->include_path }) {
        my $filepath = $path . '/' . $template;

        if (my @st = stat $filepath) {
            if (my $e = $self->cache->{$template}) {
                return $e->[1] if $st[9] == $e->[0];
            }

            open my $fh, "<".$self->open_layer, $filepath
                or die qq/failed to open "$filepath": $!/;
            my $src = do { local $/; <$fh> };
            close $fh;

            # wrap it up
            if ( $self->wrapper ) {
                $src = $self->wrapper_pre . $src . $self->wrapper_post;
            }

            $self->mt->parse($src);
            my $renderer = $self->build;

            $self->cache->{$template} = [ $st[9], $renderer ];
            return $renderer;
        }
    }
    die "could not find template file: $template";
}

__PACKAGE__->meta->make_immutable;
