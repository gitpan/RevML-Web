package RevML::Web::DB;
use strict;
use RevML::Web '-Base';
use RevML::Web::DBI;
use RevML::Web::DBI::Project;
use RevML::Web::DBI::Statistic;
use RevML::Web::DBI::RevML;
use RevML::Web::DBI::Revision;
use RevML::Web::DBI::Count;

=head1 NAME

RevML::Web::DB -- The RevML::Web database class in Spoon architecture.

=head1 DESCRIPTION


The DB class are the glue of DBI and Spoon
architecture. Upon the init() phrase of RevML::Web,
the database connection is setup, and thus provide the
database singeleton object to hook on the Spoon Hub.

It also provide some helper functions to combine several DBI
queries together.

=cut

our $VERSION = '0.01';

const class_id => 'database';

sub init {
    $self->use_class('main');
    $self->use_class('config');
    my $conf = $self->config;
    RevML::Web::DBI->connection($conf->db_dsn,$conf->db_user,$conf->db_password);
}

=head2 search( type , text );

A general search subroutine.

=cut

sub search {
    my ($type,@arg) = @_;
    my $method = "search_$type";
    return $self->$method(@arg);
}

sub search_project {
    my ($name) = @_;
    my ($prjid) = $self->project->search(name => $name);
    return $prjid;
}

sub search_revml {
    my ($text) = @_;
    my ($revml) = $self->revml->search_like(path => "\%$text\%");
    return $revml;
}

sub search_count {
    my ($proj,$kind) = @_;
    my @counts = $self->count->search(kind=>$kind,revml=>$proj);
    return wantarray? @counts : \@counts;
}

sub search_statistic {
    my ($proj,$kind) = @_;
    my @counts = $self->statistic->search(kind=>$kind,prjid=>$proj);
    return wantarray? @counts : \@counts;
}

=head2 set( thing , arg );

A general set subroutine. $thing can be one of count,revml,revision.

=cut

sub set {
    my ($thing,@arg) = @_;
    my $method = "set_$thing";
    return $self->$method(@arg);
}

sub set_count {
    my ($args) = @_;
    my $id = $self->count->find_or_create
        ({ revml => $args->{revml},
         kind => $args->{kind},
         event => $args->{event},
         counts => $args->{counts},
         });
    return $id;
}

sub set_statistic {
    my ($args) = @_;
    my $id = $self->statistic->find_or_create
        ({ prjid => $args->{prjid},
         kind => $args->{kind},
         event => $args->{event},
         counts => $args->{counts},
         });
    return $id;
}

sub set_revml {
    my ($id,$thing,$value) = @_;
    my $revml = $self->revml->retrieve(revml=>$id);
    if(!defined($value)) {
        $revml->$thing(1);
    } else {
        $revml->$thing($value);
    }
    $revml->update();
}

=head2 add($thing,@arg)

A General add subroutine, $thing can be one of
revision,revml.

    add(revml=>$file,prjid=>$prjid)

=cut

sub add {
    my ($thing,@arg) = @_;
    my $method = "add_$thing";
    return $self->$method(@arg);
}

sub add_revision {
    my $param = shift;
    my $id =  $self->revision->find_or_create($param);
    return $id;
}

sub add_project {
    my $prjname = shift;
    my $id = $self->project->find_or_create(name=>$prjname);
    return $id;
}

sub add_revml {
    my $file = shift;
    my @args = @_;
    my $id = $self->revml->find_or_create(path=>$file,@args);
    return $id;
}

=head2 get( $thing , @arg );

A general get' subroutine. $thing can be one of
count, revision.

=cut

sub get {
    my ($thing,@arg) = @_;
    my $method = "get_$thing";
    return $self->$method(@arg);
}

sub get_count {
    my $id = shift;
    return $self->count->retrieve(countid => $id);
}

sub get_revision {
    my $id = shift;
    return $self->revision->retrieve(rev => $id);

}

=head2 projects

Return all projects

=cut

sub projects {
    return $self->project->retrieve_all;
}

=head2 counts ( $project )

Return the statistic counts of a certain $project.

=cut

