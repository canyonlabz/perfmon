#!/usr/bin/perl -w
#
# Copyright:     CanyonLabz, 2018
# Author:        Jason Smallcanyon
# Revision:      $Revision$
# Last Revision: 2009
# Modified By:   Jason Smallcanyon
# Last Modified: $Date: July 16, 2013 $
# Source:        $Source:  $
#
####################################################################################
##
##

package Collector;


use lib qw "./;../";
use Modules::Config;
use Modules::Logger;
use Linux::Statistics;
use strict;
use Data::Dumper;


##############################################################
#                                                            #
# NOTE: List of metrics to capture                           #
#                                                            #
#    "CPU_STATS"       => getCpuMetrics(),                   #
#    "MEMORY_STATS"    => getMemoryMetrics,                  #
#    "DISK_STATS"      => getDiskMetrics(),                  #
#    "NETWORK_STATS"   => getNetworkMetrics(),               #
#    "PAGE_SWAP_STATS" => getPageSwapMetrics(),              #
#    "SOCKET_STATS"    => getSocketMetrics(),                #
#    "FILE_STATS"      => getFileStatsMetrics(),             #
#    "DISK_USAGE"      => getDiskUsageMetrics(),             #
#    "PROCESS_STATS"   => getProcessMetrics(),               #
#    "LOAD_AVG"        => getLoadAvgMetrics()                #
#                                                            #
##############################################################

# -----------------------------------------------------------
# SETTINGS:
# -----------------------------------------------------------

my $DEBUG = 0;

# -----------------------------------------------------------
# FUNCTIONS:
# -----------------------------------------------------------

#
# new() - Object constructor
# Input:  None
# Output: Object for performance metric collection
sub new {

    my $self = {
        "CPUTIME"  => "",             # Init value of the CPU stats (used to calculate %CPU utilization)
        "MEMINFO"  => "",             # Init value of the memory stats (used to calculate process (PID) %memory used)
        "NETSTAT"  => "",             # Init value of the network stats (used to calculate %network utilization)
        "DISKIO"   => "",              # Init value of the disk stats (used to calculate disk I/O Kbytes/sec)
        "INTERVAL" => ""
    };

    bless $self, 'Collector';   # Tag object with pkg name
    return $self;
}

#
# getCpuMetrics() - Capture the CPU metrics and output the results to an array
# Input:
# Output: Array reference to the CPU metrics captured
sub getCpuMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my %statinfo;

    my $stats = $self->load_cpu();   # Returns hash reference
    while (my($key,$value) = each %{$stats}) {
        # Capture our utilization percentages
        my $diff = cpu_time_diff($self->{'CPUTIME'}->{$key}, $value);
        my $perc = cpu_time_perc($diff);
        my $util = 100 - $perc->{'Idle'};
        $util = sprintf("%.2f", $util);

        my @stats_array = (
            $elapsed_time,
            $value->{'User'},
            $value->{'Nice'},
            $value->{'System'},
            $value->{'Idle'},
            $value->{'IOWait'},
            $value->{'IRQ'},
            $value->{'SoftIRQ'},
            $perc->{'User'},
            $perc->{'Nice'},
            $perc->{'System'},
            $perc->{'Idle'},
            $util
        );
        $statinfo{$key} = \@stats_array;
    }

    # Update the CPU time values
    $self->{'CPUTIME'} = $stats;

    return (\%statinfo);
}

#
# getMemoryMetrics() - Capture the memory metrics and output the results to an array
# Input:
# Output: Array reference to the memory metrics captured
sub getMemoryMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my @statinfo;

    my $obj = Linux::Statistics->new( MemStats => 1 );
    my $stats = Linux::Statistics->MemStats();
    @statinfo = (
        $stats->{'MemUsed'},
        $stats->{'MemFree'},
        $stats->{'MemUsedPer'},
        $stats->{'MemTotal'},
        $stats->{'Buffers'},
        $stats->{'Cached'},
        $stats->{'SwapUsed'},
        $stats->{'SwapFree'},
        $stats->{'SwapUsedPer'},
        $stats->{'SwapTotal'}
    );

    unshift(@statinfo,$elapsed_time);

    return (\@statinfo);
}

