#!/usr/bin/perl -w
#
# Copyright:     Jason Smallcanyon, 2015
# Author:        Jason Smallcanyon
# Revision:      $Revision$
# Last Revision: $Date$
# Modified By:   $LastChangedBy$
# Last Modified: $LastChangedDate$
# Source:        $URL$
#
####################################################################################
##
##

BEGIN {
    push @INC, "../Library/Perl-Lib";
    push @INC, "../Library/Perl-Lib/Modules";
}

use Modules::Config;
use Modules::Logger;
use Perfmon::Monitor;
use Perfmon::IO;
use Getopt::Long;
use Pod::Usage;
use Tie::Hash;
use strict;
use Data::Dumper;


# -----------------------------------------------------------
# SETTINGS:
# -----------------------------------------------------------

# Fetch our global configuration information
my $CONFIG = Config::new();

# Create our performance monitor
my $MONITOR = Monitor::new();

# Create our output object
my $IO = IO::new();

# -----------------------------------------------------------
# FUNCTIONS:
# -----------------------------------------------------------

sub INT_handler {
    # Send error message to log file
    print "\n[" . $MONITOR->{'SESSION_ID'} . "]: Performance Monitor is stopping....\n";
    logEvent("[" . $MONITOR->{'SESSION_ID'} . "]: Performance Monitor is stopping....");
    exit(0);
}

$SIG{'INT'} = 'INT_handler';

# -----------------------------------------------------------
# MAIN:
# -----------------------------------------------------------

print "The MyTool Performance Monitor is starting on []....\n" if ($CONFIG->{'VERBOSE'} > 1);
logHistory("[" . $MONITOR->{'SESSION_ID'} . "]: Performance Monitor is starting....");


# -----------------------------------------------------------
# Initializers - Values to capture to calculate rates & ratios
#
$MONITOR->{'INTERVAL'} = $CONFIG->{'INTERVAL'};

# If we need to capture CPU times for any processor(s), capture our initial values.
$MONITOR->{'CPUTIME'} = $MONITOR->init_cpu();

# Capture our total memory available (used for process calculations)
$MONITOR->{'MEMINFO'} = $MONITOR->init_memory();

# Capture our disk I/O stats (used to calculate disk I/O Kbytes/sec)
$MONITOR->{'DISKIO'} = $MONITOR->init_diskio();

# Need to add in some buffer time before we start capturing our metrics
sleep(5);

# -----------------------------------------------------------

# Capture the start time
my $startTime = time();
my $currentTime = 0;
my $elapsedTime = 0;
my $lastTimeValue = 0;
my $elapsed;

# We enter a never ending loop till we are given a 'Ctrl-C' value, then we exit gracefully
PERFMON: while ($elapsedTime <= $CONFIG->{'TEST_TIME_LENGTH'}) {
    print "Performance monitor on [localhost]: running....\n" if ($CONFIG->{'VERBOSE'} > 1);
    print "Elapsed Time (secs): $elapsedTime \n" if ($CONFIG->{'VERBOSE'} > 1);
    
    # Collect the CPU metrics
    if ($CONFIG->{'CPU_STATS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getCpuMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'CPU_STATS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'CPU_STATS'});
    }
    
    # Collect the Memory metrics
    if ($CONFIG->{'MEMORY_STATS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getMemoryMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'MEMORY_STATS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'MEMORY_STATS'});
    }
    
    # Collect the Disk metrics
    if ($CONFIG->{'DISK_STATS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getDiskMetrics($elapsedTime);
        ## NOTE: @info returns elapsed time as first cell value.
        $MONITOR->{'DISKIO'}->{'ReadRequests'}  = @$info[3];
        $MONITOR->{'DISKIO'}->{'ReadBytes'}     = @$info[4];
        $MONITOR->{'DISKIO'}->{'WriteRequests'} = @$info[5];
        $MONITOR->{'DISKIO'}->{'WriteBytes'}    = @$info[6];
        
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'DISK_STATS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'DISK_STATS'});
    }
        
    # Collect the Network metrics
    if ($CONFIG->{'NETWORK_STATS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getNetworkMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'NETWORK_STATS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'NETWORK_STATS'});
    }
    
    # Collect the Page Swap metrics
    if ($CONFIG->{'PAGE_SWAP_STATS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getPageSwapMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'PAGE_SWAP_STATS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'PAGE_SWAP_STATS'});
    }
    
    # Collect the Socket metrics
    if ($CONFIG->{'SOCKET_STATS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getSocketMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'SOCKET_STATS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'SOCKET_STATS'});
    }
    
    # Collect the File Stats metrics
    if ($CONFIG->{'FILE_STATS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getFileStatsMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'FILE_STATS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'FILE_STATS'});
    }
    
    # Collect the Disk Usage metrics
    if ($CONFIG->{'DISK_USAGE'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getDiskUsageMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'DISK_USAGE'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'DISK_USAGE'});
    }
    
    # Collect the Process metrics
    if ($CONFIG->{'PROCESSES'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getProcessMetrics($CONFIG->{'PROCESSES'}->{'LIST'},$elapsedTime,"FALSE");
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'PROCESSES'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'PROCESSES'});
    }
    
    # Collect the Process metrics based upon a given process owner(s)
    if ($CONFIG->{'PROCESS_OWNERS'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getProcessMetrics($CONFIG->{'PROCESS_OWNERS'}->{'LIST'},$elapsedTime,"TRUE");
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'PROCESS_OWNERS'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'PROCESSES'});
    }

    # Collect the Load Average metrics
    if ($CONFIG->{'LOAD_AVG'}->{'COLLECT'} == 1) {
        my $info   = $MONITOR->getLoadAvgMetrics($elapsedTime);
        my $stdout = $IO->formatMetrics($info);
        my $retval = $MONITOR->recordMetrics($CONFIG->{'LOAD_AVG'}->{'PERFOBJ'}, $stdout, $MONITOR->{'METRICS'}->{'LOAD_AVG'});
    }
            
    sleep $CONFIG->{'INTERVAL'};
    
    # Calculate our elapsed time values
    $currentTime = time();
    if ($elapsedTime == 0) {
        $elapsed = $currentTime - $startTime
    }
    else {
        $elapsed = $currentTime - $lastTimeValue;
    }
    $elapsedTime += $elapsed;
    $lastTimeValue = $currentTime;
    
    last PERFMON if ($elapsedTime > $CONFIG->{'TEST_TIME_LENGTH'});
    
    redo PERFMON;
}

print "The MyTool Performance Monitor is stopping.\n\n" if ($CONFIG->{'VERBOSE'} > 1);
logHistory("[" . $MONITOR->{'SESSION_ID'} . "]: Performance Monitor is stopping....");


__END__
