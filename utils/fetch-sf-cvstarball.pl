#!/usr/bin/perl -w
# Author: gugod@gugod.org
# Purpose: Fetch cvstarball on sourceforge


use strict;

my $method = 'wget';

sub fetch_sf_cvstarball {
    my $project = shift;
    my $url = "http://cvs.sourceforge.net/cvstarballs/${project}-cvsroot.tar.bz2";
    system("wget $url");
}