#
# getDiskMetrics() - Capture the disk metrics and output the results to an array
# Input:
# Output: Array reference to the disk metrics captured
sub getDiskMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my @statinfo;

    my $obj = Linux::Statistics->new( DiskStats => 1 );
    my $stats = Linux::Statistics->DiskStats();

    my $delta = ($stats->{'ReadBytes'} + $stats->{'WriteBytes'}) - ($self->{'DISKIO'}->{'ReadBytes'} + $self->{'DISKIO'}->{'WriteBytes'});
    print "DEBUG>> " . Dumper($self->{'DISKIO'}) . "\n";
    print "DEBUG>> " . ($stats->{'ReadBytes'} + $stats->{'WriteBytes'}) . " --- " . ($self->{'DISKIO'}->{'ReadBytes'} + $self->{'DISKIO'}->{'WriteBytes'}) . " === " . $delta . "\n\n";
    my $diskio = ($delta/1000) / $self->{'INTERVAL'};   ## Kbytes/sec.

    @statinfo = (
        $stats->{'Major'},
        $stats->{'Minor'},
        $stats->{'ReadRequests'},
        $stats->{'ReadBytes'},
        $stats->{'WriteRequests'},
        $stats->{'WriteBytes'},
        ($stats->{'ReadRequests'} + $stats->{'WriteRequests'}),
        ($stats->{'ReadBytes'} + $stats->{'WriteBytes'}),
        $diskio
    );

    unshift(@statinfo,$elapsed_time);

    return (\@statinfo);
}

#
# getNetworkMetrics() - Capture the network metrics and output the results to an array
# Input:
# Output: Hash reference to the network metrics captured per device
sub getNetworkMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my %statinfo;

    my @exclude = qw(lo sit0);   # Network devices to exclude from returning

    my $obj = Linux::Statistics->new( NetStats => 1 );
    my ($net,$sum) = Linux::Statistics->NetStats();

    my $netutil = 0;   ## TODO:  return %network utilization

    DEV: while(my($key,$value) = each %{$net}) {
        foreach my $dev (@exclude) {
            next DEV if ($key eq $dev);
        }
        my @stats_array = (
            $elapsed_time,
            $value->{'RxBytes'},
            $value->{'RxPackets'},
            $value->{'RxErrs'},
            $value->{'RxDrop'},
            $value->{'RxFifo'},
            $value->{'RxFrame'},
            $value->{'RxCompr'},
            $value->{'RxMulti'},
            $value->{'TxBytes'},
            $value->{'TxPackets'},
            $value->{'TxErrs'},
            $value->{'TxDrop'},
            $value->{'TxFifo'},
            $value->{'TxColls'},
            $value->{'TxCarr'},
            $value->{'TxCompr'},
            ($value->{'RxBytes'} + $value->{'TxBytes'}),
            ($value->{'RxPackets'} + $value->{'TxPackets'}),
            $netutil
        );
        $statinfo{$key} = \@stats_array;
    }

    return (\%statinfo);
}

#
# getPageSwapMetrics() - Capture the page swap metrics and output the results to an array
# Input:
# Output: Array reference to the page swap metrics captured
sub getPageSwapMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my @statinfo;

    my $obj = Linux::Statistics->new( PgSwStats => 1 );
    my $stats = Linux::Statistics->PgSwStats();
    @statinfo = (
        $stats->{'PageIn'},
        $stats->{'PageOut'},
        $stats->{'SwapIn'},
        $stats->{'SwapOut'}
    );

    unshift(@statinfo,$elapsed_time);

    return (\@statinfo);
}

#
# getSocketMetrics() - Capture the socket metrics and output the results to an array
# Input:
# Output: Array reference to the socket metrics captured
sub getSocketMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my @statinfo;

    my $obj = Linux::Statistics->new( SockStats => 1 );
    my $stats = Linux::Statistics->SockStats();
    @statinfo = (
        $stats->{'Used'},
        $stats->{'Tcp'},
        $stats->{'Udp'},
        $stats->{'Raw'},
        $stats->{'IpFrag'}
    );

    unshift(@statinfo,$elapsed_time);

    return (\@statinfo);
}

