package Thread::Conveyor::Monitored;

# Make sure we inherit from Thread::Conveyor
# Make sure we have version info for this module
# Make sure we do everything by the book from now on

our @ISA : unique = qw(Thread::Conveyor);
our $VERSION : unique = '0.02';
use strict;

# Make sure we have conveyor belts
# Make sure we have monitored throttled belts

use Thread::Conveyor ();
use Thread::Conveyor::Monitored::Throttled ();

# Allow for self referencing within monitoring thread

my $BELT;

# Satisfy -require-

1;

#---------------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 reference/name of subroutine doing the monitoring
#      3 value to consider end of monitoring action (default: undef)
# OUT: 1 instantiated object
#      2 (optional) thread object of monitoring thread

sub new {

# Obtain the class
# Obtain the parameter hash reference
# Obtain local copy of code to execute
# Die now if nothing specified

    my $class = shift;
    my $param = shift;
    my $monitor = $param->{'monitor'};
    die "Must specify subroutine to monitor the conveyor belt" unless $monitor;

# Create the namespace
# If we don't have a code reference yet, make it one

    my $namespace = caller().'::';
    $monitor = _makecoderef( $namespace,$monitor ) unless ref($monitor);

# Obtain local copy of the pre subroutine reference
# If we have one but it isn't a code reference yet, make it one
# Obtain local copy of the post subroutine reference
# If we have one but it isn't a code reference yet, make it one

    my $pre = $param->{'pre'};
    $pre = _makecoderef( $namespace,$pre ) if $pre and !ref($pre);
    my $post = $param->{'post'};
    $post = _makecoderef( $namespace,$post ) if $post and !ref($post);

# Initialize the belt
# If we already have a belt
#  Set to use the throttled class if the belt is already throttled
#  Rebless the object as ourselves
#  For all the special methods
#   Reloop if the field is not specified
#   Execute the method on that object

    my $belt;
    if ($belt = $param->{'belt'}) {
        $class .= '::Throttled' if ref($belt) =~ m#::Throttled$#;
        $belt = bless $belt,$class;
        foreach (qw(maxboxes minboxes)) {
            next unless exists( $param->{$_} );
            $belt->$_( $param->{$_} );
        }


# Else (we don't have a belt yet)
#  Initialize a belt parameter hash
#  Set maxboxes field if specified
#  Set minboxes field if specified
#  Create a belt with these parameters

    } else {
        my $beltparam = {};
        $beltparam->{'maxboxes'} = $param->{'maxboxes'}
         if exists( $param->{'maxboxes'} );
        $beltparam->{'minboxes'} = $param->{'minboxes'}
         if exists( $param->{'minboxes'} );
        $belt = $class->SUPER::new( $beltparam );
    }

# Create a thread monitoring the belt
# Return the belt object or both objects

    my $thread = threads->new(
     \&_monitor,
     $belt,
     wantarray,         # true if we do not want to detach
     $monitor,
     $param->{'exit'},	# don't care if not available: then undef = exit value
     $post,
     $pre,
     @_
    );
    return wantarray ? ($belt,$thread) : $belt;
} #new

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
# OUT: 1 instantiated Thread::Conveyor object

sub belt { $BELT } #belt

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub take { _die() } #take

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub take_dontwait { _die() } #take_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub clean { _die() } #clean

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub clean_dontwait { _die() } #clean_dontwait

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub peek { _die() } #peek

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub peek_dontwait { _die() } #peek_dontwait

#---------------------------------------------------------------------------

# Internal subroutines

#---------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)

sub _die {

# Obtain the name of the caller
# Die with the name of the caller

    (my $caller = (caller(1))[3]) =~ s#^.*::##;
    die "You cannot '$caller' on a monitored conveyor belt";
} #_die

#---------------------------------------------------------------------------
#  IN: 1 namespace prefix
#      2 subroutine name
# OUT: 1 code reference

sub _makecoderef {

# Obtain namespace and subroutine name
# Prefix namespace if not fully qualified
# Return the code reference

    my ($namespace,$code) = @_;
    $code = $namespace.$code unless $code =~ m#::#;
    \&{$code};
} #_makecoderef

#---------------------------------------------------------------------------
#  IN: 1 belt object to monitor
#      2 flag: to keep thread attached
#      3 code reference of monitoring routine
#      4 exit value
#      5 code reference of preparing routine (if available)
#      6..N parameters passed to creation routine

sub _monitor {

# Obtain the belt object
# Make sure this thread disappears outside if we don't want to keep it
# Obtain the monitor code reference
# Obtain the exit value

    my $belt = $BELT = shift;
    threads->self->detach unless shift;
    my $monitor = shift;
    my $exit = shift;

# Obtain the post subroutine reference or create an empty one
# Obtain the preparation subroutine reference
# Execute the preparation routine if there is one

    my $post = shift || sub {};
    my $pre = shift;
    $pre->( @_ ) if $pre;

# While we're processing
#  Obtain frozen copies of all the boxes and clean the belt
#  For all of the boxes just obtained
#   Obtain the actual values that are frozen in the box
#   If there is a defined exit value
#    Return now with result of post() if so indicated
#   Elsif found value is not defined (so same as exit value)
#    Return now with result of post()
#   Call the monitoring routine with all the values

    while( 1 ) {
        my @value = $belt->_clean;
        foreach my $value (@value) {
            my @set = @{$belt->_thaw( $value )};
            if (defined($exit)) {
                return $post->( @_ ) if $set[0] eq $exit;
            } elsif (!defined( $set[0] )) {
                return $post->( @_ );
            }
            $monitor->( @set );
        }
    }
} #_monitor

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Conveyor::Monitored - monitor a belt for specific content

=head1 SYNOPSIS

    use Thread::Conveyor::Monitored;
    my ($belt,$thread) = Thread::Conveyor::Monitored->new(
     {
      monitor => sub { print "monitoring value $_[0]\n" }, # is a must
      pre => sub { print "prepare monitoring\n" },         # optional
      post => sub { print "stop monitoring\n" },           # optional
      belt => $belt,   # use existing belt, create new if not specified
      exit => 'exit',  # defaults to undef

      maxboxes => 50,  # specify throttling
      minboxes => 25,  # parameters
     }
    );

    $belt->put( "foo",['listref'],{'hashref'} );
    $belt->put( undef ); # exit value by default

    @post = $thread->join; # optional, wait for monitor thread to end

    $belt = Thread::Conveyor::Monitored->belt; # "pre", "do", "post"

=head1 DESCRIPTION

                 *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.
 It is of no use with any version of Perl before 5.8.0 or
 without threads enabled.

                 *************************

The C<Thread::Conveyor::Monitored> module implements a single worker thread
that takes of boxes of values from a belt created with L<Thread::Conveyor>
and which checks the boxes for specific content.

It can be used for simply logging actions that are placed on the belt. Or
only output warnings if a certain value is encountered in a box.  Or create
a safe sandbox for Perl modules that are not thread-safe yet.

The action performed in the thread, is determined by a name or reference
to a subroutine.  This subroutine is called for every box of values obtained
from the belt.

Any number of threads can safely put boxes with values and reference on the
belt.

=head1 CLASS METHODS

=head2 new

 ($belt,$thread) = Thread::Conveyor::Monitored->new(
  {
   pre => \&pre,
   monitor => 'monitor',
   post => \&module::post,
   belt => $belt,   # use existing belt, create new if not specified
   exit => 'exit',  # defaults to undef
  }
 );


The C<new> function creates a monitoring function on an existing or on a new
(empty) belt.  It returns the instantiated Thread::Conveyor::Monitored object
in scalar context: in that case, the monitoring thread will be detached and
will continue until the exit value is put in a box on the belt.  In list
context, the thread object is also returned, which can be used to wait
for the thread to be really finished using the C<join()> method.

The first input parameter is a reference to a hash that should at least
contain the "monitor" key with a subroutine reference.

The other input parameters are optional.  If specified, they are passed to the
the "pre" routine which is executed once when the monitoring is started.

The following field B<must> be specified in the hash reference:

=over 2

=item do

 monitor => 'monitor_the_belt',	# assume caller's namespace

or:

 monitor => 'Package::monitor_the_belt',

or:

 monitor => \&SomeOther::monitor_the_belt,

or:

 monitor => sub {print "anonymous sub monitoring the belt\n"},

The "monitor" field specifies the subroutine to be executed for each set of
values that is removed from the belt.  It must be specified as either the
name of a subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  set of values obtained from the box on the belt

What the subroutine does with the values, is entirely up to the developer.

=back

The following fields are B<optional> in the hash reference:

=over 2

=item pre

 pre => 'prepare_monitoring',		# assume caller's namespace

or:

 pre => 'Package::prepare_monitoring',

or:

 pre => \&SomeOther::prepare_monitoring,

or:

 pre => sub {print "anonymous sub preparing the monitoring\n"},

The "pre" field specifies the subroutine to be executed once when the
monitoring of the belt is started.  It must be specified as either the
name of a subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any extra parameters that were passed with the call to L<new>.

