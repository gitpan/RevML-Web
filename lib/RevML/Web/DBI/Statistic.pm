package RevML::Web::DBI::Statistic;

=head1 NAME

RevML::Web::DBI::Statistic - table 'statistic'

=cut

use strict;

use strict;
use base 'RevML::Web::DBI';

RevML::Web::DBI::Statistic->table('statistic');
RevML::Web::DBI::Statistic->columns(All => qw/sid prjid kind event counts/);
RevML::Web::DBI::Statistic->has_a(prjid => 'RevML::Web::DBI::Project');

RevML::Web::DBI->set_sql(subdir => 'SELECT prjid,kind,event,counts FROM __TABLE__ WHERE prjid = ? AND kind LIKE "/%" ORDER BY counts DESC');

RevML::Web::DBI->set_sql(author => 'SELECT prjid,kind,event,counts FROM __TABLE__ WHERE prjid = ? AND kind = ? ORDER BY counts DESC');

1;

=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut
