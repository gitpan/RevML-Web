package RevML::Web::DBI::Project;

=head1 NAME

RevML::Web::DBI::Project - Presents the 'project' table.

=cut

use strict;
use base 'RevML::Web::DBI';

RevML::Web::DBI::Project->table('project');
RevML::Web::DBI::Project->columns(All => qw/prjid name/);
RevML::Web::DBI::Project->has_many(revml => 'RevML::Web::DBI::RevML');
RevML::Web::DBI::Project->has_many(statistic => 'RevML::Web::DBI::Statistic');


sub count_revision {
    my $self = shift;
    my $cnt = 0;
    for($self->revml) {
	$cnt += $_->rev->count;
    }
    return $cnt;
}

1;

=head1 TABLE DEFINITION



=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut

__DATA__
