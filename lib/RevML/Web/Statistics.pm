package RevML::Web::Statistics;

use strict;
use RevML::Web '-Base';

our $VERSION = '0.01';
$|++;
# field 'cached_statistics';
# field 'cached_count';


sub init {
    $self->use_class('config');
    $self->use_class('main');
    $self->use_class('database');
    $self->use_class('template');
}


##################################################################

=head merge_count($prjname)

Merge all revml counts of a project.
Save them into table "statistic"

=cut

sub merge_count {
    my $prj = shift;
    my $prjname;
    unless(ref($prj)) {
	$prj = $self->database->project->search(name=>$prj)->first;
    }
    $prjname = $prj->name;
    $self->merge_count_allkind($prj);
}

sub merge_count_allkind {
    my ($prj) = @_;
    my @all = $self->database->count->search_distinct_project_kind($prj);
    for(@all) {
	$self->merge_count_somekind($prj,$_->kind);
    }
}

sub merge_count_somekind {
    my ($prj,$kind) = @_;
    my $prjname = $prj->name;
    warn "[$prjname]: Generating $kind statistics...\n";
    my $c = {};
    for($prj->revml) {
	my @dc = $self->database->count->search_somekind($_,$kind);
	for(@dc) {
	    $c->{$_->event} += $_->counts;
	}
    }
    warn "[$prjname]: Saving $kind statistic ....\n";
    for(keys %$c) {
	$self->database->set(statistic => {
	    prjid  => $prj->prjid,
	    kind   => $kind,
	    event  => $_,
	    counts => $c->{$_},
	   });
    }
}

##################################################################
sub count {
    my ($revml) = @_;
    my $db = $self->database;
    my @allrev  = $db->revs($revml);
    my $counts;
    my $progressed=0;
    for (@allrev) {
        print STDERR "Counting... " . (++$progressed *100)/scalar(@allrev)
            . "\%" ." " x 20 ."\r"
		unless $self->main->quiet;
        my $rev = $db->get(revision=>$_);
        my $r = {};
        $r->{$_} = $rev->$_ for(qw/target_path author/) ;
        $counts->{$_}->{$r->{$_}}++ for keys %$r;

	my $author = $rev->author;
# skip top-level files.
        unless($r->{target_path} =~ m{/}) {
	    $counts->{"$author"}->{"/"}++ if($author);
	    $counts->{'directory'}->{"/"}++;
	    next;
	}
# split paths;
        my $filename = '/' . $r->{target_path};
        my ($dir) = $filename =~ m/(.+)\/.*/;
        $counts->{'directory'}->{"$dir/"}++;

        $counts->{"$author"}->{"$dir/"}++ if($author);

	# in fact, revml.dtd define the <name> is in unix format
        my @dirs = split'/',$dir;

	my $parent_dir = '/';
	for(1..$#dirs) {
	    my $d = '/' . join'/',@dirs[1..$_];
	    $counts->{$parent_dir}->{$d}++;
	    $parent_dir = $d;
 	}

        my $topd = $dirs[1];
        $counts->{'top_level_directory'}->{"$topd/"}++;
        next if(scalar(@dirs) < 3);

        my $second = join'/',@dirs[1..2];
        $counts->{'second_level_directory'}->{"$second/"}++;
        next if(scalar(@dirs) < 4);

        my $third = join'/',@dirs[1..3];
        $counts->{'third_level_directory'}->{"$third/"}++;
    }
    $self->save_counts($revml,$counts);
    return $counts;
}

sub save_counts {
    my ($revml,$counts) = @_;
    for my $kind (keys %$counts) {
        for my $event (keys %{$counts->{$kind}}) {
            my $id = $self->database->set(count => {
                    revml => $revml,
                    kind => $kind,
                    event => $event,
                    counts => $counts->{$kind}->{$event}
                    });
            warn "Saving counts $id\n" unless $self->main->quiet;
        }
    }
}

##################################################################
## read things. Return them sorted by count
##################################################################

sub top_level_directory {
    my $prj = shift;
    my @arr =
	sort { $b->{counts} <=> $a->{counts} }
	map  { { event => $_->event, counts => $_->counts } }
	$self->database->statistic->search(prjid => $prj,
					   kind  => 'top_level_directory');
    return wantarray? @arr : \@arr;
}


sub authors {
    my $prj = shift;
    my @arr =
	sort { $b->{counts} <=> $a->{counts} }
	map { { author => $_->event, counts => $_->counts } }
	$self->database->statistic->search(prjid => $prj,
					   kind  =>'author');
    return wantarray? @arr : \@arr;
}

sub author {
    my ($prj,$author) = @_;
    my @arr =
	sort { $b->{counts} <=> $a->{counts} }
	map { { event => $_->event, counts => $_->counts } }
	$self->database->statistic->search(prjid => $prj,
					   kind  => $author);

    warn "$author has " .scalar(@arr) . " records\n";

    return wantarray? @arr : \@arr;
}

sub directories {
    my $prj = shift;
    my @arr =
	sort { $b->{counts} <=> $a->{counts} }
	map { { directory => $_->event, counts => $_->counts } }
	$self->database->statistic->search(prjid => $prj,
					   kind  => 'directory');
    return wantarray? @arr : \@arr;
}

=head2 subdir($prj)

Return subdirectories and their counts of a project

=cut

sub subdir {
    my $prj = shift;
    my @dir = $self->database->statistic->search_subdir($prj);
    my $c = {};
    for(@dir) {
	push @{$c->{$_->kind}},
	    {event => $_->event, counts => $_->counts};
    }
    return $c;
}


=head2 subdir_counts($revml)

Return subdirectories and their counts of a revml

=cut

sub subdir_counts {
    my $revml = shift;
    my @arr = $self->database->subdirectories($revml);
    my $dirs = {};
    for(@arr) {
	push @{$dirs->{$_->kind}},
	    {event => $_->event, counts => $_->counts};
    }
    return $dirs;
}

1;
