#
# Definition of the RUN functions
# - code sample -
# Dmitry Sergeev 2014
#

package MyCommand;

use strict;
use MyHwInfo;
use Package::Constants;
use Exporter;
our @ISA          = qw[ Exporter ];
our @EXPORT     = qw[ %COMMAND ];

# commands 
our %COMMAND = (
   get_nics => \&getNetworkDevInfo,
   get_blockdev => \&getBlockDevInfo,
   get_memory_info => \&getMemoryInfo,

   # Special commands
   echo => sub {
      foreach (0 .. $_[0] || 0) {
         sleep 1;
      }

      return { echo => 'Hello there!' };
   }
);
