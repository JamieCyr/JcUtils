package JcUtils::FileDB;

use 5.006;
use strict;
use warnings;
use JcUtils::Logger;

use Time::localtime;
use Time::Local;
use JSON::XS;
use enum qw(OPEN CLOSED);

=head1 NAME

JcUtils::FileDB - The great new JcUtils::FileDB!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Flat file data base for hashes.
Stores data in a flat file using JSON format.
Smartly opens and closes the flat file db; creating 10 entries in a row opens the file once and closes
it when necessary for a reading operation such at fetch();

Perhaps a little code snippet.

    my $defaultdb = JcUtils::FileDB::new();
    
    my $logger = JcUtils::Logger::new("/tmp/myLogfile");
    my $mydb = JcUtils::FileDB::new($logger, "/tmp/myDbFile");
    
    my $hashDb = JcUtils::FileDB::new({
         'dbFile'	=>	'/tmp/hashDbFile',
         'logger'	=>	$logger,
         'maxRecords'	=> 10000
    });

=head1 EXPORT

None.

=head1 SUBROUTINES/METHODS

=cut

our %defaults = (
	'dbFile' => "/tmp/defaultDbFile",
	'maxRecords' => 1000,
	'dbLogFile' => "/tmp/defaultDbFileLog",
);


=head2 new()

Cretes the new FileDb object.  You can use a hasref or individule arguments in the correct order.

=head3 Arguments

=over 4

=item 1. Object, JcUtils::Logger, user provided logger

=item 2. String, dbFile file name

=item 3. Number, maxRecords size, the max amount of records in the DB

=back

=head3 Return

=over 2

=item 1. Object, new FileDb object

=back

=cut

sub new {
	my $self = bless {};
	my $args;
	my $logger;
	
	#did they pas a hashref
	if (ref $_[0] eq 'HASH') {
		$args = shift;
		$self->{logger} = $args->{logger};
		$logger = $self->{logger};
	}
	else {
		$args = {};
		#is the first argument a logger
		my $obj = $_[0];
		my $tmp = ref($obj);
		if ($tmp eq 'JcUtils::Logger') {
			($self->{logger}, $args->{dbFile}, $args->{maxRecords}  ) = @_;
			$logger = $self->{logger};
		}
		else {
			($args->{dbFile}, $args->{maxRecords}  ) = @_;
		}
	}
	
	#do we need to create a defatult logger
	if (!defined($logger)){
		$self->{logger} = JcUtils::Logger::new($defaults{dbLogFile});
		$logger = $self->{logger};
		$logger->log("Created default logger");
	}
	else {
		$logger->log("User provided logger");
	}
	
	if (defined($args->{dbFile})){
		$self->{dbFile} = $args->{dbFile};
	}
	else {
		$self->{dbFile} = $defaults{dbFile};
	}
	
	if (defined($args->{maxRecords})) {
		$self->{maxRecords} = $args->{maxRecords};
	}
	else {
		$self->{maxRecords} = $defaults{maxRecords};
	}
	
	$self->{entryNum} = 0;
	$self->{dbState} = CLOSED;
	
	$self->openDb();
	
	$self->{logger}->log("FileDb Ready");
	
	return $self;
}

=head2 create()

Create a database record. Returns the UUID of the recored created.

=head3 Arguments

=over 2

=item 1. Hashref, hashref of the data structure to store

=back

=head3 Return

=over 3

=item 1. Number, UUID of the entry.

=item 2. Number, 0 on failure.

=back

=cut

sub create {
	my ($self, $entry) = @_;
	my $line = "";
	my $uuid;
	my $logger = $self->{logger};
	
	#We need the enty argument
	if (!defined($entry)) {
		$logger->error->log("entry argument was not defined");
		return 0;
	}
	
	#create a unique DB ID
	$uuid = $self->{entryNum}++ . localtime()->mday() . localtime()->hour() . localtime()->min() . localtime()->sec();
	$entry->{'UUID'} = $uuid;
	
	$line = JSON::XS->new->encode($entry);
	$line = $line . "\n";
	
	if ($self->{dbState} == CLOSED) {
		$self->openDb();
	}
	
	my $db_fh = $self->{db_fh};
	
	print $db_fh $line;
	$logger->log("Created entry $uuid");
	
	return $uuid;

}

=head2 update()

Udate a record in the DB

=head3 Arguments

=over 2

=item 1. Hashref, Hash reference with UUID field.

=back

=head3 Return

=over 3

=item 1. Number, 1 for Success.

=item 2. Number, 0 for failure.

=back

=cut

sub update {
	
	my ($self, $entry) = @_;
	my $db_fh;
	my $dbW_fh;
	my $line = "";
	my $dbFile = $self->{dbFile};
	my $logger = $self->{logger};
	my $record = {};
	
	#We need the enty argument
	if (!defined($entry)) {
		$logger->error->log("Entry argument was not provided");
		return 0;
	}
	
	#The entry needs a uuid
	if (!defined($entry->{UUID})) {
		$logger->error->log("Entry had no UUID");
		return 0;
	}
	
	#Make sure the filehandle is closed.
	if ($self->{dbState} == OPEN){
		$self->closeDb();
	}
	
	open ($db_fh, "<$dbFile") || die "Could not open logfile: $self->{dbFile}: $!";
	
	#Open the temp DB
	unless (open ($dbW_fh, ">>$dbFile.tmp")) {
		$logger->error->log("Failed to open tmp DB");
		return 0;
	}
	
	while (<$db_fh>) {
		chomp $_;
		$record = JSON::XS->new->decode($_);
		if (exists $record->{UUID}) {
			if ($record->{UUID} eq $entry->{UUID}) {
				$line = JSON::XS->new->encode($entry);
				$line = $line . "\n";
				print $dbW_fh $line;
				$logger->log("updated entry $entry->{UUID}");
			}
			else {
				print $dbW_fh $_ . "\n";
			}
		}
	}
	
	close ($db_fh);
	close ($dbW_fh);
	
	#rename the DB
	unlink ($dbFile) || die "Could not delete $dbFile: $! \n";
	rename ($dbFile . ".tmp", $dbFile) || die "Could not rename $dbFile.tmp: $! \n";
	
	return 1;
	
}

sub delete {
	
}

=head2 find()

Find a record in the db, return an array of UUIDs, empty array if nothing was found.  Use fetch() method to
acutally obtain the record. The find() method will return any entry that contains the search string.

=head3 Arguments

=over 4

=item 1. String, key to find

=item 2. String, the string to search for

=item 3. Number, 1=ignore case

=back

=head3 Return

=over 2

=item 1. Array, array of restuls, empty array if no results found or failure.

=back

=cut

sub find {
	
	my ($self, $key, $searchString, $ignoreCase) = @_;
	my $db_fh;
	my $dbFile = $self->{dbFile};
	my $logger = $self->{logger};
	my @results;
	my $record = {};
	my $entry;
	
	#We need at least the first two arguments
	if (!defined($key)) {
		$logger->error->log("Key String was not defined");
		return @results;
	}
	
	if (!defined($searchString)) {
		$logger->error->log("Search String was not defined");
		return @results;
	}
	
	#Make sure the filehandle is closed.
	if ($self->{dbState} == OPEN){
		$self->closeDb();
	}
	
	open ($db_fh, "<$dbFile") || die "Could not open database file: $self->{dbFile}: $!";
	
	$logger->log("Looking for $key, $searchString");
	
	while (<$db_fh>) {
		chomp $_;
		$record = JSON::XS->new->decode($_);
		if (exists $record->{$key}) {
			$entry = $record->{$key};
			if ($ignoreCase) {
				$logger->log("Doing ignoring case search");
				$searchString = lc($searchString);
				$entry = lc($entry);
			}
			if ($entry =~ m/$searchString/) {
				$logger->log("found entry $record->{UUID}");
				push @results, $record->{UUID};
			}
		}
	}
	
	my $size = @results;
	
	unless ($size > 0){
		$logger->warn->log ("Did not find $key, $searchString");
	}
	
	close ($db_fh);
	
	return @results;
	
}

=head2 fetch()

Fetch a record from the db.  If it doesn't exist return empty hashref

=head3 Arguments

=over 2

=item 1. Number, the UUID of the record

=back

=head3 Return

=over 2

=item 1. Hashref, hash reference of the object.

=item 2. Number, 0 on failure.

=back

=cut

sub fetch {
	my ($self, $entry) = @_;
	my $db_fh;
	my $dbFile = $self->{dbFile};
	my $logger = $self->{logger};
	my $record = {};
	
	#We need the UUID argument
	if (!defined($entry)) {
		$logger->error->log("UUID argument was not provided");
		return 0;
	}
	
	#Make sure the filehandle is closed.
	if ($self->{dbState} == OPEN){
		$self->closeDb();
	}
	
	
	open ($db_fh, "<$dbFile") || die "Could not open logfile: $self->{dbFile}: $!";
	
	$logger->log("Looking for $entry");
	
	while (<$db_fh>) {
		chomp $_;
		$record = JSON::XS->new->decode($_);
		if (exists $record->{UUID}) {
			if ($record->{UUID} eq $entry) {
				$logger->log("found entry $record->{UUID}");
				return $record;
			}
		}
	}
	$logger->warn->log("Did not find $entry");
	
	close ($db_fh);
	
	return $record = {};
	
}

=head2 getRecordCount()

Get the number of records in the DB.

=head3 Returns

=over 2

=item 1. Number, number of records in the data base

=back

=cut

sub recordCount {
	my $self = shift;
	my $db_fh;
	my $dbFile = $self->{dbFile};
	my $logger = $self->{logger};
	my $count = 0;
	
	#Make sure the filehandle is closed.
	if ($self->{dbState} == OPEN){
		$self->closeDb();
	}
	
	
	open ($db_fh, "<$dbFile") || die "Could not open logfile: $self->{dbFile}: $!";
	
	$logger->log("Counting records");
	
	while (<$db_fh>) {
		$count++;
	}
	
	close ($db_fh);
	
	return $count;
	
}

=head2 closeDb()

Convenience function that opens the flat file data base.

=head3 Return

=over 3

=item 1. Number, 1 success.

=item 2. Number, 0 failure.

=back

=cut

sub closeDb {
	my $self = shift;
	my $db_fh = $self->{db_fh};
	my $logger = $self->{logger};
	
	unless (close ($db_fh)) {
		return 0;
	}
	$self->{dbState} = CLOSED;
	$logger->log("Database CLOSED");
	return 1;
}

=head2 openDb()

Convenience function that closes the flat file data base.

=head3 Return

=over 3

=item 1. Number, 1 success.

=item 2. Number, 0 failure.

=back

=cut

sub openDb {
	my $self = shift;
	my $logger = $self->{logger};
	
	my $dbFile = $self->{dbFile};
	
	unless (open ($self->{db_fh}, ">>$dbFile")) {
		$logger->error->log("Failed to open DB");
		return 0;
	}
	
	#enable autoflush on the db
	my $db_fh = $self->{db_fh};
	$db_fh->autoflush(1);
	
	$self->{dbState} = OPEN;
	$logger->log("Database OPEN");
	
	return 1;
}

=head1 AUTHOR

Jamie Cyr, C<< <jjcyr at yahoo.com> >>

=head1 BUGS

=head2 delete()

The delete() function is not yet implemented.

Please report any bugs or feature requests to TBD.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JcUtils::FileDB

You can also look for information at: TBD

=head1 ACKNOWLEDGEMENTS

None.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jamie Cyr.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of JcUtils::FileDB
