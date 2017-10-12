#!perl

use Test::More;
use ZMQ::Raw;

my ($private, $public) = ZMQ::Raw::Curve->keypair();

ok ($public ne $private);
is length ($public), 40;
is length ($private), 40;

ok (!eval {ZMQ::Raw::Curve->public ("badlength")});
is $public, ZMQ::Raw::Curve->public ($private);

$private = ZMQ::Raw::Curve->keypair();
is length ($private), 40;

done_testing;

