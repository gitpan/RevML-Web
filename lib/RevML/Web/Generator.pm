package RevML::Web::Generator;

### {{{ Start

=head1 NAME

RevML::Web::Generator -- RevML-Web pages generator

=head1 SYNOPSIS


    $self->use_class('generator');
    $self->generator->gen_counts;
    $self->generator->gen_graphs;
    $self->generator->gen_htmls;

=head1 URL NAMING SCHEME


    /index.html
    /project/<project-keyname>/index.html
    /project/<project-keyname>/<graph-kind>.jpeg
    /project/<project-keyname>/<author>.html
    /project/<project-keyname>/<author>.jpeg


=head1 DESCRIPTION

=cut

use strict;
use Imager::Graph::Pie;
use File::Spec;
use RevML::Web '-Base';

our $VERSION = '0.01';

sub init {
    $self->use_class('config');
    $self->use_class('main');
    $self->use_class('template');
    $self->use_class('database');
    $self->use_class('statistics');
}

### }}}

### {{{ APIs

sub gen_statistics {
    my $prjname = shift;
    my $prj = $self->database->project->search(name=>$prjname)->first;
    for($prj->revml) {
	$self->gen_counts_revml($_);
    }
    $self->statistics->merge_count($prj);
}

=head1 gen_counts($project_name)

Generate the counts for a single project

=cut

sub gen_counts {
    my $prjname = shift;
    $self->gen_counts_all unless($prjname);
    if(ref($prjname)) {
	my @revmls = $prjname->revml;
	warn "Generate counts for " . $prjname->name . "\n";
	$self->gen_counts_revml($_) for @revmls;
    } else {
	my $prjid   = $self->database->search(project=>$prjname);
	return unless $prjid;
	warn "Generate counts for $prjname\n";
	my @revmls = $prjid->revml;
	$self->gen_counts_revml($_) for @revmls;
    }
}


=head1 gen_counts_all

Generate the counts for all projects

=cut

sub gen_counts_all {
    my @prjs = $self->database->projects;
    warn "Projects: @prjs\n";
    $self->gen_counts($_) for(@prjs);
}


=head1 gen_counts_revml($revml_id)

Generate the counts for a single revml

=cut

sub gen_counts_revml {
    my $revml = shift;
    if ($revml->counted && !$self->main->force) {
	warn $revml->path . " already counted. Skipped\n"
	    unless $self->main->quiet;
	return ;
    }
    $self->statistics->count($revml);
    $self->database->set('revml',$revml,'counted');
}

=head2 gen_graphs ([$prj])

Generate graph files for Project $prj, if not given,
generate all of them.

=cut

sub gen_graphs {
    my $prjname = shift;
#    $self->gen_graphs_all unless($prjname);
    if(ref($prjname)) {
	my @revmls = $prjname->revml;
	warn "Generate graphs for " . $prjname->name . ", "  .
	    scalar(@revmls)
	    . " revml filess\n";
	$self->gen_graphs_revml($_) for @revmls;
    } else {
	my $prj = $self->database->project->search(name=>$prjname)->first;
	unless ($prj) {
	    warn "Warn: No project named [$prjname]\n";
	    return ;
	}
	warn "Generate graphs for $prjname($prj)\n";
	my @revmls = $prj->revml;
	$self->gen_graphs_revml($_) for @revmls;
    }
}

sub gen_graphs_project {
    my $prjname = shift;
    my $prj = $self->database->project->search(name=>$prjname)->first;
    $self->graph_project($prj);
    $self->graph_authors_project($prj);
    $self->graph_subdirs_project($prj);
}


=head2 gen_graphs_revml ([$revml])

Generate graph files for Project $revml, if not given,
generate all of them.

=cut

sub gen_graphs_revml {
    my $revml = shift;
    if ($revml) {
	if ($revml->graphed && !$self->main->force) {
	    warn $revml->path . " already graphed. Skipped\n"
		unless $self->main->quiet;
	    return ;
	}
	warn "Makin graphs of Revml [$revml]" . $revml->path . "\n";
	$self->graph($revml);
	$self->database->set('revml',$revml,'graphed');
    }
}

=head2 gen_htmls ([$revml])

Generate html pages for Project $revml, if not given,
generate all of them.

=cut

