#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;


my $output;

open(SPEEDTEST, "speedtest-cli --simple |") or die "Could not execute speedtest-cli: $!";
while ( defined( my $line = <SPEEDTEST> )  ) {
	chomp ($line);

	my $errors = 0;
	if ($line =~ /Ping: (.*) ms/) {
		$output .= "# TYPE speedtest_latency_ms gauge\n";
		$output .= "# HELP speedtest_latency_ms Latency to speedtest.net node in milliseconds\n";
		$output .= "speedtest_latency_ms $1\n";
	} elsif ($line =~ /Download: (.*) Mbit\/s/) {
		$output .= "# TYPE speedtest_bits_per_second gauge\n";
		$output .= "# HELP speedtest_bits_per_second Speed measured against speedtest.net\n";
		my $speed = $1 * 1000000;
		$output .= "speedtest_bits_per_second{direction=\"downstream\"} $speed\n";
	} elsif ($line =~ /Upload: (.*) Mbit\/s/) {
		my $speed = $1 * 1000000;
		$output .= "speedtest_bits_per_second{direction=\"upstream\"} $speed\n";
	} else {
		$output .= "# TYPE parse_errors gauge\n";
		$output .= "# HELP parse_errors Parse errors in script\n";
		$output .= "parse_errors{direction= ++$errors\n";
	}
}
close SPEEDTEST;
my @curl = ('curl', '-X', 'POST', '--data-binary', $output, 'http://localhost:9091/metrics/job/speedtest_exporter');
system (@curl) == 0 or print "ERROR: $!\n";
