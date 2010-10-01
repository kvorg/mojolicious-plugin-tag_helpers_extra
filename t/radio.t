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
$t->get_ok('/')->status_is(200)->content_is(<<EOF);
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body><form action="/" method="get">
  <p>
    <input checked="checked" name="test" type="radio" value="default">Default</input>
    <input name="test" type="radio" value="alternate">Alternate</input>
    <input name="test" type="radio" value="thelast" />
    <input type="submit" value="Test" />
  </p>
</form>
</body>
</html>
EOF
# GET / query
$t->get_ok('/?test=alternate')->status_is(200)->content_is(<<EOF);
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body><form action="/" method="get">
  <p>
    <input name="test" type="radio" value="default">Default</input>
    <input checked="checked" name="test" type="radio" value="alternate">Alternate</input>
    <input name="test" type="radio" value="thelast" />
    <input type="submit" value="Test" />
  </p>
</form>
</body>
</html>
EOF

# GET / query with too many values
$t->get_ok('/?test=alternate&test=thelast')->status_is(200)->content_is(<<EOF);
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body><form action="/" method="get">
  <p>
    <input name="test" type="radio" value="default">Default</input>
    <input checked="checked" name="test" type="radio" value="alternate">Alternate</input>
    <input name="test" type="radio" value="thelast" />
    <input type="submit" value="Test" />
  </p>
</form>
</body>
</html>
EOF


__DATA__
@@ index.html.ep
% layout 'main';
<%= form_for '/' => (method => 'get') => begin %>
  <%= tag 'p' => begin %>
    <%= radio_button_x 'test', 'default', checked => 'checked' => begin %>Default<% end %>
    <%= radio_button_x 'test', 'alternate' => begin %>Alternate<% end %>
    <%= radio_button_x 'test', 'thelast' %>
    <%= submit_button 'Test' %>
  <% end %>
<% end %>

@@ layouts/main.html.ep
<!doctype html><html>
    <head>
       <title>Test</title>
    </head>
    <body><%== content %></body>
</html>
