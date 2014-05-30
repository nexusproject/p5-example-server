#
# Default values & constants
# - code sample -
# Dmitry Sergeev 2014
#

package MyDefaults;

use strict;
use Package::Constants;
use Exporter;
use vars qw[@ISA @EXPORT];

@ISA     = qw[ Exporter ];
@EXPORT  = Package::Constants->list( __PACKAGE__ );

# Config values
use constant DEFAULT_PORT     => 1234;
use constant CLIENT_TIMEOUT   => 30; # seconds
use constant TASK_RUN_TTL     => 30; # 0 - turned off
use constant TASK_RESULT_TTL  => 60; # 0 - turned off
use constant SERVER_PID_FILE  => '/tmp/perl-server-example.pid'; 

# Protocol errors
use constant P_ERROR_NO_TASK           => 'No task founded';
use constant P_ERROR_NO_FUNCTION       => 'Function not defined';
use constant P_ERROR_NOT_READY         => 'Task still running, result not ready';
use constant P_ERROR_PRM_INVALID       => 'Invalid parameters';
use constant P_ERROR_NOT_IMPLEMENTED   => 'Not implemented';
use constant P_ERROR_BAD_REQUEST       => 'Bad request';
use constant P_ERROR_TASK_NOT_RUNNING  => 'Task not running';

1;
