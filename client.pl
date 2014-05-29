#!/usr/bin/perl -w
#
# Client utility
# - code sample -
# Dmitry Sergeev 2014
#

use strict;
use lib 'lib';
use MyClient;
use Data::Dumper;

$Data::Dumper::Terse = 1;           # don't output names where feasible
$Data::Dumper::Indent = 1;

unless ($ARGV[0]) {
   print "Usage: client.pl <command> args..\n";
   exit 1;
}

my $client = new MyClient(host => 'localhost');

# communicating with server
my $reply = $client->request(join ' ', @ARGV);

# interpret the result
die $reply->{Error} ."\n" unless $reply->{Success};
print $reply->{Payload} ? Dumper $reply->{Payload} : "OK\n";


