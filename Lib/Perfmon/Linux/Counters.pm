#!/usr/bin/perl -w
#
# Copyright:     AppLabs Inc, 2010
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


use lib qw "../../";
use Modules::Config;
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
# FUNCTIONS:
# -----------------------------------------------------------

#
# getCpuCounters() - Return array reference listing all CPU counters.
# Input:  
# Output: 
sub getCpuCounters {
    my $counters = [
        "Elapsed Time",
        "User",
        "Nice",
        "System",
        "Idle",
        "IOWait",
        "IRQ",
        "SoftIRQ",
        "\%User",
        "\%Nice",
        "\%System",
        "\%Idle",
        "\%CPU Utilization"
    ];
    return ($counters);
}

#
# getMemoryCounters() - Return array reference listing all memory counters.
# Input:  
# Output: 
sub getMemoryCounters { 
    my $counters = [
        "Elapsed Time",
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

#
# getDiskCounters() - Return array reference listing all physical disk counters.
# Input: 
# Output:
sub getDiskCounters {
    my $counters = [
        "Elapsed Time",
        "Major",
        "Minor",
        "ReadRequests",
        "ReadBytes",
        "WriteRequests",
        "WriteBytes",
        "TotalRequests",
        "TotalBytes",
        "Disk I/O"
    ];
    return ($counters);
}

#
# getNetworkCounters() - Return array reference listing all network counters.
# Input: 
# Output: 
sub getNetworkCounters {
    my $counters = [
        "Elapsed Time",
        "RxBytes",
        "RxPackets",
        "RxErrs",
        "RxDrop",
        "RxFifo",
        "RxFrame",
        "RxCompr",
        "RxMulti",
        "TxBytes",
        "TxPackets",
        "TxErrs",
        "TxDrop",
        "TxFifo",
        "TxColls",
        "TxCarr",
        "TxCompr",
        "TotalBytes",
        "TotalPackets",
        "\%Network Utilization"
    ];
    return ($counters);
}

#
# getPageSwapCounters() - Return array reference listing all page/swap counters.
# Input:
# Output: 
sub getPageSwapCounters {
    my $counters = [
        "Elapsed Time",
        "PageIn",
        "PageOut",
        "SwapIn",
        "SwapOut"
    ];
    return ($counters);
}

#
# getSocketCounters() - Return array reference listing all socket counters.
# Input: 
# Output:
sub getSocketCounters {
    my $counters = [
        "Elapsed Time",
        "Used",
        "Tcp",
        "Udp",
        "Raw",
        "IpFrag"
    ];
    return ($counters);
}

#
# getFileStatCounters() - Return array reference listing all file statistic counters.
# Input: 
# Output: 
sub getFileStatCounters {
    my $counters = [
        "Elapsed Time",
        "fhAlloc",
        "fhFree",
        "fhMax",
        "inAlloc",
        "inFree",
        "inMax",
        "Dentries",
        "Unused",
        "AgeLimit",
        "WantPages"
    ];
    return ($counters);
}

#
# getDiskUsageCounters() - Return array reference listing all disk usage counters.
# Input: 
# Output: 
sub getDiskUsageCounters {
    my $counters = [
        "Elapsed Time",
        "Total",
        "Usage",
        "Free",
        "UsagePer",
        "MountPoint"
    ];
    return ($counters);
}

#
# getProcessCounters() - Return array reference listing all process counters.
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
        "Pid",
        "\%CPU",
        "\%Memory",
    ];
    return ($counters);
}

#
# getLoadAvgCounters() - Return array reference listing all load average counters.
# Input: 
# Output: 
sub getLoadAvgCounters {
    my $counters = [
        "Elapsed Time",
        "AVG_1",
        "AVG_5",
        "AVG_15",
        "RunQueue",
        "Count"
    ];
    return ($counters);
}



1;

__END__
