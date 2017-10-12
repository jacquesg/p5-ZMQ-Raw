package ZMQ::Raw::Proxy;

use strict;
use warnings;
use ZMQ::Raw;

sub CLONE_SKIP { 1 }

=head1 NAME

ZMQ::Raw::Proxy - ZeroMQ Proxy class

=head1 DESCRIPTION

ZeroMQ Proxy

=head1 SYNOPSIS

	use ZMQ::Raw;

=head1 METHODS

=head2 new( )

Create a new proxy instance.

=head2 start( $frontend, $backend, [$capture, $control] )

Start the built-in ZeroMQ proxy in the current application thread. The proxy
connects the frontend socket to the backend socket. If a C<$capture> socket is
provided, the proxy shall send all messages, received on both frontend and
backend to the C<$capture> socket. If a C<$control> socket is provided, the proxy
also supports flow control. If C<"PAUSE"> is received on this socket, the proxy
suspends its activities. If C<"RESUME"> is received, it goes on. If C<"TERMINATE">
is received, it terminates smoothly.

B<WARNING>: This method will only return once the current context is closed,
that is, it will block. This method B<must> be called in a different interpreter
thread.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Proxy