sub gen_htmls {
    unless (-e $self->template->extract_to) {
        warn "Extracting template files...\n";
        $self->template->extract_files;
    }
    mkdir($self->config->html_directory)
	unless -d $self->config->html_directory;
    warn "Extracting and Copying CSS...\n";
    $self->save('style.css',
		File::Spec->catfile($self->config->html_directory,
				    'style.css')
	       );

    warn "Generating html pages...\n";
    $self->gen_html_recursive(@_);
    warn "Generating index page\n";
    $self->gen_html_index;
    warn "All done\n";
}

sub gen_html_index {
    my @allproj = $self->database->project->retrieve_all;
    my @arr =
	sort {$b->{revs} <=> $a->{revs} }
	map { { id => $_ , name => $_->name, revs => $_->count_revision  } }
	@allproj;

    my @x; my @y;
    for(@arr) {
	push @x, $_->{name};
	push @y, $_->{revs};
    }

    $self->save_graph(
	File::Spec->catfile($self->config->html_directory,'index.jpeg'),
	\@x,\@y);

    $self->save('index.html',
		File::Spec->catfile($self->config->html_directory,'index.html'),
		title => "RevML::Web::Index",
		graph => "index.jpeg",
		allproj => \@arr);
}

sub gen_html_recursive {
    my $project = shift;
    if ($project) {
	my $prj = $self->database->project->search(name=>$project)->first;
	$self->html($prj);
    }else {
	my @prj = $self->database->project->retrieve_all;
	for (@prj) {
	    $self->html($_);
	}
    }
}


### }}}

### {{{ Helper functions

=head2 save($template, $filename, %template_vars)

Save the processed $template output with %template_vars to
$filename.

=cut

sub save {
    my ($template,$filename,@vars) = @_;
    my $output = $self->template->process($template,@vars);
    $output > io($filename);
}

### }}}

### {{{ Generate HTML Files, Internal method called by gen_*

sub html {
    my ($prj) = @_;
    for my $kind qw(subdirs authors projects) {
	my $method = "html_$kind";
	$self->$method($prj) if($self->can($method));
    }
}

sub html_projects {
    my ($prj) = @_;
    my @tld = $self->statistics->top_level_directory($prj);
    my @authors = $self->statistics->authors($prj);
    my @directories = $self->statistics->directories($prj);

    my $dirname = $self->pmkdir($self->config->html_directory,'project',$prj);
    my $filename = File::Spec->catfile($dirname,'index.html');
    my $dirs = $self->statistics->subdir_counts($prj);
    foreach(@tld) {
	my $subdname = $_->{event};
	if(defined($dirs->{$subdname})) {
	    my $dname = $subdname; $dname =~ s|/|-|g;
	    my $filename = "subdir-$dname.html";
	    $_->{link} = $filename;
	}
    }

    $self->save('projects.html', $filename,
		title => "Project: ". $prj->name,
		revml => { id => $prj, name => $prj->name },
		tld => \@tld,
		authors => \@authors,
		directories => \@directories,
	       );
}

sub html_subdirs {
    my ($prj) = @_;
    warn "Generating subdir pages\n";
    # subdir keys: directory->{ event => subdir , counts => counts }
    my $dirs = $self->statistics->subdir_counts($prj);
    my $dirname = $self->pmkdir($self->config->html_directory,'project',$prj);
    for(keys %$dirs) {
	my $dname = $_;
	my $parentdir = $self->parent_dir($dname);
	$dname =~ s|/|-|g;
	$parentdir =~ s|/|-|g;
	my $filename = File::Spec->catfile($dirname,"subdir-$dname.html");
	my $counts = $dirs->{$_};
	foreach my $subd (@{$dirs->{$_}}) {
	    my $subdname = $subd->{event};
	    if(defined($dirs->{$subdname})) {
		my $dname = $subdname; $dname =~ s|/|-|g;
		my $filename = "subdir-$dname.html";
		$subd->{link} = $filename;
	    }
	}
	$self->save('subdir.html',$filename,
		    revml => { id => $prj,
			       name => $prj->name },
		    counts => $counts,
		    parent => "subdir-$parentdir.html",
		    graph => "subdir-$dname.jpeg",
		   );
	warn $prj->name . " subdir-$dname.html saved\n";
    }
}


sub parent_dir {
    my @d = split'/',shift;
    pop @d;
    join('/',@d) || '/';
}

sub pmkdir {
    my $d = shift;
    my @dirs = @_;
    for(@dirs) {
	$d = File::Spec->catfile($d,$_);
	unless(-d $d) {
	    mkdir($d);
	    warn "Dir [$d] maked\n";
	}
    }
    return $d;
}

