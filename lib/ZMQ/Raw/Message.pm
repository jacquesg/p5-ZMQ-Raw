package ZMQ::Raw::Message;

use strict;
use warnings;
use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Message - ZeroMQ Message class

=head1 DESCRIPTION

A L<ZMQ::Raw::Message> represents a ZeroMQ message.

=head1 METHODS

=head2 new( )

Create a new empty ZeroMQ message.

=head2 data ([$data])

Retrieve or set the message data.

=head2 more( )

Check if this message is part of a multi-part message, and if there are further
parts to be received.

=head2 size( )

Get the size in bytes of the content of the messsage.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Message

