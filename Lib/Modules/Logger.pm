#!/usr/bin/perl -w
#
# Copyright:     Jason Smallcanyon, 2009
# Author:        Jason Smallcanyon
# Revision:      $Revision: 1.0.1 $
# Last Revision: $Date$
# Modified By:   $Author: Jason Smallcanyon $
# Last Modified: $Date: July 16, 2013 $
# Source:        $Source:  $
#
####################################################################################
##
##


package Modules::Logger;

use lib qw "..";
use Modules::Config;
use strict;

# -----------------------------------------------------------
# SETTINGS:
# -----------------------------------------------------------

# Export our variables
our @ISA = qw(Exporter);

our @EXPORT = qw(logEvent fetchDate);     # Symbols to export by default

my $username;
if ($^O =~ /MSWin32/) {
    require Win32;
	$username = Win32::LoginName;
}
else {
	$username = "";
}

# -----------------------------------------------------------
# FUNCTIONS:
# -----------------------------------------------------------

#
# logEvent() - This function logs any data passed to it. The event log contains command events (i.e. read, write, execute).
# Input:  $content - String containing the content to be logged
# Output: Returns 1 if successful and undef if failed
sub logEvent {
    my($content) = @_;
    
	my $CONFIG = new Modules::Config();
    my $log_file = $CONFIG->{'EVENT_LOG'};
    my $timestamp = fetchDate();
    
    # Make sure our content is defined
    if (defined($content) && ($content ne "")) {
        $content = $timestamp.",".$content;
    }
    else {
        return;
    }
    
    # Append
    if (-e $log_file) {
        open(OUTFILE, ">>$log_file") || die "Cannot append to $log_file: $!\n";
        print OUTFILE "$content\n";
        close(OUTFILE);
    }
    # Create
    else {
        open(OUTFILE, ">$log_file") || die "Cannot create $log_file: $!\n";
        print OUTFILE "$content\n";
        close(OUTFILE);
    }
    
    return 1;
}

#
# fetchDate() - This function creates a basic formatted timestamp
# Input:  Nothing
# Output: Returns the local time in the format of: 'MM/DD/YY - HH:MM:SS'
sub fetchDate {
    # Time Information
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year = $year + 1900;
    $mon  = $mon + 1;
	my $localtime = sprintf "%02d/%02d/%4d - %02d:%02d:%02d", $mon,$mday,$year,$hour,$min,$sec;
    return $localtime;
}



1;

__END__
