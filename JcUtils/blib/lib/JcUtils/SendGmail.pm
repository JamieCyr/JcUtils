package JcUtils::SendGmail;

use 5.006;
use strict;
use warnings;
use JcUtils::Logger;
use Net::SMTP::TLS;

=head1 NAME

JcUtils::SendGmail - The great new JcUtils::SendGmail!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use JcUtils::SendGmail;

    my $foo = JcUtils::SendGmail->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=cut

our %defaults = (
	'server' => "smtp.gmail.com",
	'portNumber' => '587',
	'timeOut' => 5,
	'logFile' => '/tmp/sendGmailLog',
);


=head1 SUBROUTINES/METHODS

=head2 new()

Creates the SendGmail object

=over 7

=item 1. JcUtils::Logger, logger object

=item 2. String, Gmail user name

=item 3. String, Gmail user password

=item 4. Number, server

=item 5. String, port Number

=item 6. String, time out

=back

=head2 returns

=over 2

=item 1. Object, self

=back

=cut

sub new {

	my $self = bless {};
	my $logger;
	my $args;
	
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
			($self->{logger}, $args->{userName}, $args->{password}, $args->{server}, $args->{portNumber}, $args->{timeOut} ) = @_;
			$logger = $self->{logger};
		}
		else {
			($args->{userName}, $args->{password}, $args->{server}, $args->{portNumber}, $args->{timeOut} ) = @_;
		}
	}
	
	#do we need to create a defatul logger
	if (!defined($logger)){
		$self->{logger} = JcUtils::Logger::new($defaults{logFile});
		$logger = $self->{logger};
		$logger->log("Created default logger");
	}
	else {
		$logger->log("User provided logger");
	}
	
	if (defined($args->{server})){
		$self->{server} = $args->{server};
		$logger->log("Using user provided server: " . $self->{server});
	}
	else {
		$self->{server} = $defaults{server};
		$logger->log("Using default server: " . $self->{server});
	}
	
	if (defined($args->{portNumber})){
		$self->{portNumber} = $args->{portNumber};
		$logger->log("Using user provided portNumber: " . $self->{portNumber});
	}
	else {
		$self->{portNumber} = $defaults{portNumber};
		$logger->log("Using default port: " . $self->{portNumber});
	}
	
	if (defined($args->{timeOut})){
		$self->{timeOut} = $args->{timeOut};
		$logger->log("Using user defined timeOut: " . $self->{timeOut});
	}
	else {
		$self->{timeOut} = $defaults{timeOut};
		$logger->log("Using default timeOut: " . $self->{timeOut});
	}
	
	if (defined($args->{userName})){
		$self->{userName} = $args->{userName};
	}
	else {
		$logger->error->log("Missing necessary argument userName");
		die "Missing necessary argument userName \n";
	}
	
	if (defined($args->{password})){
		$self->{password} = $args->{password};
	}
	else {
		$logger->error->log("Missing necessary argument password");
		die "Missing necessary argument password \n";
	}
	
	$logger->log("SendGmail Ready to send");
	return $self
	
}

=head2 sendMessage()

Sends a message using gmail smtp server

=over 4

=item 1. String, To: email address

=item 2. String, message

=item 3. String, subject

=back

=head2 returns

=over 3

=item 1. Number, 0 failure

=item 2. Number, 1 success

=back

=cut

sub sendMessage {
	my $self = shift;
	my $logger;
	my $args;
	
	$logger = $self->{logger};
	
	if (ref $_[0] eq 'HASH') {
		$args = shift;
	}
	else {
		$args = {};
		($args->{to}, $args->{message}, $args->{subject}) = @_;
	}
	
	#where the right arguments supplied
	if (!defined($args->{to})) {
		$logger->error->log("To: not provided");
		return 0;
	}
	
	if (!defined($args->{message})) {
		$logger->error->log("Messge not provided");
		return 0;
	}
	
	if ($self->{userName} eq 'Fake.User@gmail.com') {
		$logger->warn->log("not actually sending the message");
		$logger->log("Sent fake message To: " . $args->{to} . " Subject: " . $args->{subject});
		return 1;
	}
	
	
	eval {
		my $mailer = new Net::SMTP::TLS(
        $self->{server},
        Port    =>      $self->{portNumber},
        User    =>      $self->{userName},
        Password=>      $self->{password});
	 $mailer->mail($self->{userName});
	 $mailer->to($args->{to});
	 $mailer->data;
	 if (defined($args->{subject})){
	 	$mailer->datasend("Subject: " . $args->{subject} . "\n");
	 }
	 else {
	 	$logger->warn->log("No subject given");
	 }
	 $mailer->datasend($args->{message} . "\n");
	 $mailer->dataend;
	 $mailer->quit;
	};
	
	if ($@) {
		$logger->error->log("Net::SMTP::TLS encountered and error $@");
		return 0;
	}
	
	$logger->log("Sent message To: " . $args->{to} . " Subject: " . $args->{subject});
	 return 1;
	
}

=head1 AUTHOR

Jamie Cyr, C<< <jjcyr at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jcutils-logger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JcUtils-Logger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JcUtils::SendGmail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JcUtils-Logger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JcUtils-Logger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JcUtils-Logger>

=item * Search CPAN

L<http://search.cpan.org/dist/JcUtils-Logger/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jamie Cyr.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of JcUtils::SendGmail
