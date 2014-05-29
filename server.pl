#!/usr/bin/perl -w
#
# Simple nonblocking threaded server
# - code sample -
# Dmitry Sergeev 2014
#

use strict;
#use IO::Socket::INET # XXX: wanna show the low-level approach 
#use IO::Select       # this an example, so only hardcore )
use Socket qw[:DEFAULT IPPROTO_TCP TCP_NODELAY];
use POSIX qw[:errno_h :fcntl_h setsid];
use lib 'lib';
use MyDefaults;
use MyWorker;

my (%handle, $ServerSocket, $rbx);

# Dealing w signals
$SIG{INT} = $SIG{KILL} = $SIG{TERM} = sub {
   POSIX::close $ServerSocket;
   print "Killing tasks..\n";
   killAllTasks();
   print "Bye bye..\n";
   exit; 
};

$SIG{HUP} = sub {
   print "Dropping connections..\n";
   $rbx = chr 0;
   POSIX::close $_ foreach keys %handle;
   print "Killing tasks..\n";
   killAllTasks();
   vec($rbx, fileno($ServerSocket), 1) = 1;
};

sub daemonize { 
   chdir '/';
   open STDIN, '/dev/null' or die "Cant read /dev/null";
   open STDOUT, '>/dev/null' or die "Cant open for write /dev/null";
   defined(my $pid = fork) or die "Cant fork";
   exit if $pid;

   setsid() or die "Cant make new session";
   open STDERR, '>&STDOUT';
}

sub getFdList {
   my @bits = split(//, unpack('b*', shift));
   my @fdlist;
   for (my $i=0; $i<=$#bits; $i++) {
      push @fdlist, $i if $bits[$i];
   }

   return @fdlist;
}

sub closeHandle {
   my $fd = shift;
   vec($rbx, $fd, 1) = 0;
   # XXX: This is simple way to avoid the problem with cloned io descriptor in thread
   POSIX::close $fd;
   delete $handle{$fd};
}

# Starting.
die "Can be runned on Linux systems ONLY!\n" if $^O ne 'linux';

my $__pidfile = SERVER_PID_FILE;
my $__pid = `cat $__pidfile` if -e $__pidfile; 
if ($__pid) {
   chop $__pid;
   die "Server already running on pid $__pid..\n" if kill 0, $__pid;
}

print "Starting..\n";
daemonize() if $ARGV[0] && $ARGV[0] eq '-d';
system "echo $$ > $__pidfile";
$0 = 'perl-server-example';

# Socket stuff
my $proto = getprotobyname('tcp');
socket($ServerSocket, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
setsockopt($ServerSocket, SOL_SOCKET, SO_REUSEADDR, 1) or die "setsockopt: $!";
bind($ServerSocket, sockaddr_in(DEFAULT_PORT, INADDR_ANY)) or die "bind: $!";
listen($ServerSocket, SOMAXCONN);   

# Main loop
$rbx = chr 0;
vec($rbx, fileno($ServerSocket), 1) = 1;

for (;;) {
   # XXX: For linux epoll is better, but this is an classic.
   my $nf = select(my $rbs=$rbx, undef, undef, 1);

   if ($nf > 0) {
      # Processing ready for read
      foreach my $fd ( getFdList($rbs) ) {
         if ($fd == fileno($ServerSocket)) {
            if (accept(my $client, $ServerSocket)) {
               print "Client connected.\n";
               $handle{ fileno($client) } = {
                  sock => $client, 
                  ts => time() 
               };

               my $flags = fcntl($client, F_GETFL, 0);
               fcntl($client, F_SETFL, $flags | O_NONBLOCK);
               vec($rbx, fileno($client), 1) = 1;
            }
         }
         else {
            # XXX: Theoretically, with O_NONBLOCK sockets, this approach may not guarantee the data integrity.
            # But i think thats enough for this case. 

            # Communicating w client
            my $client = $handle{$fd}->{sock};
            my $ret = read($client, my $data, POSIX::BUFSIZ);

            if ($ret > 0) {
               # Processing the request
               send($client, processRequest($data), 0); 
            } 
            elsif ($ret == 0) {
               # Seems client gone
               print "Client gone\n";
            }
         
            closeHandle $fd;
         }
      }
   } #nf
   
   # Processing timeouts
   foreach my $fd ( getFdList($rbx) ) {
      next if $fd == fileno($ServerSocket); 
      if ($handle{$fd}->{ts} + CLIENT_TIMEOUT <= time()) {
         print "Client was disconnected after timeout.\n";
         closeHandle $fd;
      }
   } 
}

