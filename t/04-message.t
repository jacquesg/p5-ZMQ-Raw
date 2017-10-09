#!perl

use Test::More;
use ZMQ::Raw;

my $msg = ZMQ::Raw::Message->new;
isa_ok ($msg, "ZMQ::Raw::Message");

is $msg->more, 0;
is $msg->size, 0;
is $msg->data, undef;

ok ($msg->data ('hello'));
is $msg->size, 5;
my $result = $msg->data;
is $result, 'hello';

is $msg->data ('world'), 'world';

done_testing;