#
# getFileStatsMetrics() - Capture the file stats metrics and output the results to an array
# Input:
# Output: Array reference to the file stats metrics captured
sub getFileStatsMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my @statinfo;

    my $obj = Linux::Statistics->new( FileStats => 1 );
    my $stats = Linux::Statistics->FileStats();
    @statinfo = (
        $stats->{'fhAlloc'},
        $stats->{'fhFree'},
        $stats->{'fhMax'},
        $stats->{'inAlloc'},
        $stats->{'inFree'},
        $stats->{'inMax'},
        $stats->{'Dentries'},
        $stats->{'Unused'},
        $stats->{'AgeLimit'},
        $stats->{'WantPages'}
    );

    unshift(@statinfo,$elapsed_time);

    return (\@statinfo);
}

#
# getDiskUsageMetrics() - Capture the disk usage metrics and output the results to an array
# Input:
# Output: Array reference to the disk usage metrics captured
sub getDiskUsageMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my %statinfo;

    my $obj = Linux::Statistics->new( DiskUsage => 1 );
    my $stats = Linux::Statistics->DiskUsage();

    while (my($key,$value) = each %{$stats}) {
        my @stats_array = (
            $elapsed_time,
            $value->{'Total'},
            $value->{'Usage'},
            $value->{'Free'},
            $value->{'UsagePer'},
            $value->{'MountPoint'}
        );
        $statinfo{$key} = \@stats_array;
    }

    return (\%statinfo);
}

#
# getProcessMetrics() - Capture the given process metrics and output the results to an array
# Input:
# Output: Hash reference to the process metrics captured
sub getProcessMetrics {
    my ($self) = shift;
    my ($item_list, $elapsed_time, $fetch_by_owner) = @_;
    my %statinfo;

    print "DEBUG>> [getProcessMetrics] => Input => Item List \n" if $DEBUG > 1;
    print "DEBUG>> [getProcessMetrics] => " . Dumper($item_list) . "\n" if $DEBUG > 1;

    my $processes;
    if (defined($fetch_by_owner) && $fetch_by_owner =~ m/true/i) {
        $processes = $self->getProcessesByOwner($item_list);
    }
    else {
        $processes = $self->getProcessesByName($item_list);
    }
    my $stats = $self->ProcessesByID($processes);   # Returns hash reference
    while(my($key,$value) = each %{$stats}) {
        # Capture %CPU and %Memory via 'ps' command
        my $cmd = 'ps -p ' . $value->{'Pid'} . ' -o %cpu,%mem,pid,comm --no-heading';
        my $output = `$cmd`;
        $output =~ s/^\s+//;
        $output =~ s/\s+$//;
        my @procstats = split /\s+/, $output;

        # Make sure we have real values
        my $percentMemory = (defined($procstats[1]) && $procstats[1] ne "") ? $procstats[1] : "null";
        my $processMemUsed = (defined($procstats[1]) && $procstats[1] ne "") ? (($self->{'MEMINFO'}->{'Value'} / 100) * $procstats[1]) : "null";

        my @stats_array = (
            $elapsed_time,
            $value->{'PPid'},
            $value->{'Owner'},
            $value->{'State'},
            $value->{'PGrp'},
            $value->{'Session'},
            $value->{'TTYnr'},
            $value->{'MinFLT'},
            $value->{'CMinFLT'},
            $value->{'MayFLT'},
            $value->{'CMayFLT'},
            $value->{'CUTime'},
            $value->{'STime'},
            $value->{'UTime'},
            $value->{'CSTime'},
            $value->{'Prior'},
            $value->{'Nice'},
            $value->{'StartTime'},
            $value->{'ActiveTime'},
            $value->{'VSize'},
            $value->{'NSwap'},
            $value->{'CNSwap'},
            $value->{'CPU'},
            $value->{'Size'},
            $value->{'Resident'},
            $value->{'Share'},
            $value->{'TRS'},
            $value->{'DRS'},
            $value->{'LRS'},
            $value->{'DT'},
            $value->{'Comm'},
            $value->{'CMDLINE'},
            $value->{'Pid'},
            $procstats[0],
            $processMemUsed
        );
        $statinfo{$key} = \@stats_array;
    }

    return (\%statinfo);
}

#
# getLoadAvgMetrics() - Capture the load average metrics and output the results to an array
# Input:
# Output: Array reference to the load average metrics captured
sub getLoadAvgMetrics {
    my ($self) = shift;
    my ($elapsed_time) = shift;
    my @statinfo;

    my $obj = Linux::Statistics->new( LoadAVG => 1 );
    my $stats = Linux::Statistics->LoadAVG();
    @statinfo = (
        $stats->{'AVG_1'},
        $stats->{'AVG_5'},
        $stats->{'AVG_15'},
        $stats->{'RunQueue'},
        $stats->{'Count'}
    );

    unshift(@statinfo,$elapsed_time);

    return (\@statinfo);
}

