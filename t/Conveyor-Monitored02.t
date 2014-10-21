BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use Test::More tests => 1 + (2 * (4 * 11));

BEGIN { use_ok('Thread::Conveyor::Monitored') }

my $file = 'outmonitored';
my $handle;
my $class : shared;

foreach my $optimize (qw(cpu memory)) {

foreach my $times (10,100,1000,int(rand(1000))) {

diag( "$times boxes optimized for $optimize" );

  my $mbelt = Thread::Conveyor::Monitored->new(
   {
    optimize => $optimize,
    pre => sub {
                ok( open( $handle,">$_[0]" ), 'check pre opening file' );
                $class = ref(Thread::Conveyor::Monitored->belt);
               },
    monitor => sub { print $handle (%{$_[0]}) },
    post => sub {
                 ok( close( $handle ), 'check post closing file');
                 return 'anydone'
                },
   },
   $file
  );

  isa_ok( $mbelt, 'Thread::Conveyor::Monitored', 'check belt object type' );
  my $thread = $mbelt->thread;
  isa_ok( $thread, 'threads',		'check thread object type' );

  $mbelt->put( {$_ => $_+1} ) foreach 1..$times;
  my $onbelt = $mbelt->onbelt;
  ok( $onbelt >= 0 and $onbelt <= $times, 'check number of values on the belt');

  threads->yield;
  ok( $class =~ m#^Thread::Conveyor::#,	'check result of ->belt' );

  is( ($mbelt->shutdown)[0],'anydone',	'check result of shutdown' );

  my $check = '';
  $check .= ($_.($_+1)) foreach 1..$times;
  ok( open( my $in,"<$file" ),		'check opening of file' );
  is( join('',<$in>), $check,		'check whether monitoring ok' );
  ok( close( $in ),			'check closing of file' );

  ok( unlink( $file ) );
} #$times

} #$optimize
