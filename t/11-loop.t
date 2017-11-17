#!perl

use Test::More;
use ZMQ::Raw;

my $ctx = ZMQ::Raw::Context->new;
my $loop = ZMQ::Raw::Loop->new ($ctx);

sub trigger
{
	my $sock = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_DEALER);
	$sock->connect ('tcp://localhost:5559');
	$sock->send ('hello');
}

my $sock = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_DEALER);
$sock->bind ('tcp://*:5559');

my $readable = 0;
my $handle;
$handle = ZMQ::Raw::Loop::Handle->new (
	handle => $sock,
	timeout => 1000,
	on_timeout => sub
	{
		$loop->terminate();
	},
	on_readable => sub
	{
		$sock->recv;

		if (++$readable == 2)
		{
			$loop->terminate();
		}
		else
		{
			$loop->add ($handle);

			trigger;
		}

	}
);
isa_ok $handle, 'ZMQ::Raw::Loop::Handle';

ok (!eval {ZMQ::Raw::Loop::Handle->new});
ok (!eval {ZMQ::Raw::Loop::Handle->new (handle => 'blah')});
ok (!eval {ZMQ::Raw::Loop::Handle->new (handle => $sock, on_readable => 'blah')});
ok (!eval {ZMQ::Raw::Loop::Handle->new (handle => $sock, on_writable => 'blah')});
ok (!eval {ZMQ::Raw::Loop::Handle->new (handle => $sock, on_readable => sub {}, on_timeout => 'blah')});
ok (!eval {ZMQ::Raw::Loop::Handle->new (handle => $sock, on_readable => sub {}, on_timeout => sub {})});

trigger;
$loop->add ($handle);
$loop->run;
is $readable, 2;

my $handle2 = ZMQ::Raw::Loop::Handle->new (
	handle => $sock,
	timeout => 1000,
	on_timeout => sub
	{
		$loop->terminate();
	},
	on_readable => sub
	{
		$sock->recv;
		++$readable;
	}
);

$loop->add ($handle2);
$loop->run;
is $readable, 2;


my $count = 0;
my $timer = ZMQ::Raw::Loop::Timer->new (
	timer => ZMQ::Raw::Timer->new ($ctx, after => 100, interval => 100),
	on_timeout => sub
	{
		my ($timer) = @_;

		if (++$count == 5)
		{
			$timer->cancel();
			$loop->terminate();
		}
	}
);

ok (!eval {ZMQ::Raw::Loop->Timer->new});
ok (!eval {ZMQ::Raw::Loop->Timer->new (timer => ZMQ::Raw::Timer->new ($ctx, after => 100))});

$loop->add ($timer);
$loop->run;
is $count, 5;

my $size = $loop->poller->size;
is $size, 0;

my $timedout = 0;
$handle = ZMQ::Raw::Loop::Handle->new (
	handle => $sock,
	timeout => 1000,

	on_readable => sub
	{
		my ($handle) = @_;

		isa_ok $handle, 'ZMQ::Raw::Loop::Handle';

		++$readable;
		$sock->recv;

		$loop->terminate();
	},
	on_timeout => sub
	{
		my ($handle) = @_;

		isa_ok $handle, 'ZMQ::Raw::Loop::Handle';

		++$timedout;

		$loop->terminate();
	},
);

$loop->add ($handle);
$loop->run;

$size = $loop->poller->size;
is $size, 0;
is $count, 5;
is $timedout, 1;

ok (!eval {ZMQ::Raw::Loop::Event->new});
ok (!eval {ZMQ::Raw::Loop::Event->new ($ctx, on_set => 'blah')});
ok (!eval {ZMQ::Raw::Loop::Event->new ($ctx, on_set => sub {}, on_timeout => 'blah')});
ok (!eval {ZMQ::Raw::Loop::Event->new ($ctx, on_set => sub {}, on_timeout => sub {})});

my $eventset = 0;
my $event1 = ZMQ::Raw::Loop::Event->new ($ctx,
	on_set => sub
	{
		++$eventset;
	}
);

my $event2 = ZMQ::Raw::Loop::Event->new ($ctx,
	timeout => 1000,
	on_set => sub
	{
		++$eventset;
	},
	on_timeout => sub
	{
		++$timedout;
		$loop->terminate();
	}
);

my $event3 = ZMQ::Raw::Loop::Event->new ($ctx,
	timeout => 10000,
	on_set => sub
	{
		++$eventset;
	},
	on_timeout => sub
	{
		++$timedout;
	},
);

$timer = ZMQ::Raw::Loop::Timer->new (
	timer => ZMQ::Raw::Timer->new ($ctx, after => 100),
	on_timeout => sub
	{
		++$timedout;
		$event1->set();
	}
);

$loop->add ($timer);
$loop->add ($event1);
$loop->add ($event2);
$loop->add ($event3);
$loop->run;

is $timedout, 3;
is $eventset, 1;

done_testing;