=item post

 post => 'stop_monitoring',		# assume caller's namespace

or:

 post => 'Package::stop_monitoring',

or:

 post => \&SomeOther::stop_monitoring,

or:

 post => sub {print "anonymous sub when stopping the monitoring\n"},

The "post" field specifies the subroutine to be executed once when the
monitoring of the belt is stopped.  It must be specified as either the
name of a subroutine or as a reference to a (anonymous) subroutine.

The specified subroutine should expect the following parameters to be passed:

 1..N  any parameters that were passed with the call to L<new>.

Any values returned by the "post" routine, can be obtained with the C<join>
method on the thread object.

=item belt

 belt => $belt,  # create new one if not specified

The "belt" field specifies the Thread::Conveyor object that should be
monitored.  A new L<Thread::Conveyor> object will be created if it is not
specified.

=item exit

 exit => 'exit',   # defaults to undef

The "exit" field specifies the value that will cause the monitoring thread
to seize monitoring.  The "undef" value will be assumed if it is not specified.
This value should be L<put> in a box on the belt to have the monitoring thread
stop.

=item maxboxes

 maxboxes => 50,

 maxboxes => undef,  # disable throttling

The "maxboxes" field specifies the B<maximum> number of boxes that can be
sitting on the belt to be handled (throttling).  If a new L<put> would
exceed this amount, putting of boxes will be halted until the number of
boxes waiting to be handled has become at least as low as the amount
specified with the "minboxes" field.

Fifty boxes will be assumed for the "maxboxes" field if it is not specified.
If you do not want to have any throttling, you can specify the value "undef"
for the field.  But beware!  If you do not have throttling active, you may
wind up using excessive amounts of memory used for storing all of the boxes
that have not been handled yet.

The L<maxboxes> method can be called to change the throttling settings
during the lifetime of the object.

=item minboxes

 minboxes => 25, # default: maxboxes / 2

The "minboxes" field specified the B<minimum> number of boxes that can be
waiting on the belt to be handled before the L<put>ting of boxes is allowed
again (throttling).

If throttling is active and the "minboxes" field is not specified, then
half of the "maxboxes" value will be assumed.

The L<minboxes> method can be called to change the throttling settings
during the lifetime of the object.

=back

=head2 belt

 $belt = Thread::Conveyor::Monitored->belt; # only within "pre" and "do"

The class method "belt" returns the L<Thread::Conveyor> object for which this
thread is monitoring.  It is available within the "pre" and "do" subroutine
only.

=head1 OBJECT METHODS

=head2 put

 $belt->put( $scalar,[],{} );
 $belt->put( 'exit' ); # stop monitoring

The "put" method freezes all specified parameters in a box and puts it on
the belt.  The monitoring thread will stop monitoring if the "exit" value
is put in the box.

=head2 maxboxes

 $belt->maxboxes( 100 );
 $maxboxes = $belt->maxboxes;

The "maxboxes" method returns the maximum number of boxes that can be on the
belt before throttling sets in.  The input value, if specified, specifies the
new maximum number of boxes that may be on the belt.  Throttling will be
switched off if the value B<undef> is specified.

Specifying the "maxboxes" field when creating the object with L<new> is
equivalent to calling this method.

The L<minboxes> method can be called to specify the minimum number of boxes
that must be on the belt before the putting of boxes is allowed again after
reaching the maximum number of boxes.  By default, half of the "maxboxes"
value is assumed.

=head2 minboxes

 $belt->minboxes( 50 );
 $minboxes = $belt->minboxes;

The "minboxes" method returns the minimum number of boxes that must be on the
belt before the putting of boxes is allowed again after reaching the maximum
number of boxes.  The input value, if specified, specifies the new minimum
number of boxes that must be on the belt.

Specifying the "minboxes" field when creating the object with L<new> is
equivalent to calling this method.

The L<maxboxes> method can be called to set the maximum number of boxes that
may be on the belt before the putting of boxes will be halted.

=head1 CAVEATS

You cannot remove any boxes from the belt, as that is done by the monitoring
thread.  Therefore, the methods "take", "take_dontwait", "peek" and
"peek_dontwait" are disabled on this object.

Passing unshared values between threads is accomplished by freezing the
specified values using C<Storable> when putting the boxes on the belt and
thawing the values when the box is taken off the belt.  This allows for
great flexibility at the expense of more CPU usage.  Unfortunately it also
limits what can be passed, as e.g. code references and blessed objects can
B<not> (yet) be frozen and therefore not be passed.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>, L<threads::shared>, L<Thread::Conveyor>, L<Storable>.

=cut
