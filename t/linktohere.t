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
plan tests => 9;

use Mojolicious::Lite;
plugin 'tag_helpers_extra';

app->log->level('error'); #silence

# GET /
get '/' => 'index';

# Test
my $client = app->client;
my $t      = Test::Mojo->new;

# GET / default
$t->get_ok('/?page=3')->status_is(200)->content_is(<<EOF);
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body>
<a href="/?page=3">link</a>
<a href="/?page=3">Reload</a>
<a class="link" href="/?page=3">Reload</a>
<a href="/?page=4">Next</a>
<a href="/?page=4&colour=blue&colour=red">More colours</a>
</body>
</html>
EOF

# GET / query
$t->get_ok('/?page=3&colour=yellow')->status_is(200)->content_is(<<EOF);
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body>
<a href="/?page=3&colour=yellow">link</a>
<a href="/?page=3&colour=yellow">Reload</a>
<a class="link" href="/?page=3&colour=yellow">Reload</a>
<a href="/?colour=yellow&page=4">Next</a>
<a href="/?colour=yellow&page=4&colour=blue&colour=red">More colours</a>
</body>
</html>
EOF

# GET / query with multiple values
$t->get_ok('/?page=3&page=5')->status_is(200)->content_is(<<EOF);
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body>
<a href="/?page=3&page=5">link</a>
<a href="/?page=3&page=5">Reload</a>
<a class="link" href="/?page=3&page=5">Reload</a>
<a href="/?page=4">Next</a>
<a href="/?page=4&colour=blue&colour=red">More colours</a>
</body>
</html>
EOF


__DATA__
@@ index.html.ep
% layout 'main';
<% my $newpage = $self->param('page'); $newpage++; %>
<%= link_to_here %>
<%= link_to_here begin %>Reload<% end %>
<%= link_to_here class => 'link' => begin %>Reload<% end %>
<%= link_to_here { page => $newpage } => begin %>Next<% end %>
<%= link_to_here [ colour => 'blue', colour => 'red'] => begin %>More colours<% end %>

@@ layouts/main.html.ep
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body><%== content %></body>
</html>
