package Thread::Conveyor::Monitored::Throttled;

# Make sure we're a monitored conveyor belt
# Make sure we have version info for this module
# Make sure we do everything by the book from now on

our @ISA : unique = qw(Thread::Conveyor::Monitored);
our $VERSION : unique = '0.03';
use strict;

# Make sure we can do naughty things
# For all the subroutines that are identical to normal belts are monitored
#  Make sure they are the same

{
 no strict 'refs';
 foreach (qw(_clean _red maxboxes minboxes onbelt put)) {
     *$_ = \&{"Thread::Conveyor::Throttled::$_"};
 }
}

# Satisfy -require-

1;

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Conveyor::Monitored::Throttled - helper class of Thread::Conveyor::Monitored

=head1 DESCRIPTION

This class should not be called by itself, but only by specifying throttling
parameters with a call to L<Thread::Conveyor::Monitored>.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Thread::Conveyor::Monitored>.

=cut
