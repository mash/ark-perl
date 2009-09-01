package Ark::Plugin::Log::Dispatch;
use Ark::Plugin;

use Log::Dispatch;
use Log::Dispatch::Config;
use Log::Dispatch::Configurator::YAML;
use MouseX::Types::Path::Class;
use Path::Class;

has _log_conf_file  => ( is => 'rw', isa => 'Path::Class::File', lazy => 1,
                              default => sub {
                                  my ($context) = @_;
                                  my $home = dir( $context->app->config->{home} );
                                  return unless $home;
                                  return $home->file( 'log.yml' );
                              } );

has _log_dispatch   => ( is => 'rw', isa => 'Log::Dispatch', lazy => 1,
                              default => sub {
                                  my ($context) = @_;
                                  Log::Dispatch::Config->configure_and_watch(
                                      Log::Dispatch::Configurator::YAML->new( $context->_log_conf_file->stringify )
                                  );
                                  return Log::Dispatch::Config->instance;
                              } );

sub log {
    my $context = shift;
    return $context->_log_dispatch( @_ );
}

1;
