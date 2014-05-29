#
# Client lib
# - code sample -
# Dmitry Sergeev 2014
#

package MyClient;

use strict;
use Carp;
use Socket qw/:DEFAULT IPPROTO_TCP/;
use MyDefaults;
use JSON;

sub new {
   shift; 
   my %args = @_;
   my $host = $args{host} || 'localhost';
   my $port = $args{port} || DEFAULT_PORT;
   my $iaddr = inet_aton($host) or croak "no host: $!";
   my $paddr = sockaddr_in($port, $iaddr);

   return bless { paddr => $paddr };
}

sub request {
   my $self = shift;
   my $request = shift;

   my $proto = getprotobyname("tcp");
   socket(SOCK, PF_INET, SOCK_STREAM, $proto) or croak "socket: $!";
   connect(SOCK, $self->{paddr}) or croak "connect: $!";

   send(SOCK, $request, 0);
   my $reply = <SOCK>;
   close SOCK;
   return from_json $reply;
}

1;
