package RevML::Web::DBI::Count;

=head1 NAME

RevML::Web::DBI::Count -- DBI class for table 'count'

=cut

use strict;
use base 'RevML::Web::DBI';

RevML::Web::DBI::Count->table('count');
RevML::Web::DBI::Count->columns(All => qw/countid revml kind event counts/);
RevML::Web::DBI::Count->has_many(revmls => 'RevML::Web::DBI::RevML');

RevML::Web::DBI::Count->set_sql(count_directory => "SELECT revml,kind,event,counts FROM __TABLE__ WHERE kind='directory' AND revml = ?");

RevML::Web::DBI::Count->set_sql(somekind => "SELECT revml,kind,event,counts FROM __TABLE__ WHERE revml = ? AND kind = ?");

RevML::Web::DBI::Count->set_sql(count_one_author => "SELECT revml,kind,event,counts FROM __TABLE__ WHERE revml = ? AND kind = ?");

RevML::Web::DBI::Count->set_sql(count_project_kind => qq{
    SELECT kind, SUM(counts) as counts
    FROM   count,revml,project
    WHERE  kind= ?
    AND project.prjid= ?
    AND project.prjid=revml.prjid
    AND revml.revml = count.revml
    GROUP BY project.prjid});

RevML::Web::DBI::Count->set_sql(distinct_project_kind => qq{
    SELECT distinct kind AS kind
    FROM   count,revml,project
    WHERE project.prjid= ?
    AND project.prjid=revml.prjid
    AND revml.revml = count.revml
    GROUP BY project.prjid});

RevML::Web::DBI::Count->set_sql(distinct_project_some_kind => qq{
    SELECT distinct kind AS kind
    FROM   count,revml,project
    WHERE project.prjid= ?
    AND project.prjid=revml.prjid
    AND revml.revml = count.revml
    AND kind like ?
    GROUP BY project.prjid});

sub count_directory {
    my($self,@arg) = @_;
    return $self->search_count_directory(@arg);
}

sub count_author {
    my($self,@arg) = @_;
    return $self->search_count_one_author(@arg);
}


RevML::Web::DBI->set_sql(count_subdir => 'SELECT revml,kind,event,counts FROM __TABLE__ WHERE revml = ? AND kind LIKE "/%" ORDER BY counts DESC');

1;

=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut
