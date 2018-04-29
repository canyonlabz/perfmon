#!/usr/bin/perl -w
#
# Copyright:     Jason Smallcanyon, 2011
# Author:        Jason Smallcanyon
# Revision:      $Revision$
# Last Revision: $Date$
# Modified By:   $ Jason Smallcanyon $
# Last Modified: $ 06/09/2015 $
# Source:        $URL$
#
####################################################################################
##
##


package Perfmon::Monitor;

use lib qw "..";
use Modules::Config;
use Modules::Logger;
use Perfmon::IO;
use vars qw($METRICS);
use strict;
use Data::Dumper;


# -----------------------------------------------------------
# SETTINGS:
# -----------------------------------------------------------

SWITCH: {
    if ($^O =~ m/linux/i) {
        require Perfmon::Linux::Counters;
        require Perfmon::Linux::Collector;
        last SWITCH;
    }
    #elsif ($^O =~ m/solaris/i) {
    #    require Perfmon::Solaris::Counters;
    #    require Perfmon::Solaris::Collector;
    #    last SWITCH;
    #}
    elsif ($^O =~ m/Win|NT/i) {   # Windows
        require Perfmon::Windows::Counters;
        require Perfmon::Windows::Collector;
        last SWITCH;
    }
	else {
		print "[ERROR]: Your operating system wasn't recognized: [$^O]\n";
	}
    ##exit;
}

my $COLLECTOR = Collector::new();

my $IO = new Perfmon::IO();

my $METRICS = { 
    "CPU_STATS"       => getCpuCounters(),
    "MEMORY_STATS"    => getMemoryCounters(),
    "DISK_STATS"      => getDiskCounters(),
    "NETWORK_STATS"   => getNetworkCounters(),
    "PAGE_SWAP_STATS" => getPageSwapCounters(),
    "SOCKET_STATS"    => getSocketCounters(),
    "FILE_STATS"      => getFileStatCounters(),
    "DISK_USAGE"      => getDiskUsageCounters(),
    "PROCESS_STATS"   => getProcessCounters(),
    "LOAD_AVG"        => getLoadAvgCounters()
};

# ------------------------------------------------------------------------------
# MAIN FUNCTIONS:
# ------------------------------------------------------------------------------

#
# new() - Object constructor
# Input:  None
# Output: Object for performance monitoring
sub new {
    my $class = shift;
	
	my $CONFIG = new Modules::Config();
	
    my $self = {
        "METRICS"      => $METRICS,
        "SESSION_ID"   => time(),         # This is the directory of where the results are stored
        "SYSINFO"      => $COLLECTOR->getSystemInfo(),
        "INTERVAL"     => "",
        "CPUTIME"      => "",             # Init value of the CPU stats (used to calculate %CPU utilization)
        "MEMINFO"      => "",             # Init value of the memory stats (used to calculate process (PID) %memory used)
        "NETSTAT"      => "",             # Init value of the network stats (used to calculate %network utilization)
        "DISKIO"       => "",              # Init value of the disk stats (used to calculate disk I/O Kbytes/sec)
		"RESULTS_PATH" => $CONFIG->{'RESULTS_PATH'}
    };
    
    bless $self, $class;   # Tag object with pkg name
    return $self;
}

#
# recordMetrics() - Record the performance metrics to the results file
# Input:  $perfobj - String containing the performance object name of the metrics to record.
#         $content  - String or hash reference containing the performance metrics to record
#         $headings - Array reference containing a list of the performance counter names
# Output: Returns 1 if our file was successfully written, or undef on failure
sub recordMetrics {
    my($self) = shift;
    my($perfobj, $content, $headings) = @_;
    
    # Define the following
    my $resultsPath = $self->{'RESULTS_PATH'};
    my $resultsDir  = $resultsPath . $self->{'SESSION_ID'} . ( ($^O =~ /MSWin32/) ? "\\" : "/" );
    my $resultsFile = $resultsDir . $perfobj;
    
    my $rv;
    unless (-d $resultsDir) {
        $rv = $self->createResultsDir($self->{'SESSION_ID'});
    }
    
    # If our data type is a hash reference then we are dealing with performance objects with multiple instances (i.e. multiple NICs, multiple processors, etc.)
    my $retval = 0;
    if (ref($content) eq 'HASH') {
        if ($perfobj =~ m/(network|cpustat)/i) {
            $retval = $IO->writeMetricsPerInstance($content, $resultsFile, $headings);
        }
        elsif ($perfobj =~ m/(proc_user|process)/i) {
            $retval = $IO->writeMetricsPerProcess($content, $resultsFile, $headings, "30");
        }
        else {
            # Do nothing
        }
        if ($retval < 0) { return $retval; }
    }
    else {
        $retval = $IO->writeMetricsToFile($content, $resultsFile, $headings);
    }
    
    return 1;
}

