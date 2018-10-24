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


package Perfmon::Windows::Counters;

use lib qw "../../";
use strict;


##############################################################
#                                                            #
# NOTE: List of counters to capture                          #
#                                                            #
#    "CPU_STATS"       => getCpuCounters(),                  #
#    "MEMORY_STATS"    => getMemoryCounters(),               #
#    "DISK_STATS"      => getDiskCounters(),                 #
#    "NETWORK_STATS"   => getNetworkCounters(),              #
#    "PAGE_SWAP_STATS" => getPageSwapCounters(),             #
#    "SOCKET_STATS"    => getSocketCounters(),               #
#    "FILE_STATS"      => getFileStatCounters(),             #
#    "DISK_USAGE"      => getDiskUsageCounters(),            #
#    "PROCESS_STATS"   => getProcessCounters(),              #
#    "LOAD_AVG"        => getLoadAvgCounters()               #
#                                                            #
##############################################################

# -----------------------------------------------------------
# SETTINGS:
# -----------------------------------------------------------

# Export our variables
our @ISA = qw(Exporter);

our @EXPORT = qw(getCpuCounters getMemoryCounters getDiskCounters getNetworkCounters
				 getPageSwapCounters getSocketCounters getFileStatCounters getDiskUsageCounters
				 getProcessCounters getLoadAvgCounters);     # Symbols to export by default

# -----------------------------------------------------------
# FUNCTIONS:
# -----------------------------------------------------------


#
# getCpuCounters() - Returns a set of Windows CPU performance metrics.
# Input:
# Output:
sub getCpuCounters {
    my $counters = [
        "Elapsed Time",
		"Processor(_Total)\\\% Idle Time",
		"Processor(_Total)\\\% Privileged Time",
		"Processor(_Total)\\\% User Time",
		"Processor(_Total)\\\% DPC Time",
		"Processor(_Total)\\\% Interrupt Time",
		"Processor(_Total)\\Interrupts/sec"
    ];

    return ($counters);
}

#
# getMemoryCounters() - Returns a set of Windows memory performance metrics.
# Input:
# Output:
sub getMemoryCounters {
    my $counters = [
        "Elapsed Time",
		"Memory\\Available Bytes",
		"Memory\\Cache Bytes",
		"Memory\\Committed Bytes",
		"Memory\\\% Committed Bytes in Use",
		"Memory\\Commit Limit"
    ];

    return ($counters);
}

#
# getDiskCounters() - Returns a set of Windows physical disk performance metrics.
# Input:
# Output:
sub getDiskCounters {
    my $counters = [
        "Elapsed Time",
		"Physical Disk(_Total)\\Current Disk Queue Length",
		"Physical Disk(_Total)\\Disk Bytes/sec",
		"Physical Disk(_Total)\\Disk Read Bytes/sec",
		"Physical Disk(_Total)\\Disk Write Bytes/sec",
		"Physical Disk(_Total)\\Avg. Disk Bytes/Read",
		"Physical Disk(_Total)\\Avg. Disk Bytes/Write",
		"Physical Disk(_Total)\\Avg. Disk Queue Length",
		"Physical Disk(_Total)\\Avg. Disk sec/Read",
		"Physical Disk(_Total)\\Avg. Disk sec/Write"
    ];

    return ($counters);
}

#
# getNetworkCounters() - Returns a set of Windows network (NIC) performance metrics.
# Input:
# Output:
# NOTE: Need to identify how to capture the correct NIC (i.e. Ethernet, wireless, etc.)
sub getNetworkCounters {
    my $counters = [
        "Elapsed Time",
		"Network Interface(_All)\\Bytes Received/sec",
		"Network Interface(_All)\\Bytes Sent/sec",
		"Network Interface(_All)\\Bytes Total/sec",
		"Network Interface(_All)\\Current Bandwidth",
		"Network Interface(_All)\\Packets Received/sec",
		"Network Interface(_All)\\Packets Sent/sec",
		"Network Interface(_All)\\Packets/sec",
		"Network Interface(_All)\\Packets Outbound Errors",
		"Network Interface(_All)\\Packets Received Errors"
    ];

    return ($counters);
}

