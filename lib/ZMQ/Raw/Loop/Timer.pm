package ZMQ::Raw::Loop::Timer;

use strict;
use warnings;
use Carp;

sub CLONE_SKIP { 1 }

my @attributes;

BEGIN
{
	@attributes = qw/
		done
		timer
		loop
		on_timeout
	/;

	no strict 'refs';
	foreach my $accessor (@attributes)
	{
		*{$accessor} = sub
		{
			@_ > 1 ? $_[0]->{$accessor} = $_[1] : $_[0]->{$accessor}
		};
	}
}

use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Loop::Timer - Timer class

=head1 DESCRIPTION

A L<ZMQ::Raw::Loop::Timer> represents a timer, usable in a
L<ZMQ::Raw::Loop>.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $context = ZMQ::Raw::Context->new;
	my $loop = ZMQ::Raw::Loop->new ($context);

	my $timer = ZMQ::Raw::Loop::Timer->new
	(
		timer => ZMQ::Raw::Timer->new ($context, after => 100),
		on_timeout => sub
		{
			print "Timed out!\n";
			$loop->terminate();
		},
	);

	$loop->add ($timer);
	$loop->run;

=head1 METHODS

=head2 new( )

Create a new loop timer.

=head2 cancel( )

Cancel the underlying timer.

=cut

sub new
{
	my ($this, %args) = @_;

	if (!$args{timer} || ref ($args{timer}) ne 'ZMQ::Raw::Timer')
	{
		croak "timer not provided or not a 'ZMQ::Raw::Timer'";
	}

	if (!$args{on_timeout} || ref ($args{on_timeout}) ne 'CODE')
	{
		croak "on_timeout not a code ref";
	}

	my $class = ref ($this) || $this;
	my $self =
	{
		timer => $args{timer},
		on_timeout => $args{on_timeout},
	};

	return bless $self, $class;
}

sub cancel
{
	my ($this) = @_;
	$this->timer->cancel;
}

=for Pod::Coverage done timer loop on_timeout

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Loop::Timer
