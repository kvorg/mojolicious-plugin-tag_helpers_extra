#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::TagHelpersExtra' ) || print "Bail out!
";
}

diag( "Testing Mojolicious::Plugin::TagHelpersExtra $Mojolicious::Plugin::TagHelpersExtra::VERSION, Perl $], $^X" );
