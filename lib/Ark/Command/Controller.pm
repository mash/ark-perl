package Ark::Command::Controller;
use Mouse;

with 'Ark::Command::Interface::ModuleSetup';

1;

__END__

=head1 NAME

Ark::Command::Controller;

=head1 SYNOPSIS

 ark.pl controller [options] [target] [base_class]

 Options:
  -i --init    just init your view flavor
  -f --flavor  flavor name for your template (default: default)

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
