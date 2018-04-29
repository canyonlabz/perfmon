#!/usr/bin/perl -w
#
# Copyright:     Jason Smallcanyon, 2011
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


package Perfmon::IO;

use lib qw "..";
use Modules::Logger;
use strict;
use Data::Dumper;


# -----------------------------------------------------------
# FUNCTIONS:
# -----------------------------------------------------------

#
# new() - Object constructor
# Input:  None
# Output: Object for performance metric collection
sub new {
	my $class = shift;
    
    my $self = {
        "OUTPUT" => "CSV"
    };
    
    bless $self, $class;   # Tag object with pkg name
    return $self;
}

#
# writeMetricsToFile() - Write the given metrics to an output file.
# Input:
# Output:
sub writeMetricsToFile {
    my ($self) = shift;
    my ($content, $results_file, $headings) = @_;
    
    $results_file .= ".csv";   # Output to a CSV file
    
    # Make sure we have the content
    unless (defined($content)) {
        logEvent("[Error]: The content could not be found for the file [$results_file]. Skipping....");
        return -1;
    }
        
    # Append
    if (-e $results_file) {
        open(OUTFILE, ">>$results_file") || die "Cannot append to $results_file: $!\n";
        print OUTFILE "$content\n";
        close(OUTFILE);
    }
    # Create
    else {
        my $metric_headings = $self->formatMetricHeadings($headings);
        open(OUTFILE, ">$results_file") || die "Cannot create $results_file: $!\n";
        print OUTFILE "$metric_headings\n";
        print OUTFILE "$content\n";
        close(OUTFILE);
    }    
    return 1;
}

#
# writeMetricsPerInstance() - Writes out the given metrics for each instance of the performance object (i.e. multiple NICs, multiple processors, etc.)
# Input:
# Output:
sub writeMetricsPerInstance {
    my ($self) = shift;
    my ($content, $results_file, $headings) = @_;
    
    foreach my $key (keys (%{$content})) {
        my $tmp_file = $results_file . "_" . $key;
        my $retval = $self->writeMetricsToFile($content->{$key}, $tmp_file, $headings);
        if ($retval < 0) { return $retval; }
    }
    return 1;
}

#
# writeMetricsPerProcess() - Writes out the given metrics for each process by name.
# Input:
# Output:
sub writeMetricsPerProcess {
    my ($self) = shift;
    my ($content, $results_file, $headings, $cell) = @_;
    
    foreach my $key (keys (%{$content})) {
        my @proc_array = split /,/, $content->{$key};
        my $proc_name = $proc_array[$cell];
        $proc_name =~ s/^\(//;
        $proc_name =~ s/\)$//;
        my $tmp_file = $results_file . "_" . $proc_name . "_" . $key;
        my $retval = $self->writeMetricsToFile($content->{$key}, $tmp_file, $headings);
        if ($retval < 0) { return $retval; }
    }
    return 1;
}

#
# formatMetricHeadings() - Formats the headings of the performance metrics
# Input:  $self - Object
#         $headings - Array reference to the metric headings
# Output: Returns a string containing the formatted metric headings
sub formatMetricHeadings {
    my($self) = shift;
    my($headings) = shift;
    
    # Make sure we are receiving a valid array reference
    unless (ref($headings) eq 'ARRAY') {
        my $logTime = time();
        logEvent("[Warning]: The data type received in formatMetricHeadings() was not a valid array reference.");
        return;
    }
    
    my @keys = @$headings;
    
    # Define the following
    my $stdout = "";
    
    # Iterate through each performance counter and format the values
    for (my $i=0; $i <= ($#keys); $i++) {
        $stdout .= $keys[$i] . ",";
    }
    
    $stdout =~ s/(,)$//;
    
    return ($stdout);
}

#
# formatMetrics() - Format the performance metrics into a comma-delimited string
# Input:  $self - Object
#         $metrics - Array or Hash reference to the performance metrics captured
# Output: Returns either a hash reference for objects with multiple instances or a string for one instance.
sub formatMetrics {
    my($self) = shift;
    my($metrics) = shift;
    
    # Make sure we have values to format
    unless (defined($metrics)) {
        logEvent("[Warning]: There were no performance metrics returned for formatting. Skipping....");
        return;
    }
    
    # Define the following
    my $stdout;
    
    # If our data type is a hash, then we have multiple instances of the performance object (i.e. multiple NICs, multiple processors, etc.)
    if (ref($metrics) eq 'HASH') {
        while (my($key,$value) = each %{$metrics}) {
            my $tmp_stdout = "";
            foreach my $stat (@$value) {
                $tmp_stdout .= ((defined($stat) && $stat ne "") ? $stat : "null") . ",";
            }
            $tmp_stdout =~ s/(,)$//;
            
            # Return our metrics per device
            $stdout->{$key} = $tmp_stdout;
        }
    }
    else {
        # Iterate through each performance metrics and format the values
        $stdout = "";
        foreach my $stat (@$metrics) {
            $stdout .= ( (defined($stat) && $stat ne "") ? $stat : "null" ) . ",";
        }
        $stdout =~ s/(,)$//;
    }
    
    return ($stdout);
}



1;

__END__