sub counts {
    return $self->search_count(@_);
}

=head2 revs( $project )

Retrieve all revision id of a certain project.

=cut

sub revs {
    my $revml = shift;
    my @revs = $self->revision->search(revml => $revml);
    return wantarray? @revs : \@revs;
}

=head2 rev_counts ($project)

Return the number of revisions of a certain project.

=cut

sub rev_counts {
    my $revml = shift;
    my ($revs) = $self->revision->count_rev($revml);
    return $revs;
}

=head2 authors ($revml)

Return all authors and their revision counts of a revml.

=cut

sub authors {
    my $revml = shift;
    my @counts = $self->revision->count_author($revml);
    return wantarray? @counts : \@counts;
}

=head2 author ($revml,$author)

Return all directory counts for an author;

=cut

sub author {
    my ($revml,$author) = @_;
    my @counts = $self->count->count_author($revml,$author);
    return wantarray? @counts : \@counts;
}

=head2 directories ($revml)

Return all directories and their revision counts of a revml.

=cut

sub directories {
    my $revml = shift;
    $revml = $revml->revml if(ref($revml));
    warn "Retrieve directory counts for revml [$revml]\n";
    my @counts = $self->count->search_count_directory($revml);
    return wantarray? @counts : \@counts;
}

=head2 subdirectories ($revml)

Return all directories and their revision counts of a revml.

=cut

sub subdirectories {
    my $revml = shift;
    my @counts = $self->count->search_count_subdir($revml);
    return wantarray? @counts : \@counts;
}

=head2 reset_dirty_flags

Reset the dirty flags to zero.

=cut

sub reset_dirty_flags {
    my @allproj = $self->revml->retrieve_all;
    for(@allproj) {
	$_->counted(0);
	$_->graphed(0);
	$_->update;
    }
}

sub project_directories {
    my $prj = shift;
    my @dirs = $self->count->search_distinct_project_some_kind($prj->prjid,'%/%');
    map { $_->kind } @dirs;
}

my %wrapper = (
    revml    => 'RevML',
    count    => 'Count',
    project  => 'Project',
    revision => 'Revision',
    statistic => 'Statistic',
   );

for (keys %wrapper) {
    my $pkg = $wrapper{$_};
    eval "sub ${_} {return RevML::Web::DB::$pkg->new;}";
}

package RevML::Web::DB::RevML;
sub new { bless {} }
sub AUTOLOAD {
    my $func = $RevML::Web::DB::RevML::AUTOLOAD;
    $func =~ s/.*:://;
    RevML::Web::DBI::RevML->$func(@_);
}
package RevML::Web::DB::Revision;
sub new { bless {} }
sub AUTOLOAD {
    my $func = $RevML::Web::DB::Revision::AUTOLOAD;
    $func =~ s/.*:://;
    RevML::Web::DBI::Revision->$func(@_);
}
package RevML::Web::DB::Count;
sub new { bless {} }
sub AUTOLOAD {
    my $func = $RevML::Web::DB::Count::AUTOLOAD;
    $func =~ s/.*:://;
    RevML::Web::DBI::Count->$func(@_);
}
package RevML::Web::DB::Statistic;
sub new { bless {} }
sub AUTOLOAD {
    my $func = $RevML::Web::DB::Statistic::AUTOLOAD;
    $func =~ s/.*:://;
    RevML::Web::DBI::Statistic->$func(@_);
}
package RevML::Web::DB::Project;
sub new { bless {} }
sub AUTOLOAD {
    my $func = $RevML::Web::DB::Project::AUTOLOAD;
    $func =~ s/.*:://;
    RevML::Web::DBI::Project->$func(@_);
}


# XXX: Don't know why this would failed
#
# for(values %wrapper) {
#     eval qq{
#       package RevML::Web::DB::${_};
# 	sub new { bless {} }
# 	sub AUTOLOAD {
# 	    my \$func = \$RevML::Web::DB::${_}::AUTOLOAD;
# 	    \$func =~ s/.*::(.+)\$/\$1/;
# 	    RevML::Web::DBI::${_}->\$func(\@_);
# 	}
#     };
# }


1;