#
# getPageSwapCounters() - Returns a set of Windows paging performance metrics.
# Input:
# Output:
sub getPageSwapCounters {
    my $counters = [
        "Elapsed Time",
		"Memory\\Page Writes/sec",
		"Memory\\Page Reads/sec",
		"Memory\\Page Faults/sec",
		"Memory\\Pages Input/sec",
		"Memory\\Pages Output/sec",
		"Memory\\Pages/sec",
		"Memory\\Pool Paged Bytes",
		"Memory\\Pool Nonpaged Bytes"
    ];

    return ($counters);
}

#
# getSocketCounters() - Returns a set of TCPv4/UDPv4 (connections/datagrams) Windows performance metrics.
# Input:
# Output:
sub getSocketCounters {
    my $counters = [
        "Elapsed Time",
		"TCPv4\\Connection Failures",
		"TCPv4\\Connections Active",
		"TCPv4\\Connections Established",
		"TCPv4\\Connections Passive",
		"TCPv4\\Connections Reset",
		"UDPv4\\Datagrams No Port/sec.",
		"UDPv4\\Datagrams Received Errors",
		"UDPv4\\Datagrams Received/sec",
		"UDPv4\\Datagrams Sent/sec",
		"UDPv4\\Datagrams/sec",
    ];

    return ($counters);
}

#
# getFileStatCounters() - Returns a set of file performance statistics.
# Input:
# Output:
sub getFileStatCounters {
    my $counters = [
        "Elapsed Time",
		"System\\File Control Bytes/Sec",
		"System\\File Control Ops/Sec",
		"System\\File Data Ops/Sec",
		"System\\File Read Bytes/Sec",
		"System\\File Read Ops/Sec",
		"System\\File Write Bytes/Sec",
		"System\\File Write Ops/Sec"
    ];

    return ($counters);
}

#
# getDiskUsageCounters() - Returns a set of Windows disk usage performance metrics.
# Input:
# Output:
sub getDiskUsageCounters {
    my $counters = [
        "Elapsed Time",
		"Logical Disk(_Total)\\\% Free Space",
		"Logical Disk(_Total)\\Size",
		"Logical Disk(_Total)\\Free Megabytes"
    ];

    return ($counters);
}

#
# getLoadAvgCounters() - Returns a set of Windows CPU load statistics.
# Input:
# Output:
# NOTE:  Uses Win32_Processor
sub getLoadAvgCounters {
    my $counters = [
        "Elapsed Time",
		"System\\Processes",
		"System\\Process Queue Length",
		"System\\Threads",
		"Processor(_Total)\\\% Processor Time",
		"Processor\\\# of Cores",
		"Processor\\\# of Logical Processors",
		"Processor\\Load Percentage"
    ];

    return ($counters);
}

#
# getProcessCounters() -
# Input:
# Output:
sub getProcessCounters {
    my $counters = [
        "Elapsed Time",
        "PPid",
        "Owner",
        "State",
        "PGrp",
        "Session",
        "TTYnr",
        "MinFLT",
        "CMinFLT",
        "MayFLT",
        "CMayFLT",
        "CUTime",
        "STime",
        "UTime",
        "CSTime",
        "Prior",
        "Nice",
        "StartTime",
        "ActiveTime",
        "VSize",
        "NSwap",
        "CNSwap",
        "CPU",
        "Size",
        "Resident",
        "Share",
        "TRS",
        "DRS",
        "LRS",
        "DT",
        "Comm",
        "CMDLINE",
        "Pid"
    ];

    return ($counters);
}

#
# getProcessUtilCounters() -
# Input:
# Output:
sub getProcessUtilCounters {
    my $counters = [
        "Elapsed Time",
        "\%CPU Utilization",
        "\%Memory Utilization",
        "PID",
        "Command",
        "Process Memory Used",
        "Memory Used",
        "Memory Free",
        "\%Memory Used",
        "Memory Total",
        "Buffers",
        "Cached",
        "Swap Used",
        "Swap Free",
        "\%Swap Used",
        "Swap Total"
    ];

    return ($counters);
}


1;

__END__
