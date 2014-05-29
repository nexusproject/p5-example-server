#
# Threaded worker & proto
# - code sample -
# Dmitry Sergeev 2014
#

package MyWorker;

use strict;
use threads ('yield', 'exit' => 'threads_only');
use MyDefaults;
use MyRunnableFunction;
use JSON;
use Exporter;
use vars qw[@ISA @EXPORT];

@ISA     = qw[Exporter];
@EXPORT  = qw[
   processRequest
   killAllTasks
];

my %TASK;

sub taskState {
   my $tid = shift;
   if (my $task = $TASK{$tid}) {
      return {
         task => $tid,
         command => $task->{command},
         started => $task->{started},
         ready => $task->{thread}->is_running() ? 0 : 1
      };
   }
}

sub killTask {
   my $task_id = shift;
   if (my $task = $TASK{$task_id}) {
      $task->{thread}->is_running ? $task->{thread}->kill('KILL')->detach() : $task->{thread}->join();
      delete $TASK{$task_id};
   }
}

# killing all tasks
sub killAllTasks {
   killTask $_ foreach keys %TASK;
}

sub protoSuccess {
   my $payload = shift;
   return { Success => 1, Payload => $payload };
}

sub protoError {
   my $errorDescription = shift;
   return { Success => 0, Error => $errorDescription };
}

# Task's autokill & autoclean the results
$SIG{ALRM} = sub {
   foreach my $tid (keys %TASK) {
      my $task = $TASK{$tid};
      if ($task->{thread}->is_running) {
         # running tasks
         if (TASK_RUN_TTL && $task->{started} + TASK_RUN_TTL < time()) {
            print "Worker: Killing task $tid by timeout\n";
            killTask $tid;
         }
      }
      else {
         # results
         $task->{stopped} = time() unless $task->{stopped};

         if (TASK_RESULT_TTL && $task->{stopped} + TASK_RESULT_TTL < time()) {
            # finalizing task & deleting result
            print "Worker: Cleaning the result of task $tid\n";
            $task->{thread}->join();
            delete $TASK{$tid};
         }  
      }
   }
   alarm 1;
};
alarm 1;

# protocol commands
my %PROTO = (
   RUN => sub {
      my $cmdName = shift;
      my @prms = @_;
      
      return protoError P_ERROR_PRM_INVALID unless $cmdName;

      if (my $func = $RUN_FUNCTION{$cmdName}) {
         my $thr = threads->create(sub {
            $SIG{KILL} = sub { print "Thread exiting..\n"; threads->exit(); };

            print "Thread: executing command $cmdName (" . join(',', @prms) . ")\n";
            return &$func(@prms);
         });

         # XXX: Seems is no sense to generate unique id specially
         my $tid = $thr->tid();

         $TASK{$tid} = {
            command => $cmdName,
            thread   => $thr,
            started => time()
         };
         
         return protoSuccess { task => $tid };
      }
      else {
         return protoError P_ERROR_NO_FUNCTION;
      }
   },

   # get task result
   GET => sub {
      my $task_id = shift;

      return protoError P_ERROR_PRM_INVALID unless $task_id;

      if (my $task = $TASK{$task_id}) {
         unless ($task->{thread}->is_running()) {
            my $reply = protoSuccess { Command => $task->{command}, Result => $task->{thread}->join() };

            delete $TASK{$task_id};
            return $reply;
         }
         else {
            return protoError P_ERROR_NOT_READY;
         }
      }
      else {
         return protoError P_ERROR_NO_TASK;
      }
   },

   # get list of allowed commands 
   LISTCMDS => sub {
      return protoSuccess [ keys %RUN_FUNCTION ];
   },

   # get task info
   INFO => sub {
      my $task_id = shift;
      return protoError P_ERROR_PRM_INVALID unless $task_id;

      if (my $task = $TASK{$task_id}) {
         return protoSuccess taskState $task_id;
      }
      else {
         return protoError P_ERROR_NO_TASK;
      }
   },

   # get list of current tasks
   LIST => sub {
      return protoSuccess [ map { taskState $_ } keys %TASK ]; 
   },

   # stop the task
   STOP => sub {
      my $task_id = shift;
      return protoError P_ERROR_PRM_INVALID unless $task_id;   

      if (my $task = $TASK{$task_id}) {
         if ($task->{thread}->is_running) { 
            killTask $task_id;
            return protoSuccess ();
         } 
         else {
            return protoError P_ERROR_TASK_NOT_RUNNING;
         } 
      }
      else {
         return protoError P_ERROR_NO_TASK;
      }
   },

   # killall tasks
   KILLALL => sub {
      killAllTasks();
      return protoSuccess ();
   }
);

# processing the request
sub processRequest {
   my $request = shift;
   my ($command, @args) = split /\s+/, $request;

   if ($command && exists $PROTO{uc $command}) {
      print "Worker: Client requesting: $command " . join(',', @args). "\n";
      return to_json &{$PROTO{uc $command}}(@args); 
   }
   else {
      return to_json protoError P_ERROR_BAD_REQUEST;
   }
}

1;
