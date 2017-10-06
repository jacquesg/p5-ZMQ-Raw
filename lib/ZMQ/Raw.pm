package ZMQ::Raw;

use strict;
use warnings;

require XSLoader;
XSLoader::load ('ZMQ::Raw', $ZMQ::Raw::VERSION);

=head1 NAME

ZMQ::Raw - Perl bindings to the ZeroMQ library

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw

