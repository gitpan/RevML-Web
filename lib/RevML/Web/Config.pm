package RevML::Web::Config;
use strict;
use Spoon::Config '-base';
use Spoon::Installer '-base';

const class_id => 'config';

sub default_configs {
    my $self = shift;
    my @configs;
    push @configs, "$ENV{HOME}/.revml-web/config.yaml"
      if defined $ENV{HOME} and -f "$ENV{HOME}/.revml-web/config.yaml";
    push @configs, "config.yaml"
      if -f "config.yaml";
    return @configs;
}

sub default_config {
    return {
            main_class => 'RevML::Web',
            config_class => 'RevML::Web::Config',
            hub_class => 'RevML::Web::Hub',
            command_class => 'RevML::Web::Command',
            statistics_class => 'RevML::Web::Statistics',
            template_class => 'RevML::Web::Template::TT2',
            database_class => 'RevML::Web::DB',
	    generator_class => 'RevML::Web::Generator',
	    template_directory => 'template',
	    template_path => [ 'template' ],
	    html_directory => 'html',
            db_dsn => 'DBI:mysql:database=revmlweb',
            db_user => 'root',
            db_password => '',
	    graph_font => '/usr/X11R6/lib/X11/fonts/TTF/luximr.ttf',
	    graph_fontsize => 12,
            siteroot => '/revmlweb',
            verbose => 0,
            fetch_command => 'wget',
        };
}

1;
