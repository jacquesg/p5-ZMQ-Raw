package ZMQ::Raw::Curve;

use strict;
use warnings;
use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Curve - ZeroMQ CURVE methods

=head1 DESCRIPTION

ZeroMQ CURVE methods.

=head1 SYNOPSIS

	use ZMQ::Raw;

	my ($private, $public) = ZMQ::Raw::Curve->keypair();

=head1 METHODS

=head2 keypair( )

Create a new, generated random keypair consisting of a private and public key.
Returns the private and public key in list context and only the private key
in scalar context.

=head2 public( $private )

Derive the public key from a private key.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Curve