sub html_authors {
    my ($prj) = @_;
    my @count = $self->statistics->authors($prj);

    my $dirname = $self->pmkdir($self->config->html_directory,'project',$prj);
    my $filename = File::Spec->catfile($dirname,'authors.html');

    $self->save('authors.html',$filename,
		title => 'Authors',
		project => { id => $prj, name => $prj->name },
		author_counts => \@count);
    foreach(@count) {
	warn "Generating author view for $_->{author}\n";
	$self->html_author($prj,$_->{author});
    }
}


sub html_author {
    my ($prj,$author) = @_;
    return unless($author);
    my $dirname = $self->pmkdir($self->config->html_directory,
				'project',$prj);
    my $filename = File::Spec->catfile($dirname,"${author}.html");

    my @counts = $self->statistics->author($prj,$author);

    $self->save('author.html',$filename,
		title => "Author: $author",
		author => $author,
		revml => { id => $prj, name => $prj->name },
		counts => \@counts);
}

### }}}

### {{{ Generate graphs

sub graph {
    my ($revml) = @_;
    $self->graph_subdirs($revml);
    for my $kind qw(author top_level_directory second_level_directory) {
        my @x; my @y;
        my @counts = $self->database->counts($revml,$kind);
        $self->make_graph($revml,$kind,@counts);
    }

    my @authors = $self->statistics->authors($revml);
    for(@authors) {
	next unless($_->{author});
	my @counts = $self->database->counts($revml,$_->{author});
	$self->make_graph($revml,$_->{author},@counts);
    }
}

sub graph_project {
    my $prj = shift;
    for my $kind qw(author top_level_directory second_level_directory) {
        my @x; my @y;
        my @counts = $self->database->statistic->search
	    (prjid => $prj, kind => 'author');
        $self->make_graph($prj,$kind,@counts);
    }
}

sub graph_authors_project {
    my $prj = shift;
    my @authors = $self->statistics->authors($prj);
    for(@authors) {
	my @counts = $self->statistics->author($prj,$_->{author});
	$self->make_graph($prj,$_->{author},@counts);
    }
}

sub graph_subdirs {
    my ($revml) = @_;
    warn "Generating subdir graphs\n";
    my $dirs = $self->statistics->subdir_counts($revml);
    my $dirname = $self->pmkdir($self->config->html_directory,'project',$revml);
    for(keys %$dirs) {
	my $dname = $_; $dname =~ s|/|-|g;
	$self->make_graph($revml,"subdir-$dname",@{$dirs->{$_}});
	warn "$revml subdir-$dname graph saved\n";
    }
}


sub graph_subdirs_project {
    my ($prj) = @_;
    warn "Generating subdir graphs\n";
    my $dirs = $self->statistics->subdir($prj);
    my $dirname = $self->pmkdir($self->config->html_directory,'project',$prj);
    for(keys %$dirs) {
	my $dname = $_; $dname =~ s|/|-|g;
	$self->make_graph($prj,"subdir-$dname",@{$dirs->{$_}});
	warn $prj->name . " subdir-$dname graph saved\n";
    }
}

sub make_graph {
    my ($prj,$kind,@counts) = @_;
    my (@x,@y);
    for(@counts) {
	if(defined( $_->{event})) {
	    push @x, $_->{event};
	    push @y, $_->{counts};
	} else {
	    push @x, $_->event;
	    push @y, $_->counts;
	}
    }
    print STDERR "[$prj] $kind column collected\n"
	unless $self->main->quiet;

    my $dirname = $self->pmkdir($self->config->html_directory,'project',$prj);
    my $filename = File::Spec->catfile($dirname,$kind);

    $self->save_graph($filename,\@x,\@y);
}


sub save_graph {
    my ($filename,$x,$y) = @_;
    my $chart = Imager::Graph::Pie->new;
    my $fontfile = $self->config->graph_font;
    my $font = Imager::Font->new(file=>$fontfile, aa=>1)
	or die "Cannot create font object: ",Imager->errstr,"\n";
    my @nx;
    for my $k (@$x) {
        $k =~ s{.*(/.+)$}{$1}g;
        push @nx,$k;
    }
    my $img = $chart->draw(labels => \@nx, data => $y,
	    style=>'fount_lin',
	    features=>[qw/labels labelspc pieblur outline dropshadow/],
	    width=>480, height=>480,
	    font => $font);
    $img->write(file=>"${filename}.jpeg",type=>'jpeg');
    warn "${filename}.jpeg saved\n" unless $self->main->quiet;
}

### }}}

1;

=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut
