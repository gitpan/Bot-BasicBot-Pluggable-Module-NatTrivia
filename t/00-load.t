#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::NatTrivia' ) || print "Bail out!\n";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::NatTrivia $Bot::BasicBot::Pluggable::Module::NatTrivia::VERSION, Perl $], $^X" );
