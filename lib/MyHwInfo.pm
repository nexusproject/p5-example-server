#
# Sysinfo functions
# - code sample -
# Dmitry Sergeev 2014
#

package MyHwInfo;

use strict;
use Exporter;
use vars qw[@ISA @EXPORT];
   
@ISA     = qw[Exporter];
@EXPORT  = qw[
   getMemoryInfo
   getBlockDevInfo
   getNetworkDevInfo 
];

# memory info
sub getMemoryInfo {
   my @fields = @_;

   open (MEMINFO, '</proc/meminfo') or die "Cant open /proc/meminfo $!";

   my $meminfo;
   while (<MEMINFO>) {
      chop;
      my ($key, $val) = split /\s*\:\s*/, $_, 2;
      $meminfo->{$key} = $val if ! @fields || grep { $key eq $_ } @fields;
   }

   close MEMINFO;
   return $meminfo;
}

# udev
sub udevWalk {
   my $callback = shift;
   open UDEV, '-|', 'udevadm info -q all --export-db';
   my @block;
   while (<UDEV>) {
      if (/\A\n/) {
         my ($name, $device, $stub);

         foreach my $line (@block) {
            chop $line;
            my ($tag, $value) = split /\s*\:\s*/, $line;
               next unless $tag;

               if ($tag eq 'P') {
                  $device = $value;
               }
               elsif ($tag eq 'N') {
                  $name = $value;
               }
               elsif ($tag eq 'E') {
                  my ($k, $v) = split /\=/, $value;
                     $stub->{$k} = $v;
               }
            }

            &$callback($name, $device, $stub);
            splice @block;
      }
      
      push @block, $_;
   }
   close UDEV;
}

# physical disks/partitions & cd
sub getBlockDevInfo {
   my $d_type = shift;
   my @target_types = grep { $d_type ? $d_type eq $_ : 1 } qw[disk cd floppy];
   return undef unless @target_types;

   my $info;
   udevWalk(sub {
      my ($name, $device, $stub) = @_;
      if (exists $stub->{ID_TYPE} && grep { $stub->{ID_TYPE} eq $_ } @target_types) {
         $info->{$name} = {
            device    => $device,
            devname   => $stub->{DEVNAME},
            serial    => $stub->{ID_SERIAL},
            bus       => $stub->{ID_BUS},
            model     => $stub->{ID_MODEL},
            type      => $stub->{DEVTYPE},
            subsystem => $stub->{SUBSYSTEM},
            size      => $stub->{UDISKS_PARTITION_SIZE}
         }
      }
   });

   return $info;
}

# network devices 
sub getNetworkDevInfo {
   my $info;

   udevWalk(sub {
      my ($name, $device, $stub) = @_;
      if (exists $stub->{SUBSYSTEM} && $stub->{SUBSYSTEM} eq 'net') {
         $info->{ $stub->{INTERFACE} } = {
            device    => $device,
            model     => $stub->{ID_MODEL_FROM_DATABASE},
            bus       => $stub->{ID_BUS},
            subsystem => $stub->{SUBSYSTEM}
         };
      }  
   });

   return $info;
}

1;
