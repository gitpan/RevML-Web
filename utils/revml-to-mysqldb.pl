#!/usr/bin/env perl
# Author: gugod@ib.gugod.org
# Purpose:

use strict;
use XML::Twig;
use YAML;
use DBI;
use DBIx::SearchBuilder::Handle;

my $Project = $ARGV[0];
init(@ARGV);
mkidx(@ARGV);

my $Revml = $ARGV[0];

my $Handle;
sub init {
#    $Handle = DBIx::SearchBuilder::Handle->new();
#    $Handle->Connect( Driver => 'sqlite', Database => '/tmp/revml.db' );
    my $dbname = $_[0] . ".sqlite.db";
    $Handle = DBI->connect("dbi:mysql:database=revmlweb","root");
#    $Handle->do('CREATE TABLE rev (id varchar(255),filename varchar(255),author varchar(255),comment text)');
    return $Handle;
}

my $i = 0;
sub insert {
    my ($id,$author,$filename,$comment) = @_[1,3,5,7];
    my $qcomment = $Handle->quote($comment);
    my $sql = "INSERT INTO rev VALUES ('$Project','$id','$filename','$author',$qcomment)";
    $Handle->do($sql);
    print $i++,": $id\n";
}

# DB: id -> user_id,filename
sub mkidx {
    my $file = shift;
    my $twig = XML::Twig->new
	(twig_handlers =>
	   {
	    rev => sub {
		my ($t,$rev) = @_;
                insert(id => $rev->att('id'),
                       author => $rev->first_child_text('user_id'),
                       filename => $rev->first_child_text('name'),
                       comment => $rev->first_child_text('comment'),
                   );
		$t->purge;
	    }
	   },
	 );
    my $root = $twig->parsefile($file);
}

