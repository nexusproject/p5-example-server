p5-example-server
=================

This is the small server that capable to perform the remote functions asynchronously.

This project just my perl5 code sample. Made just for fun! :-)

Installation & Dependencies
---
1. Clone this repo.
2. Install perl JSON lib
using apt:
```
apt-get install libjson-perl
```

or by hands:
http://search.cpan.org/~makamaka/JSON-2.90/lib/JSON.pm

Protocol
---
Simple application-level protocol, running in the form of a request-response.
Client should send the request in form:
```
PROTO_CMD PRM PRMn
```

Server replies by serialized JSON

####Protocol Commands:
Command  | Parameters                | Description
---------|---------------------------|-------------
LIST     | -                         | List of current server tasks
LISTCMDS | -                         | List of defined runnable functions
RUN      | runnable function & prms  | Executing the function
GET      | task id                   | Get the result & close task
INFO     | task id                   | Get info about task
STOP     | task id                   | Stop task 
KILLALL  | -                         | Kill all tasks

Server
---
##### Starting
`./server.pl`
or to daemonize
`./server.pl -d`

##### Configuration?
Please have a look into `lib/MyDefaults.pm`

##### Signals
HUP - Disconnect all clients and stop all tasks

Usage example
---
##### Using client:
List of defined runnable functions:
```
./client.pl listcmds
[
  'get_blockdev',
  'get_nics',
  'echo',
  'get_memory_info'
]
```
Run function, get list tasks and get the result:
```
./client.pl run echo
{
  'task' => '1'
}

./client.pl list
[
  {
    'task' => '1',
    'started' => 1401364683,
    'ready' => 1,
    'command' => 'echo'
  }
]

./client.pl get 1
{
  'Command' => 'echo',
  'Result' => {
    'echo' => 'Hello there!'
  }
}
```
#####Same using telnet :-) 
```
telnet localhost 1234
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
listcmds
{"Payload":["get_blockdev","get_nics","echo","get_memory_info"],"Success":1}Connection closed by foreign host.
```

Defined Functions
---
#####echo
Just echo. Can be runned with parameter - delay (in seconds)
```
./client.pl run echo 5 
```
#####get_memory_info
Memory info from `/proc/meminfo`. You can specify a list of keys by listing them in the parameters. 
Example:
```
./client.pl run get_memory_info MemTotal MemFree
{
  'task' => '3'
}
./client.pl get 3
{
  'Command' => 'get_memory_info',
  'Result' => {
    'MemTotal' => '628876 kB',
    'MemFree' => '55208 kB'
  }
}
```

#####get_blockdev
Get information about block devices. Supports options: disk/cd/floppy
Example:
```
./client.pl run get_blockdev disk
{
  'task' => '2'
}
./client.pl get 2
{
  'Command' => 'get_blockdev',
  'Result' => {
    'sda2' => {
      'devname' => '/dev/sda2',
      'bus' => 'ata',
      'serial' => 'VBOX_HARDDISK_VB36fbd3f0-95aa65cf',
      'model' => 'VBOX_HARDDISK',
      'device' => '/devices/pci0000',
      'subsystem' => 'block',
      'size' => '660603904',
      'type' => 'partition'
    },
    'sda' => {
      'devname' => '/dev/sda',
      'bus' => 'ata',
      'serial' => 'VBOX_HARDDISK_VB36fbd3f0-95aa65cf',
      'model' => 'VBOX_HARDDISK',
      'device' => '/devices/pci0000',
      'subsystem' => 'block',
      'size' => undef,
      'type' => 'disk'
    },
    'sda5' => {
      'devname' => '/dev/sda5',
      'bus' => 'ata',
      'serial' => 'VBOX_HARDDISK_VB36fbd3f0-95aa65cf',
      'model' => 'VBOX_HARDDISK',
      'device' => '/devices/pci0000',
      'subsystem' => 'block',
      'size' => '660602880',
      'type' => 'partition'
    },
    'sda1' => {
      'devname' => '/dev/sda1',
      'bus' => 'ata',
      'serial' => 'VBOX_HARDDISK_VB36fbd3f0-95aa65cf',
      'model' => 'VBOX_HARDDISK',
      'device' => '/devices/pci0000',
      'subsystem' => 'block',
      'size' => '7926185984',
      'type' => 'partition'
    }
  }
}
```
#####get_nics
Get information about nics

####I want to define my own function, what should i do!? :-()
Please have a look into `lib/MyRunnableFunction.pm`

Tested:
---
* Ubuntu/Linaro 4.6.3-1ubuntu5


