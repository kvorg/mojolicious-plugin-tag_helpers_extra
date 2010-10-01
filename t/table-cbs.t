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
  our $count = 20;
  our $width = 10;
  sub stuff {
    return undef unless $count--;
    return ([map {$count - 15 + $_;} (1 .. $width)]);
  } ;
  sub new {
    my $self = [];
    return bless $self, 'Stuff';
  }
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
       <style type="text/css">
	  table   { caption-side: bottom; border-collapse: collapse; border-widht: 0pt; }
          td      { text-align: right; padding-left: .5em; padding-right: .5em;}
          td.red  { color: red; } 
          tr.odd  { background-color: Lavender; }
       </style>
    </head>
    <body><table class="programmatic">
<caption>Programmatic.</caption>
<tr class="odd">
<td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td><td>12</td><td>13</td><td>14</td>
</tr>
<tr>
<td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td><td>12</td><td>13</td>
</tr>
<tr class="odd">
<td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td><td>12</td>
</tr>
<tr>
<td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td>
</tr>
<tr class="odd">
<td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td>
</tr>
<tr>
<td>0</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td>
</tr>
<tr class="odd">
<td class="red">-1</td><td>0</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td>
</tr>
<tr>
<td class="red">-2</td><td class="red">-1</td><td>0</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td>
</tr>
<tr class="odd">
<td class="red">-3</td><td class="red">-2</td><td class="red">-1</td><td>0</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td>
</tr>
<tr>
<td class="red">-4</td><td class="red">-3</td><td class="red">-2</td><td class="red">-1</td><td>0</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td>
</tr>
<tr class="odd">
<td class="red">-5</td><td class="red">-4</td><td class="red">-3</td><td class="red">-2</td><td class="red">-1</td><td>0</td><td>1</td><td>2</td><td>3</td><td>4</td>
</tr>
<tr>
<td class="red">-6</td><td class="red">-5</td><td class="red">-4</td><td class="red">-3</td><td class="red">-2</td><td class="red">-1</td><td>0</td><td>1</td><td>2</td><td>3</td>
</tr>
<tr class="odd">
<td class="red">-7</td><td class="red">-6</td><td class="red">-5</td><td class="red">-4</td><td class="red">-3</td><td class="red">-2</td><td class="red">-1</td><td>0</td><td>1</td><td>2</td>
</tr>
<tr>
<td class="red">-8</td><td class="red">-7</td><td class="red">-6</td><td class="red">-5</td><td class="red">-4</td><td class="red">-3</td><td class="red">-2</td><td class="red">-1</td><td>0</td><td>1</td>
</tr>
<tr class="odd">
<td class="red">-9</td><td class="red">-8</td><td class="red">-7</td><td class="red">-6</td><td class="red">-5</td><td class="red">-4</td><td class="red">-3</td><td class="red">-2</td><td class="red">-1</td><td>0</td>
</tr>
<tr>
<td class="red">-10</td><td class="red">-9</td><td class="red">-8</td><td class="red">-7</td><td class="red">-6</td><td class="red">-5</td><td class="red">-4</td><td class="red">-3</td><td class="red">-2</td><td class="red">-1</td>
</tr>
<tr class="odd">
<td class="red">-11</td><td class="red">-10</td><td class="red">-9</td><td class="red">-8</td><td class="red">-7</td><td class="red">-6</td><td class="red">-5</td><td class="red">-4</td><td class="red">-3</td><td class="red">-2</td>
</tr>
<tr>
<td class="red">-12</td><td class="red">-11</td><td class="red">-10</td><td class="red">-9</td><td class="red">-8</td><td class="red">-7</td><td class="red">-6</td><td class="red">-5</td><td class="red">-4</td><td class="red">-3</td>
</tr>
<tr class="odd">
<td class="red">-13</td><td class="red">-12</td><td class="red">-11</td><td class="red">-10</td><td class="red">-9</td><td class="red">-8</td><td class="red">-7</td><td class="red">-6</td><td class="red">-5</td><td class="red">-4</td>
</tr>
<tr>
<td class="red">-14</td><td class="red">-13</td><td class="red">-12</td><td class="red">-11</td><td class="red">-10</td><td class="red">-9</td><td class="red">-8</td><td class="red">-7</td><td class="red">-6</td><td class="red">-5</td>
</tr>
</table>
</body>
</html>
EOF

__DATA__
@@ index.html.ep
% layout 'main';
% my $isod = sub {
%   my $x = shift;
%   $x->{attributes}{class} = 'odd' unless $x->{row_no} % 2;
%   return $x;
% }
% my $isneg = sub {
%   my $x =shift;
%   $x->{attributes}{class} = 'red' unless $x->{value} >= 0;
%   return $x;
% }
<%= table class => 'programmatic', $data, rcb=> $isodd , ccb=> $isneg, sub=> sub {$stuff->stuff} => begin %>Programmatic.<% end %>

@@ layouts/main.html.ep
<!doctype html><html>
    <head>
       <title>Test</title>
       <style type="text/css">
	  table   { caption-side: bottom; border-collapse: collapse; border-widht: 0pt; }
          td      { text-align: right; padding-left: .5em; padding-right: .5em;}
          td.red  { color: red; } 
          tr.odd  { background-color: Lavender; }
       </style>
    </head>
    <body><%== content %></body>
</html>
