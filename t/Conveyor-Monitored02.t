BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use Test::More tests => 12;

BEGIN { use_ok('Thread::Conveyor::Monitored') }

my $times = 1000;
my $file = 'outmonitored';
my $handle;
my $object : shared;

my ($belt,$thread) = Thread::Conveyor::Monitored->new(
 {
  pre => sub {
              ok( open( $handle,">$_[0]" ), 'check pre opening file' );
              $object = ref(Thread::Conveyor::Monitored->belt);
             },
  monitor => sub { print $handle (%{$_[0]}) },
  post => sub {
               ok( close( $handle ), 'check post closing file');
	       return 'anydone'
              },
 },
 $file
);

isa_ok( $belt, 'Thread::Conveyor::Monitored', 'check belt object type' );
isa_ok( $thread, 'threads',		'check thread object type' );

$belt->put( {$_ => $_+1} ) foreach 1..$times;
my $onbelt = $belt->onbelt;
ok( $onbelt >= 0 and $onbelt <= $times, 'check number of values on the belt' );

$belt->put( undef ); # stop monitoring
is( $thread->join,'anydone',			'check result of join' );

is( $object,'Thread::Conveyor::Monitored', 'check result of ->belt' );

my $check = '';
$check .= ($_.($_+1)) foreach 1..$times;
ok( open( my $in,"<$file" ),		'check opening of file' );
is( join('',<$in>), $check,		'check whether monitoring ok' );
ok( close( $in ),			'check closing of file' );

ok( unlink( $file ) );
