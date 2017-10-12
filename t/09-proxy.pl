#!perl

use strict;
use warnings;
use Config;
use Test::More;
use ZMQ::Raw;

if (!$Config{useithreads})
{
	diag ("threads not available, skipping");
	ok (1);
	done_testing;
	exit;
}

require threads;

sub Proxy
{
	my $ctx = ZMQ::Raw::Context->new;

	my $frontend = ZMQ::Raw::Socket->new (ZMQ::Raw->ZMQ_ROUTER);
	$frontend->bind ('tcp://*:5555');

	my $backend = ZMQ::Raw::Socket->new (ZMQ::Raw->ZMQ_DEALER);
	$backend->bind ('tcp://*:5556');

	my $proxy = ZMQ::Raw::Proxy->new();
	$proxy->start ($frontend, $backend);
}

my $proxy = threads->create ('Proxy');

$proxy->join();

ok (1);
done_testing;