#
# getSystemInfo() - Capture some basic system information and return the results as a hash reference
# Input:  Nothing
# Output: Hash reference containing some basic system information
sub getSystemInfo {
    # Return info based upon OS
    my $obj = Linux::Statistics->new( SysInfo => 1 );
    my $stats = Linux::Statistics->SysInfo();

    return ($stats);
}

# -----------------------------------------------------------
# PROCESS MGMT FUNCTIONS:
# -----------------------------------------------------------

#
# getProcessesByOwner() - Function that returns a list of PIDs (process IDs) based upon a given process owner name.
# Input:  $process_owner - Array that contains a list of process owners or string with one process owner.
# Output: Hash that contains an array reference to all PIDs for a given process owner(s).
# NOTE:  Process list is defined within the /MyTool/Config/config.xls spreadsheet or /MyTool/Config/config.ini file.
sub getProcessesByOwner {
    my ($self) = shift;
    my ($process_owner) = shift;

    unless (defined($process_owner)) {
        return;
    }

    my @procList;
    if (ref($process_owner) eq 'ARRAY') {
        # We have an array representing multiple owners
        @procList = @$process_owner;
        print "DEBUG>> [getProcessByOwner] => Process owner is an ARRAY \n" if $DEBUG > 1;
    }
    else {
        # We have a string representing a single owner
        $process_owner =~ s/^\s+//;
        $process_owner =~ s/\s+$//;
        $procList[0] = $process_owner;
        print "DEBUG>> [getProcessByOwner] => Process owner is a STRING \n" if $DEBUG > 1;
    }

    print "DEBUG>> [getProcessByOwner] => " . Dumper($process_owner) . "\n" if $DEBUG > 1;

    my %processes;
    foreach my $owner (@procList) {
        my $procOwner = $owner;
        my $cmd = "ps -U '" . $procOwner . "' -o pid=";
        my @output = `$cmd`;
        foreach (@output) {
            $_ =~ s/^\s+//;
            $_ =~ s/\s+$//;
        }
        $processes{$procOwner} = \@output;
    }

    return (\%processes);
}

#
# getProcessesByName() - Function that returns a list of PIDs (process IDs) for each given process.
# Input:  $process_list - Array that contains a list of process names or string with one process name.
# Output: Hash that contains an array reference to all PIDs for a given process name(s).
# NOTE:  Process list is defined within the /MyTool/Config/config.xls spreadsheet or /MyTool/Config/config.ini file.
sub getProcessesByName {
    my ($self) = shift;
    my ($process_list) = shift;

    unless (defined($process_list)) {
        return;
    }

    my @procList;
    if (ref($process_list) eq 'ARRAY') {
        # We have an array representing multiple processes
        @procList = @$process_list;
        print "DEBUG>> [getProcessByName] => Process list is an ARRAY \n" if $DEBUG > 1;
    }
    else {
        # We have a string representing a single process
        $process_list =~ s/^\s+//;
        $process_list =~ s/\s+$//;
        $procList[0] = $process_list;
        print "DEBUG>> [getProcessByName] => Process list is a STRING \n" if $DEBUG > 1;
    }

    print "DEBUG>> [getProcessByName] => " . Dumper($process_list) . "\n" if $DEBUG > 1;

    ## NOTE: While trying to list each process, you just need to list the actual executable name, rather than the whole list of parameters/options.
    ## EXAMPLE:  The following process showing in the "ps" list would show as:  /bin/sh - /usr/lib/vxvm/bin/vxrelocd root
    ##           However, you only need to list the following in the config.ini file:  vxrelocd
    my %processes;
    foreach my $proc (@procList) {
        my $procName = $proc;
        my $cmd = "ps -C '" . $procName . "' -o pid=";
        my @output = `$cmd`;
        foreach (@output) {
            $_ =~ s/^\s+//;
            $_ =~ s/\s+$//;
        }
        $processes{$procName} = \@output;
    }

    return (\%processes);
}

