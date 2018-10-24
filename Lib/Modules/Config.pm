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


package Modules::Config;

use lib qw "..";
use Cwd 'abs_path';
use Config::IniFiles;
use Sys::HostIP;
use strict;

# -----------------------------------------------------------
# FUNCTIONS:
# -----------------------------------------------------------

#
# new() - Object constructor
# Input: - Nothing
# Output - Object for global configurations to environment
sub new {
    my $class = shift;

    # Define the following
    my $base_path = abs_path(".");
	##print "DEBUG: BasePath = $base_path \n\n";
	# If our base path includes "Lib" in the path, then go up 2 folders
	if ($base_path =~ m/perfmon\/Lib/i) {
		##print "DEBUG: Found 'Lib' in BasePath... Removing...\n\n";
		$base_path =~ s/\/Lib\/(.*)$//i;
		##print "DEBUG: New BasePath: $base_path \n\n"
	}
    my $config_path = $base_path."/Config/";
	my $results_path = $base_path."/Results/";

    # Fetch our configuration INI values
    my $config_ini = $config_path."perfmon_config.ini";
	##print "DEBUG: ConfigIni = $config_ini \n\n";
    my $cfg = new Config::IniFiles( -file => $config_ini );

	# Define our node to be monitored IP address
	my $LOCAL_HOST;
	if (defined parseValue( $cfg->val( 'PERFMON', 'NODE_IP_ADDRESS' ) ) && parseValue( $cfg->val( 'PERFMON', 'NODE_IP_ADDRESS' ) ) ne "") {
		$LOCAL_HOST = parseValue( $cfg->val( 'PERFMON', 'NODE_IP_ADDRESS' ) );
	}
	else {
		$LOCAL_HOST = hostip();   ## TODO: Address multi-nic machines
	}

	# Define our node to be monitored hostname
	my $LOCAL_HOSTNAME;
	if (defined parseValue( $cfg->val( 'PERFMON', 'NODE_HOSTNAME' ) ) && parseValue( $cfg->val( 'PERFMON', 'NODE_HOSTNAME' ) ) ne "") {
		$LOCAL_HOSTNAME = parseValue( $cfg->val( 'PERFMON', 'NODE_HOSTNAME' ) );
	}
	else {
		$LOCAL_HOSTNAME = `hostname`; # default
		$LOCAL_HOSTNAME = parseValue($LOCAL_HOSTNAME);
	}
	#print "DEBUG: local hostname = [$LOCAL_HOSTNAME] \n\n";

    # Fetch a list of processes to monitor
    my @processes = ();
    if (exists $cfg->{'v'}->{'PERFMON_METRICS'}->{'PROCESS_LIST'}) {
        my $procs = $cfg->{'v'}->{'PERFMON_METRICS'}->{'PROCESS_LIST'};
        if (ref($procs) eq "ARRAY") {
            push (@processes, @$procs);
        }
        else {
            push (@processes, $procs);
        }
    }
    my @process_owners = ();
    if (exists $cfg->{'v'}->{'PERFMON_METRICS'}->{'PROCESS_OWNER'}) {
        my $proc_owners = $cfg->{'v'}->{'PERFMON_METRICS'}->{'PROCESS_OWNER'};
        if (ref($proc_owners) eq 'ARRAY') {
            push (@process_owners, @$proc_owners);
        }
        else {
            push (@process_owners, $proc_owners);
        }
    }

    my $self = {
		"BASE_PATH"			    => $base_path,
        "CONFIG_PATH"           => $config_path,
		"RESULTS_PATH"			=> $results_path,
		"EVENT_LOG"             => $base_path."/Logs/event_" . $LOCAL_HOSTNAME . "_log.txt",
        "DEBUG"                 => parseValue( $cfg->val( 'GLOBAL', 'DEBUG' ) ),                  # Debugging mode (1=on / 0=off)
        "VERBOSE"               => parseValue( $cfg->val( 'GLOBAL', 'VERBOSE' ) ),                # Verbose mode (1=on / 0=off)
        "LOG"                   => parseValue( $cfg->val( 'GLOBAL', 'LOG' ) ),                    # Logging mode (1=on / 0=off)
		"CONTROLLER_HOSTNAME"   => parseValue( $cfg->val( 'CONTROLLER', 'HOSTNAME' ) ),
		"CONTROLLER_IP_ADDRESS" => parseValue( $cfg->val( 'CONTROLLER', 'IP_ADDRESS' ) ),
		"NODE_HOSTNAME"         => $LOCAL_HOSTNAME,
		"NODE_IP_ADDRESS"       => $LOCAL_HOST,
		"MONITOR_INTERVAL"		=> parseValue( $cfg->val( 'PERFMON', 'MONITOR_INTERVAL') ),
		"MONITOR_DURATION_SECS" => parseValue( $cfg->val( 'PERFMON', 'MONITOR_DURATION_SECS' ) ),
        "CPU_STATS"             => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'CPU_STATS' ) ),             # Processor statistics (1=on / 0=off)
            "FILE"              => "cpustat.csv",
            "PERFOBJ"           => "cpustat"
        },
        "MEMORY_STATS"          => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'MEMORY_STATS' ) ),          # Memory statistics (1=on / 0=off)
            "FILE"              => "memory.csv",
            "PERFOBJ"           => "memory"
        },
        "PAGE_SWAP_STATS"       => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'PAGE_SWAP_STATS' ) ),       # Page/Swap statistics (1=on / 0=off)
            "FILE"              => "pageswap.csv",
            "PERFOBJ"           => "pageswap"
        },
        "NETWORK_STATS"         => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'NETWORK_STATS' ) ),         # Network statistics (1=on / 0=off)
            "FILE"              => "network.csv",
            "PERFOBJ"           => "network"
        },
        "SOCKET_STATS"          => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'SOCKET_STATS' ) ),          # Socket statistics (1=on / 0=off)
            "FILE"              => "socket.csv",
            "PERFOBJ"           => "socket"
        },
        "DISK_STATS"            => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'DISK_STATS' ) ),            # Disk statistics (1=on / 0=off)
            "FILE"              => "disk.csv",
            "PERFOBJ"           => "disk"
        },
        "DISK_USAGE"            => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'DISK_USAGE' ) ),            # Disk usage statistics (1=on / 0=off)
            "FILE"              => "diskusage.csv",
            "PERFOBJ"           => "diskusage"
        },
        "LOAD_AVG"              => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'LOAD_AVG' ) ),              # Load average statistics (1=on / 0=off)
            "FILE"              => "loadavg.csv",
            "PERFOBJ"           => "loadavg"
        },
        "FILE_STATS"            => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'FILE_STATS' ) ),            # File statistics (1=on / 0=off)
            "FILE"              => "filestat.csv",
            "PERFOBJ"           => "filestat"
        },
        "PROCESSES"             => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'PROCESSES' ) ),             # Process statistics (1=on / 0=off)
            "FILE"              => "process.csv",
            "PERFOBJ"           => "process",
            "LIST"              => \@processes                                                    # List of processes to capture metrics for.
        },
        "PROCESS_UTIL"          => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'PROCESS_UTIL' ) ),          # Process utilization statistics (1=on / 0=off)
            "FILE"              => "utilization.csv",
            "PERFOBJ"           => "utilization",
            "LIST"              => \@processes                                                    # List of processes to capture utilization statistics for.
        },
        "PROCESS_OWNERS"        => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'PROCESSES_BY_OWNER' ) ),
            "FILE"              => "proc_user.csv",
            "PERFOBJ"           => "proc_user",
            "LIST"              => \@process_owners
        },
        "PROCESS_UTIL_OWNERS"   => {
            "COLLECT"           => parseValue( $cfg->val( 'PERFMON_METRICS', 'PROCESS_UTIL_BY_OWNER' ) ),
            "FILE"              => "procutil_user.csv",
            "PERFOBJ"           => "procutil_user",
            "LIST"              => \@process_owners
        },
        "SYSTEM_INFO"           => {                                                              # System information (1=on / 0=off)
            "COLLECT"           => 0,
            "PERFOBJ"           => "sysinfo",
            "FILE"              => "sysinfo.csv"
        },
    };

    bless $self, $class;   # Tag object with pkg name
    return $self;
}

#
# parseValue() - Function that parses the given string for a set of meta-characters.
# Input:  $var - String containing the value to parse.
# Output: Returns the parsed string value.
sub parseValue {
    my $var = shift;

    unless (defined($var)) {
        return;
    }

    $var =~ s/"//g;
    $var =~ s/^\s+//;
    $var =~ s/\s+$//;
	$var =~ s/\n+$//;
	$var =~ s/\r+$//;

    return $var;
}


1;

__END__
