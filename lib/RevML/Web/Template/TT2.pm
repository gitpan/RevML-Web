package RevML::Web::Template::TT2;
use strict;
use warnings;
use Spoon::Template::TT2 '-base';
use Spoon::Installer '-base';

sub plugins { {} }

sub extract_to {
    my $self = shift;
    $self->hub->config->template_directory;
}

sub include_path {
    my $self = shift;
    $self->hub->config->template_path || 
      [ $self->hub->config->template_directory ];
}

sub init {
    my $self = shift;
    $self->use_class('config');
}

sub process {
    my $self = shift;
    my $template = shift;
    my %vars = @_;

    $vars{siteroot} = $self->config->siteroot;

    $self->SUPER::process($template,%vars);
}


1;

__DATA__
__style.css__
h1 {
    font-size: 16px;
    text-shadow: pink 2px 2px 1px;
    text-decoration: underline;
}

table {
    border: 1px solid #999999;
    margin-right: 36px;
}

table tr td {
    border: 1px solid #333;
}


.left {
float: left;
max-width: 500px;
width: 30%;
}

.right {
float: left;
}

img {
border: 0px;
}

.seperator {
   clear: both;
   min-width: 90%;
   align: center;
   margin-top: 2em;
   margin-down: 2em;
}
__header.html__
<html>
<head>
  <title>[% title %]</title>
  <link rel="stylesheet" type="text/css" href="[% siteroot %]/style.css" />
</head>
<body>

__footer.html__
<div class="seperator"></div>

[<a href="[% siteroot %]/index.html">Index</a>]
[<a href="[% siteroot %]/project/[% revml.id %]/index.html">[% revml.name %]</a>]
</body>
</html>
__authors.html__
[% INCLUDE header.html %]
<h1>Authors of [% project.name %]</h1>

<div class="right">
<h2>Author Statistics</h2>
<table>
[% FOREACH a = author_counts %]
  <tr>
    <td><a href="[% a.author || 'UNKNOWN' %].html">[% a.author || 'UNKNOWN' %]</a></td>
    <td>[% a.counts %]</td>
  </tr>
[% END %]
</table>
</div>

<div class="left">
<a href="author.jpeg"><img src="author.jpeg"/></a>
</div>

[% INCLUDE footer.html %]
__projects.html__
[% INCLUDE header.html %]
<h1>[% title %]</h1>

<h2>Author</h2>
<div class="right">
<table>
  <tr><td>Account</td> <td>Revision Counts</td></tr>
  [% FOREACH c = authors %]
  [% SET author = c.author || 'UNKNOWN' %]
  <tr>
    [% IF author == 'UNKNOWN' %]
    <td>[% author %]</td>
    [% ELSE %]
    <td><a href="[% author %].html">[% author %]</a></td>
    [% END %]
    <td>[% c.counts %]</td>
  </tr>
  [% END %]
</table>
</div>

<div class="left">
<a href="author.jpeg"><img src="author.jpeg"/></a>
</div>

<div class="seperator"></div>

<div class="right">
<a href="subdir--.html">File system view</a>
</div>

[% INCLUDE footer.html %]
__author.html__
[% INCLUDE header.html %]
<!-- begin author view -->
<h1>[% title %]</h1>


<div class="right">
<table>
  <tr><td>Directory</td><td>Revision Counts</td></tr>
  [% FOREACH p = counts %]
  <tr>
    <td>[% p.event %]</a></td>
    <td>[% p.counts %]</td>
  </tr>
  [% END %]
</table>
</div>

<div class="left">
<a href="[% author %].jpeg"><img src="[% author %].jpeg"/></a>
</div>


<!-- end author view -->
[% INCLUDE footer.html %]
__index.html__
[% INCLUDE header.html %]
<h1>[% title %]</h1>

<div class="right">
<table>
  <tr><td>RevML File</td><td>Number of revisions</td></tr>
  [% FOREACH p = allproj %]
  <tr>
    <td><a href="project/[% p.id %]/index.html">[% p.name %]</a></td>
    <td>[% p.revs %]</td>
  </tr>
  [% END %]
</table>
</div>


<div class="left">
<a href="[% graph %]"><img src="[% graph %]"/></a>
</div>


[% INCLUDE footer.html %]
__subdir.html__
[% SET title = "$revml.name directory view" %]
[% INCLUDE header.html %]
<!-- begin subdir view -->
<h1>[% title %]</h1>

<div class="right">
<table>
  <tr><td>Directory</td><td>Revision Counts</td></tr>
  <tr><td><a href="[% parent %]">..</a></td><td> </td></tr>
  [% FOREACH p = counts %]
  [% SET dname = p.event %]
  <tr>
  [% IF p.link %]
    <td><a href="[% p.link %]">[% p.event %]</a></td>
  [% ELSE %]
    <td>[% p.event %]</td>
  [% END %]
    <td>[% p.counts %]</td>
  </tr>
  [% END %]
</table>
</div>

<div class="left">
<a href="[% graph %]"><img src="[% graph %]" /></a>
</div>

[% INCLUDE footer.html %]
