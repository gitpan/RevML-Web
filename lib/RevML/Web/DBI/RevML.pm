package RevML::Web::DBI::RevML;

=head1 NAME

RevML::Web::DBI::RevML -- revml file management database interface

=cut

use strict;
use base 'RevML::Web::DBI';

RevML::Web::DBI::RevML->table('revml');
RevML::Web::DBI::RevML->columns(All => qw/revml prjid path counted graphed/);
RevML::Web::DBI::RevML->has_a(prjid => 'RevML::Web::DBI::Project');
RevML::Web::DBI::RevML->has_many(rev => 'RevML::Web::DBI::Revision');

1;

=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut
