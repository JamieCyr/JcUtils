#!/usr/bin/perl -w

use strict;
use JcUtils::Logger;
use 5.006;
use warnings;

my $mailLogger = JcUtils::Logger::new('/tmp/testLogger');

try($mailLogger);

sub try{
	my $logger = shift;
	
	$logger->log("some log");
}

