require 5.008;
use threads (); # just to force breakage if threads are not available
use ExtUtils::MakeMaker;

WriteMakefile (
 NAME		=> "Thread::Conveyor::Monitored",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	=> 'monitor a belt for specific content') : (),
 VERSION_FROM	=> 'lib/Thread/Conveyor/Monitored.pm',
 PREREQ_PM	=> {
                    'Thread::Conveyor' => '0.08',
                   },
);
