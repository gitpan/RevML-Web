package RevML::Web;
use strict;
use Spoon '-Base';

our $VERSION = '0.01';

const class_id => 'main';
const config_class => 'RevML::Web::Config';

field verbose => 0;
field quiet => 0;
field force => 0;
field allproj => {};

1;

__END__

=head1 NAME

RevML::Web - Display RevML Statistic on Web.

=head1 SYNOPSIS

Please see L<RevML::Web::Command> for command line usage.

=head1 DESCROPTION

The RevML::Web module is the main class for Revml-Web system.
The RevML-Web system reads in RevML files, dig out revision
informations, and out the processed statistics value.

For further information about the framework, please see
L<Spoon> and L<Spork>.

=head1 SEE ALSO

L<Spiffy> , L<Spoon> , L<Spork>

=head1 COPYRIGHT

Copyright 2003 by Kang-min Liu E<lt>gugod@gugod.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
