package RevML::Web::Command;

### {{{ Start

=head1 NAME

RevML::Web::Command - command class for RevML::Web

=head1 SYNOPSIS

    revml-web-cmd [option] sub-command [sub-command arguments]

=head1 OPTIONS

    --verbose : display verbose output.
    --force   : violently do everything.

=head1 SUB-COMMANDS

=over 4

=item list

Display all revmls currently imported. Information include internal
id, origianl path, and total number of revisions.

=item reset

Reset internal dirty flags. Doing this would make
the successive 'generate' command to generate things again.

=item fetch-sf

Fetch SourceForge nightly cvsroot tarball under current directory.

=item generate [count project_name]

=item generate [graph project_name]

=item generate [html project_name]

Generate revision counts ,statistics graphs or html pages.
If nothing is given, generate all things.

=item generate counts / graphs / htmls

Generate all counts , graphs or htmls.

=item import project_name revml_file, [other_revml_files, ...]

Import target revml file to mysql. You have to give full file path.
Currently only mysql is supported.

=back

=cut

use strict;
use DBI;
use XML::Twig;
use YAML;
use IO::All;

use RevML::Web '-Base';

our $VERSION = '0.01';

sub init {
    $self->use_class('config');
    $self->use_class('main');
    $self->use_class('database');
    $self->use_class('generator');
}

### }}}

### {{{ Process command-line input

sub boolean_arguments { qw(--verbose --quiet --force list grep-emails generate graphs counts htmls reset help) }
sub paired_arguments { qw(fetch-sf show import show-counts count graph html statistics help) }

sub process {
    my ($args,@others) = $self->parse_arguments(@_);

    for ( qw/quiet force verbose/ ) {
	if ($args->{"--$_"}) {
	    $self->main->$_(1);
	    undef $args->{"--$_"};
	}
    }

    return $self->reset_state if($args->{'reset'});
    return $self->list if($args->{'list'});
    return $self->show($args->{'show'}) if($args->{'show'});

    return $self->generate($args) if($args->{generate});
    return $self->tomysql($args->{'import'},@others) if $args->{'import'};
    return $self->fetch($args->{'fetch-sf'}) if $args->{'fetch-sf'};

    return $self->grep_comment_email if $args->{'grep-emails'};
    return $self->show_counts($args->{'show-counts'}) if ($args->{'show-counts'});
    return $self->usage;
}

sub usage {
    use Pod::Perldoc;
    exec("perldoc",(caller)[0]);
}

sub list {
    my @prjs = $self->database->projects;
    for(@prjs) {
	print $_->prjid. ': '.  $_->name . "\n";
	my @revmls = $_->revml;
	for(@revmls) {
	    print '  ' . $_->revml . ': ' . $_->path . "\n";
	}
    }
}

sub show {
    my $prjname = shift;
    my $prj = $self->database->project->search(name=>$prjname)->first;
    my @st = $prj->statistic;
    for(@st) {
	print $_->event . ': '.  $_->counts . "\n";
    }
}


sub generate {
    my $args = shift;
    if($args->{'count'}) {
	$self->gen_counts($args->{'count'});
    } elsif($args->{'statistics'}) {
	$self->gen_statistics($args->{'statistics'});
    } elsif($args->{'graph'}) {
	$self->gen_graphs($args->{'graph'});
    } elsif($args->{'html'}) {
	$self->gen_htmls($args->{'html'});
    } else {
	my @thing = qw/counts graphs htmls/;

	for(@thing) {
	    my $m = "gen_$_";
	    return $self->$m if($args->{$_});
	}
	warn "No specific parameter given, generate all things\n"
	    unless $self->main->quiet;
	$self->gen_all ;
    }
}

### }}}

### {{{ Do the real thing

sub reset_state {
    return $self->database->reset_dirty_flags;
}

sub fetch {
    my $project = shift;
    my $url = "http://cvs.sourceforge.net/cvstarballs/${project}-cvsroot.tar.bz2";
    my $method = $self->config->fetch_command;
    system("$method $url");
}

sub tomysql {
    my $project = shift;
    my @files = @_;
    my $prjid = $self->database->project->find_or_create(name=>$project);
    for(@files) {
	$self->revml_tomysql($prjid,$_);
    }
}

sub revml_tomysql {
    my ($prjid,$file) = @_;
    my $revml = $self->database->revml->find_or_create(path=>$file, prjid=>$prjid);
    warn "$file add, id: $revml\n";
    my $length;
    my $mkidx = sub {
        my $file = shift;
        my $twig = XML::Twig->new(
                twig_handlers => {
                rev => sub {
                my ($t,$rev) = @_;
                my $id = $self->database->add('revision',{
                    rev => $rev->att('id'),
                    revml => $revml,
                    author => $rev->first_child_text('user_id'),
                    comment => $rev->first_child_text('comment'),
                    target_path => $rev->first_child_text('name')
                    });
                $t->purge;
# eyes message sugar.
                print STDERR " " x $length . "\r";
                print STDERR "rev: $id\r";
                $length = length("rev: $id");
                }});
        my $root = $twig->parsefile($file);
    };
    warn "importing $file\n";
    $mkidx->($file);
    warn "\n";
    return $revml;
}

sub grep_comment_email {
    my $project = shift;
    my %emails = $self->database->grep_email_in_comment($project);
    print YAML::Dump(\%emails);
}

sub gen_statistics {
    $self->generator->gen_statistics(@_);
}

sub gen_counts {
    $self->generator->gen_counts(@_);
}

sub gen_graphs {
#    $self->generator->gen_graphs(@_);
    $self->generator->gen_graphs_project(@_);
}

sub gen_htmls {
    $self->generator->gen_htmls(@_);
}

sub gen_all {
    $self->gen_counts;
    $self->gen_graphs;
    $self->gen_htmls;
}

# }}}

1;

__END__

=head1 SEE ALSO

L<Spiffy> , L<Spoon> , L<Spork>

=head1 COPYRIGHT

Copyright 2003 by Kang-min Liu E<lt>gugod@gugod.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
