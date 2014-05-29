p5-example-server
=================

This is the small threaded server that capable of performing the remote functions.

This just a code sample.Made for fun! :-)

Installation & Dependencies
---
1. Clone this repo.
2. Install perl JSON lib
using apt:
```
apt-get install libjson-perl
```

by hands:
http://search.cpan.org/~makamaka/JSON-2.90/lib/JSON.pm





Protocol
---
Simple application-level protocol, running in the form of a request-response.
Client should send the request in form:
```
<PROTO CMD> PRM1 PRMn
```

Server replies by serialized JSON

####Protocol Commands:
Command  | Parameters                | Description
---------|---------------------------|-------------
LIST     | -                         | List of current server tasks
LISTCMDS | -                         | List of defined runnable functions
RUN      | runnable function name    | Executing the function
GET      | task no                   | Running the function
INFO     | task no                   | Get info about task
STOP     | task no                   | Stop task 
KILLALL  | -                         | Kill all tasks


Using example
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

Signals
---

Its tested!
---
