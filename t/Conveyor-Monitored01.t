BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use Test::More tests => 3+(2*4);

BEGIN { use_ok('threads') }
BEGIN { use_ok('Thread::Conveyor::Monitored') }

can_ok( 'Thread::Conveyor::Monitored',qw(
 belt
 new
 onbelt
 peek
 peek_dontwait
 put
 take
 take_dontwait
) );

my @list : shared;
my $times = 1000;

check( Thread::Conveyor::Monitored->new( { monitor => \&monitor } ) );

my ($belt,$thread) = Thread::Conveyor->new;
my $exit = 'exit';
($belt,$thread) = Thread::Conveyor::Monitored->new(
 {
  monitor => 'monitor',
  belt => $belt,
  exit => $exit,
 }
);
check( $belt,$thread,$exit );

sub check {

  my ($belt,$thread,$exit) = @_;
  @list = ();

  isa_ok( $belt, 'Thread::Conveyor::Monitored', 'check belt object type' );
  isa_ok( $thread, 'threads',		'check thread object type' );

  $belt->put( [$_,$_+1] ) foreach 1..$times;
  my $onbelt = $belt->onbelt;
  ok( $onbelt >= 0 and $onbelt <= $times, 'check number of values on belt' );

  $belt->put( $exit ); # stop monitoring
  $thread->join;

  my $check = '';
  $check .= ($_.($_+1)) foreach 1..$times;
  is( join('',@list), $check,		'check whether monitoring ok' );
} #check

sub monitor { push( @list,join('',@{$_[0]}) ) }
