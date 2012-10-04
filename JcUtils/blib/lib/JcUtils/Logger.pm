package JcUtils::Logger;

use 5.006;
use strict;
use warnings;

use Time::localtime;
use Time::Local;
use enum qw(WARN INFO ERROR);

my %defaults = (
	'logFile' => "/tmp/defaultLog",
	'maxLogSize' => 100000,
);

=head1 NAME

JcUtils::Logger - The great new JcUtils::Logger!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Perl logger utility for use in perl scripts.  Features three logging levels WARN, INFO, and ERROR.
JcUtils::Logger will never die from error; a failed log attempt should not stop a program from running.
Ability to set log level such that after debugging you can specify to log only ERROR or ERROR and WARN thus not logging INFO.

    my $defaultLogger = JcUtils::Logger::new();
    $defaultLogger->log("some text to log");
    $defaultLogger->warn->log("Warning log");
    $defaultLogger->error->log("Error log");
    $defaultLogger->log("Back to INFO log");
	
    my $newLogger = JcUtils::Logger::new("/tmp/newtestlog");
	
    my $filesizeLogger = JcUtils::Logger::new("/tmp/testLog", 10000);

=cut


=head1 EXPORT

None.

=head1 SUBROUTINES/METHODS

=cut


=head2 new()

Creates the logger object

=head2 Arguments

=over 3

=item 1. String, log file name

=item 2. Number, log file max size

=back

=cut

sub new {
	
	my $self = bless {};
	my %args;
	$self->{logEntryNum} = 0;
	$self->{logLevel} = INFO;
	
	($args{logFile}, $args{maxLogSize} ) = @_;
	
	#Has the user defined a specific log file
	if (defined($args{logFile})){
		$self->{logFile} = $args{logFile};
	}
	else {
		$self->{logFile} = $defaults{logFile};
	}
	
	#Has the user provided a max log size
	if (defined($args{maxLogSize})) {
		$self->{maxLogSize} = $args{maxLogSize};
	}
	else {
		$self->{maxLogSize} = $defaults{maxLogSize};
	}
	
	$self->{logType} = INFO;
	
	#before we open the log, let's do some maintenance
	$self->maint();
	
	$self->openLog();
	
	return $self;
}

=head2 log()

Formats strings for logging then logs string.

=over 2

=item 1. String, string to be logged

=back

=cut

sub log {
	my ($self, $entry) = @_;
	
	my $log_fh = $self->{log_fh};
	
	my $timeStamp;
	my $build;
	
	$timeStamp = localtime()->mon()+1 . localtime()->mday() . localtime()->hour() . localtime()->min() . localtime()->sec();
	
	if ($self->{logType} == INFO) {
		$build = "INFO ";
	}
	if ($self->{logType} == WARN){
		$build = "WARN "
	}
	if ($self->{logType} == ERROR){
		$build = "ERROR "
	}
	
	$build = $build . $self->{logEntryNum}++ . $timeStamp . " " . $entry . "\n";
	
	#check to see if, somehow the log was deleted
	my $logFile = $self->{logFile};
	unless (-e $logFile) {
		$self->openLog();
	}
	
	#Are we logging this entry
	if ($self->{logLevel} == ERROR) {
		if ($self->{logType} == ERROR) {
			print $log_fh $build;
			$self->{logType} = INFO;
			return 1;
		}
	}
	if ($self->{logLevel} == WARN) {
		if ($self->{logType} == WARN || $self->{logType} == ERROR ) {
			print $log_fh $build;
			$self->{logType} = INFO;
			return 1;
		}
	}
	
	if ($self->{logLevel} == INFO) {
		if ($self->{logType} == WARN || $self->{logType} == INFO || $self->{logType} == ERROR ) {
			print $log_fh $build;
			$self->{logType} = INFO;
			return 1;
		}
	}

	$self->{logType} = INFO;
	
	return 1;
	
}

=head2 setLogLevelError()

Sets logger to log only ERROR

=cut

sub setLogLevelError {
	my $self = shift;
	$self->{logLevel} = ERROR;
	return $self;
}

=head2 setLogLevelWarn()

Sets logger to log only WARN and ERROR

=cut

sub setLogLevelWarn {
	my $self = shift;
	$self->{logLevel} = WARN;
	return $self;
}

=head2 setLogLevelInfo()

Sets logger to log INFO, WARN, and ERROR.  Or, log everything as is the default.

=cut

sub setLogLevelInfo {
	my $self = shift;
	$self->{logLevel} = INFO;
	return $self;
}

=head2 info()

Sets the log entry type to INFO, returns itself

=cut

sub info {
	my $self = shift;
	$self->{logType} = INFO;
	return $self;
}

=head2 warn()

Sets the log entry type to WARN, returns itself

=cut

sub warn {
	my $self = shift;
	$self->{logType} = WARN;
	return $self;
}

=head2 error()

Sets the log entry type to ERROR, returns itself

=cut

sub error {
	my $self = shift;
	$self->{logType} = ERROR;
	return $self;
}
=head2 maint()

Does log maintenace and is usually called in the constuctor of this object; however, can be
called by the user.

=cut

sub maint {
	my $self = shift;
	my $logFile = $self->{logFile};
	my $maxLogSize = $self->{maxLogSize};

	my $size = -s $logFile;
	if (defined($size)) {
		if ($size > $maxLogSize) {
			if (-e $logFile . ".bak") {
				unlink($logFile . ".bak");
			}
			rename($logFile, $logFile . ".bak");
		}
	}
	
}

=head2 closeLog()

Closes the log file

=cut

sub closeLog {
	
	my $self = shift;
	
	my $log_fh = $self->{log_fh};

	unless (close ($log_fh)) {
		print STDERR "Unable to close log file: " . $self->{logFile} . $! . "\n";
		return 0;
	}
	return 1;
}

sub openLog {
	
	my $self = shift;
	
	unless (open ($self->{log_fh}, ">>$self->{logFile}")) {
		print STDERR "Unable to open log file: " . $self->{logFile} . $! . "\n";
		return 0;
	}
	
	#enable autoflush on the logger
	#my $log_fh = $self->{log_fh};
	#$log_fh->autoflush(1);
	$self->{log_fh}->autoflush(1);
	
	return 1;
	
}


=head1 AUTHOR

Jamie Cyr, C<< <jjcyr at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to TBD.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JcUtils::Logger

You can also look for information at: TBD

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jamie Cyr.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of JcUtils::Logger