#
# ProcessesByID() - Returns a list of process stats based upon a given process list (PIDs)
# Input:  $procList - Array reference containing a list of all the processes (by name) we want to capture stats for.
# Output:
sub ProcessesByID {
    my ($self) = shift;
    my ($procList) = shift;

    my (%sps,%userids);

    # We parse our process list
    my @prc;
    my %procRef = %$procList;
    foreach my $key (keys %procRef) {
        foreach my $prx ( @{$procRef{$key}} ) {
            push (@prc, $prx);
        }
    }

    # Define the following files
    my $passwd_file = "/etc/passwd";
    my $uptime_file = "/proc/uptime";
    my $procdir     = "/proc";

    # we trying to get the UIDs for each linux user
    open my $fhp, '<', $passwd_file or die "Statistics: can't open $passwd_file";

    while (defined (my $line = <$fhp>)) {
        next if $line =~ /^(#|$)/;
        my ($user,$uid) = (split /:/,$line)[0,2];
        $userids{$uid} = $user;
    }

    close $fhp;

    open my $fhu, '<', $uptime_file or die "Statistics: can't open $uptime_file";
    my $uptime = (split /\s+/, <$fhu>)[0];
    close $fhu;

    foreach my $pid (@prc) {
        #  memory usage for each process
        if (open my $fhm, '<', "$procdir/$pid/statm") {
            @{$sps{$pid}}{qw(Size Resident Share TRS DRS LRS DT)} = split /\s+/, <$fhm>;
            close $fhm;
        } else {
            delete $sps{$pid};
            next;
        }

        #  different other informations for each process
        if (open my $fhp, '<', "$procdir/$pid/stat") {
            @{$sps{$pid}}{qw(
                Pid Comm State PPid PGrp Session TTYnr MinFLT
                CMinFLT MayFLT CMayFLT UTime STime CUTime CSTime
                Prior Nice StartTime VSize NSwap CNSwap CPU
            )} = (split /\s+/, <$fhp>)[0..6,9..18,21..22,35..36,38];
            close $fhp;
        } else {
            delete $sps{$pid};
            next;
        }

        # calculate the active time of each process
        my $s = sprintf('%li',$uptime - $sps{$pid}{StartTime} / 100);
        my $m = 0;
        my $h = 0;
        my $d = 0;

        $s >= 86400 and $d = sprintf('%i',$s / 86400) and $s = $s % 86400;
        $s >= 3600  and $h = sprintf('%i',$s / 3600)  and $s = $s % 3600;
        $s >= 60    and $m = sprintf('%i',$s / 60);

        $sps{$pid}{ActiveTime} = sprintf '%02d:%02d:%02d', $d, $h, $m;

        # determine the owner of the process
        if (open my $fhu, '<', "$procdir/$pid/status") {
            while (defined (my $line = <$fhu>)) {
                $line =~ s/\t/ /;
                next unless $line =~ /^Uid:\s+(\d+)/;
                $sps{$pid}{Owner} = $userids{$1} if $userids{$1};
            }

            $sps{$pid}{Owner} = 'n/a' unless $sps{$pid}{Owner};
            close $fhu;
        } else {
            delete $sps{$pid};
            next;
        }

        #  command line for each process
        if (open my $fhc, '<', "$procdir/$pid/cmdline") {
            $sps{$pid}{CMDLINE} =  <$fhc>;
            $sps{$pid}{CMDLINE} =~ s/\0/ /g if $sps{$pid}{CMDLINE};
            $sps{$pid}{CMDLINE} =  'n/a' unless $sps{$pid}{CMDLINE};
            chomp $sps{$pid}{CMDLINE};
            close $fhc;
        }
    }

    return \%sps;
}

# -----------------------------------------------------------
# %CPU CALCULATION FUNCTIONS:
# -----------------------------------------------------------

#
# load_cpu() - Function that captures the CPU time values from the /proc/stat file and returns them
#              as a hash reference. If multiple processors, it returns all processor CPU time values.
# Input:
# Output: Hash reference containing all processor CPU time values.
sub load_cpu {
    my ($self) = shift;

    my $metric_file = "/proc/stat";

    # Make sure our file exists
    unless (open INFILE, $metric_file) {
        logEvent("[Error]: The metrics file ($metric_file) could not be found.");
        return;
    }
    my @contents = <INFILE>;
    close (INFILE);

    my %cputimes;

    foreach my $line (@contents) {
        if ($line =~ m/^cpu/i) {
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
            # Example:  cpu  801922 3814 243379 67123880 650370 2745 0 0
            my @tmp_array = split(/\s+/,$line);
            $cputimes{$tmp_array[0]} = {
                "User"    => $tmp_array[1],
                "Nice"    => $tmp_array[2],
                "System"  => $tmp_array[3],
                "Idle"    => $tmp_array[4],
                "IOWait"  => $tmp_array[5],
                "IRQ"     => $tmp_array[6],
                "SoftIRQ" => $tmp_array[7]
            };
        }
    }

    return (\%cputimes);
}

#
# cpu_time_diff() - Calculates the delta between a past CPU snapshot and a current CPU snapshot.
# Input:
# Output: Hash reference containing the delta values.
sub cpu_time_diff {
    my($first, $second) = @_;

    my %diff;  # Hash that contains the CPU time differences
    $diff{'User'}    = $second->{'User'} - $first->{'User'};
    $diff{'Nice'}    = $second->{'Nice'} - $first->{'Nice'};
    $diff{'System'}  = $second->{'System'} - $first->{'System'};
    $diff{'Idle'}    = $second->{'Idle'} - $first->{'Idle'};

    return \%diff;
}

#
# cpu_time_perc() - Calculates the percent utilization for each CPU time value.
# Input:
# Output: Hash reference containing the percent values.
sub cpu_time_perc {
    my ($diff) = shift;

    use Math::Round::Var;
    my $rnd = Math::Round::Var->new(0.01);  # rounds to two decimal places:

    my $total = 0;
    $total = $diff->{'User'} + $diff->{'Nice'} + $diff->{'System'} + $diff->{'Idle'};

    my %result;
    $result{'User'}   = $rnd->round( (($diff->{'User'} / $total) * 100) );
    $result{'Nice'}   = $rnd->round( (($diff->{'Nice'} / $total) * 100) );
    $result{'System'} = $rnd->round( (($diff->{'System'} / $total) * 100) );
    $result{'Idle'}   = $rnd->round( (($diff->{'Idle'} / $total) * 100) );

    return \%result;
}

# -----------------------------------------------------------
# INIT FUNCTIONS:
# -----------------------------------------------------------

#
# load_memory() - Function that captures the memory values from the /proc/meminfo file and returns them as a hash reference.
# Input:
# Output: Hash reference containing memory stats.
sub load_memory {
    my ($self) = shift;

    my $metric_file = "/proc/meminfo";

    # Make sure our file exists
    unless (open INFILE, $metric_file) {
        logEvent("[Error]: The metrics file ($metric_file) could not be found.");
        return;
    }
    my @contents = <INFILE>;
    close (INFILE);

    my %retval;

    foreach my $line (@contents) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        # Example:  MemTotal:     65859080 kB
        if ($line =~ m/^memtotal/i) {
            my @tmp_array = split(/\s+/,$line);
            $retval{$tmp_array[0]} = {"Value" => ($tmp_array[1] * 1000), "Unit"  => "Bytes"};
        }
        if ($line =~ m/^memfree/i) {
            my @tmp_array = split(/\s+/,$line);
            $retval{$tmp_array[0]} = {"Value" => ($tmp_array[1] * 1000), "Unit"  => "Bytes"};
        }
        if ($line =~ m/^swaptotal/i) {
            my @tmp_array = split(/\s+/,$line);
            $retval{$tmp_array[0]} = {"Value" => ($tmp_array[1] * 1000), "Unit"  => "Bytes"};
        }
        if ($line =~ m/^swapfree/i) {
            my @tmp_array = split(/\s+/,$line);
            $retval{$tmp_array[0]} = {"Value" => ($tmp_array[1] * 1000), "Unit"  => "Bytes"};
        }
    }

    return (\%retval);
}

#
# load_diskio()
# Input:
# Output:
sub load_diskio {
    my ($self) = shift;
    my %retval;

    my $obj = Linux::Statistics->new( DiskStats => 1 );
    my $stats = Linux::Statistics->DiskStats();

    $retval{'ReadRequests'}  = $stats->{'ReadRequests'};
    $retval{'ReadBytes'}     = $stats->{'ReadBytes'};
    $retval{'WriteRequests'} = $stats->{'WriteRequests'};
    $retval{'WriteBytes'}    = $stats->{'WriteBytes'};

    return (\%retval);
}




1;

__END__