#
# createResultsDir() - Create the directory where our results will be placed
# Input:  $session_id - The name of the folder where our current test run results will be stored (represents UNIX timestamp)
# Output: Returns zero on success or undef on failure
sub createResultsDir {
    my($self) = shift;
    my($session_id) = @_;
    
    # Make sure we have a valid session ID value
    unless (defined($session_id) && $session_id ne "") {
        print "ERROR: Did not receive a session ID value for createResultsDir().\n";
        exit;
    }
    
    my $resultsPath = $self->{'RESULTS_PATH'};
    my $resultsDir = $resultsPath . $session_id . ( ($^O =~ /MSWin32/) ? "\\" : "/" );
    
    # Check if our directory already exists
    if (-d $resultsDir) {
        return;
    }
    
    # Make sure we remember where we are
    use Cwd;
    my $oldPath = cwd;
    if ($^O =~ /MSWin32/) {
        $oldPath =~ s/\//\\/g;
    }
    
    # Change into the directory where our results exist
    chdir($resultsPath) || die "Cannot chdir to: $resultsPath ($!) \n";
    
    # Define our current path
    my $currentPath = cwd;
    if ($^O =~ /MSWin32/) {
        $currentPath =~ s/\//\\/g;
    }
    
    # Create our directory
    mkdir($session_id,0777) || die "Cannot mkdir [$session_id]: $! \n";
    
    # Change back to old path when we finish, so relative paths continue to make sense
    chdir($oldPath);
    
    return 1;
}

# ------------------------------------------------------------------------------
# COLLECTOR FUNCTIONS:
# ------------------------------------------------------------------------------

#
# getCpuMetrics() - 
# Input:
# Output:
sub getCpuMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getCpuMetrics($elapsedTime);
    return $retval;
}

#
# getMemoryMetrics() - 
# Input:
# Output:
sub getMemoryMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getMemoryMetrics($elapsedTime);
    return $retval;
}

#
# getDiskMetrics() -
# Input:
# Output:
sub getDiskMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    $COLLECTOR->{'INTERVAL'} = $self->{'INTERVAL'};
    my $retval = $COLLECTOR->getDiskMetrics($elapsedTime);
    return $retval;
}

#
# getNetworkMetrics() -
# Input:
# Output:
sub getNetworkMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getNetworkMetrics($elapsedTime);
    return $retval;
}

#
# getPageSwapMetrics() -
# Input:
# Output:
sub getPageSwapMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getPageSwapMetrics($elapsedTime);
    return $retval;
}

#
# getSocketMetrics() -
# Input:
# Output:
sub getSocketMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getSocketMetrics($elapsedTime);
    return $retval;
}

#
# getFileStatsMetrics() -
# Input:
# Output:
sub getFileStatsMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getFileStatsMetrics($elapsedTime);
    return $retval;
}

#
# getDiskUsageMetrics() -
# Input:
# Output;
sub getDiskUsageMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getDiskUsageMetrics($elapsedTime);
    return $retval;
}

#
# getProcessMetrics() -
# Input:
# Output:
sub getProcessMetrics {
    my $self = shift;
    my($itemList, $elapsedTime, $fetchByOwner) = @_;
    my $retval = $COLLECTOR->getProcessMetrics($itemList,$elapsedTime,$fetchByOwner);
    return $retval;
}

#
# getLoadAvgMetrics() -
# Input:
# Output:
sub getLoadAvgMetrics {
    my $self = shift;
    my $elapsedTime = shift;
    my $retval = $COLLECTOR->getLoadAvgMetrics($elapsedTime);
    return $retval;
}

# ------------------------------------------------------------------------------
# INIT FUNCTIONS:
# ------------------------------------------------------------------------------

#
# init_cpu() - Returns CPU time values that will be used as the first delta in rates/ratio calculations.
# Input:
# Output:
sub init_cpu {
    my $self = shift;
    my $retval = $COLLECTOR->load_cpu;
    $COLLECTOR->{'CPUTIME'} = $retval;
    return $retval;
}

#
# init_memory() - Returns memory stat values that will be used as the first delta in rates/ratio calculations.
# Input:
# Output:
sub init_memory {
    my $self = shift;
    my $retval = $COLLECTOR->load_memory;
    $COLLECTOR->{'MEMINFO'} = $retval;
    return $retval;
}

#
# init_diskio() - Returns disk stat values that will be used as the first delta in rates/ratios calculations.
# Input:
# Output:
sub init_diskio {
    my $self = shift;
    my $retval = $COLLECTOR->load_diskio;
    $COLLECTOR->{'DISKIO'} = $retval;
    return $retval;
}



1;

__END__
