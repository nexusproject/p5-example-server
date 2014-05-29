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



###Protocol Commands:
Command  | Parameters                | Description
---------|---------------------------|-------------
LIST     | none                      |
LISTCMDS | none                      |
RUN      | runnable function name    |
GET      | task no                   |
INFO     | task no                   |
STOP     | task no                   | 
KILLALL  | none                      |


Using example
---

Defined Functions
---

Signals
---

Its tested!
---
