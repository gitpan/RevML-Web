package RevML::Web::DBI::Revision;

=head1 NAME

RevML::Web::DBI::Revision -- Revision management database backend

=cut

use base 'RevML::Web::DBI';

RevML::Web::DBI::Revision->table('rev');
RevML::Web::DBI::Revision->columns(All => qw/rev revml author target_path comment/);
RevML::Web::DBI::Revision->columns(TEMP => qw/counts/);
RevML::Web::DBI::Revision->has_a(revml => 'RevML::Web::DBI::RevML');

RevML::Web::DBI->set_sql(count_rev => "SELECT COUNT(*) FROM __TABLE__ WHERE revml = ? ");

RevML::Web::DBI->set_sql(count_author => "SELECT author,COUNT(author) as counts FROM __TABLE__ WHERE revml = ? GROUP BY author");

sub count_rev {
    my($self,@arg) = @_;
    my $sth = $self->sql_count_rev;
    return $self->sql_count_rev->select_val(@arg);
}

sub count_author {
    my($self,@arg) = @_;
    return $self->search_count_author(@arg);
}

1;

=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut
