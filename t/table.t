#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

# Disable epoll, kqueue and IPv6
BEGIN { $ENV{MOJO_POLL} = $ENV{MOJO_NO_IPV6} = 1 }

use Mojo::IOLoop;
use Test::More;
use Test::Mojo;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 3;

use Mojolicious::Lite;
plugin 'tag_helpers_extra';

app->log->level('error'); #silence

{
  package Stuff;
  our $count = 10;
  sub stuff {
    return undef unless $count--;
    return ([$count, qw/X Y Z/]);
  } ;
  sub new {
    my $self = [];
    return bless $self, 'Stuff';
  }
}

sub whole {
  return [[ 1, {class=>'first'}, 2, 3], [4, 5, 6], { class=>'last'}];
}

my $stuff = new Stuff;


# GET /
get '/' => sub { shift->render(template=>'index', stuff=>$stuff); } => 'index';

# Test
my $client = app->client;
my $t      = Test::Mojo->new;

# GET /
$t->get_ok('/')->status_is(200)->content_is(<<EOF);
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body><table>
<tr class="rowtitle">
<td>Name</td><td>A</td><td>B</td><td>C</td>
</tr>
<tr>
<td class="celltitle">John</td><td>3</td><td>5</td><td>6</td>
</tr>
<tr>
<td>Mary</td><td>1</td><td>3</td><td>8</td>
</tr>
</table>
<table>
<caption>test</caption>
<tr class="rowtitle">
<td>Name</td><td>A</td><td>B</td><td>C</td>
</tr>
<tr>
<td class="celltitle">John</td><td>3</td><td>5</td><td>6</td>
</tr>
<tr>
<td>Mary</td><td>1</td><td colspan="3">N/A</td>
</tr>
</table>
<table>
<tr class="rowtitle">
<td>Name</td><td>A</td><td>B</td><td>C</td>
</tr>
<tr>
<td class="celltitle">John</td><td>3</td><td>5</td><td>6</td>
</tr>
<tr>
<td>Mary</td><td>1</td><td>3</td><td>8</td>
</tr>
</table>
<table class="test">
<caption>Test. A <i>double</i> test.</caption>
<tr class="rowtitle">
<th>Name</th><th>A</th><th>B</th><th>C</th>
</tr>
<tr>
<th class="celltitle">John</th><td>3</td><td>5</td><td>6</td>
</tr>
<tr>
<th>Mary</th><td>1</td><td>3</td><td>8</td>
</tr>
</table>
<table>
<head>
<th>Name</th><th>A</th><th>B</th><th>C</th>
</head>
<foot>
<th>name</th><th>a</th><th>b</th><th>c</th>
</foot>
<tr>
<td>John</td><td>3</td><td>5</td><td>6</td>
</tr>
<tr>
<td>Mary</td><td>1</td><td>3</td><td>8</td>
</tr>
</table>
<table class="incremental">
<caption>Incremental.</caption>
<tr>
<td>9</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>8</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>7</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>6</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>5</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>4</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>3</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>2</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>1</td><td>X</td><td>Y</td><td>Z</td>
</tr>
<tr>
<td>0</td><td>X</td><td>Y</td><td>Z</td>
</tr>
</table>
<table class="failed-incremental">
<caption>Incremental.</caption>
<tr class="rowtitle">
<td>Name</td><td>A</td><td>B</td><td>C</td>
</tr>
<tr>
<td class="celltitle">John</td><td>3</td><td>5</td><td>6</td>
</tr>
<tr>
<td>Mary</td><td>1</td><td>3</td><td>8</td>
</tr>
</table>
<table class="whole">
<caption>Whole.</caption>
<tr>
<td class="first">1</td><td>2</td><td>3</td>
</tr>
<tr class="last">
<td>4</td><td>5</td><td>6</td>
</tr>
</table>
<table class="direct">
<caption>Direct.</caption>
<tr>
<td class="first">1</td><td>2</td><td>3</td>
</tr>
<tr class="last">
<td>4</td><td>5</td><td>6</td>
</tr>
</table>
</body>
</html>
EOF

__DATA__
@@ index.html.ep
% layout 'main';
<%= table [ [ qw/Name A B C/ ] => { class=>'rowtitle' }, [ 'John' => { class=>'celltitle' }, 3, 5, 6 ], [ 'Mary', 1, 3, 8 ] ] %>
<%= table [ [ qw/Name A B C/ ] => { class=>'rowtitle' }, [ 'John' => { class=>'celltitle' }, 3, 5, 6 ], [ 'Mary', 1, 'N/A' => {colspan=>3} ] ], caption => 'test' %>
<%= table [ [ qw/Name A B C/ ] => { class=>'rowtitle' }, [ 'John' => { class=>'celltitle' }, 3, 5, 6 ], [ 'Mary', 1, 3, 8 ] ] => begin %>A <i>nice</i> test.<% end %>
<%= table [ [ qw/Name A B C/ ] => { class=>'rowtitle' }, [ 'John' => { class=>'celltitle' }, 3, 5, 6 ], [ 'Mary', 1, 3, 8 ] ], class => 'test', rh => 1, ch => 1, caption => 'Test.' => begin %>A <i>double</i> test.<% end %>
<%= table [ [ 'John', 3, 5, 6 ], [ 'Mary', 1, 3, 8 ] ], head => [ qw/Name A B C/ ], foot => [ qw/name a b c/ ] %>
<%= table class => 'incremental', sub=> sub {$stuff->stuff} => begin %>Incremental.<% end %>
<%= table [ [ qw/Name A B C/ ] => { class=>'rowtitle' }, [ 'John' => { class=>'celltitle' }, 3, 5, 6 ], [ 'Mary', 1, 3, 8 ] ], class => 'failed-incremental', sub=> sub {$stuff->stuff} => begin %>Incremental.<% end %>
<%= table class => 'whole', sub=> sub { ::whole() } => begin %>Whole.<% end %>
<%= table ::whole(), class => 'direct', => begin %>Direct.<% end %>

@@ layouts/main.html.ep
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body><%== content %></body>
</html>
