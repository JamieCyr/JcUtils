use Test::More tests => 14;
use Test::Output;
use JcUtils::SendGmail;
use JcUtils::Logger;

BEGIN {
    use_ok( 'JcUtils::SendGmail' ) || print "Bail out!\n";
}

diag( "Testing JcUtils::Logger $JcUtils::Logger::VERSION, Perl $], $^X" );

my $mailLogger = JcUtils::Logger::new('/tmp/mailLogger');

my $gmailWlogger = JcUtils::SendGmail::new({
	'logger'	=> $mailLogger,
	'userName'	=>	'some.user@gmail.com',
	'password'	=> 'somepasswd'});
ok(-e "/tmp/mailLogger", "gmail with logger");
unlink ('/tmp/mailLogger');

my $mailLoggerReg = JcUtils::Logger::new('/tmp/mailLoggerReg');

my $gmailWloggerReg = JcUtils::SendGmail::new($mailLoggerReg, 'some.user@gmail.com', 'thepassword');
ok(-e "/tmp/mailLoggerReg", "gmail with logger");
unlink ('/tmp/mailLoggerReg');

my $defaultgmail = JcUtils::SendGmail::new({
	'userName'	=> 'some.user@gmail.com',
	'password'	=>	'somepasswd'});
	
ok(-e "/tmp/sendGmailLog", "gmail default");
can_ok($defaultgmail, qw(new sendMessage));
unlink ('/tmp/sendGmailLog');

my $argRef = {};
$argRef->{userName} = 'some.user@gmail.com';
$argRef->{password} = 'somepasswd';

my $defaultRef = JcUtils::SendGmail::new($argRef);
ok(-e "/tmp/sendGmailLog", "gmail default");
unlink ('/tmp/sendGmailLog');

my $refLogger = JcUtils::Logger::new('/tmp/refLogger');

my $argRefLogger = {};
$argRefLogger->{userName} = 'some.user@gmail.com';
$argRefLogger->{password} = 'somepasswd';
$argRefLogger->{logger} = $refLogger;

my $defaultRefWlogger = JcUtils::SendGmail::new($argRefLogger);
ok(-e "/tmp/refLogger", "gmail default");
unlink ('/tmp/refLogger');

my $allArgs = JcUtils::SendGmail::new ('all.args@gmail.com', 'allargspsswd', 'all.arg.server', 69, 96);
ok($allArgs->{portNumber} == 69, "All args, portNumber");
ok($allArgs->{server} eq 'all.arg.server', "All args, server");
ok($allArgs->{timeOut} == 96, "All args, timeOut");
unlink ('/tmp/sendGmailLog');

my $sendgmail = JcUtils::SendGmail::new({
	'userName'	=> 'Fake.User@gmail.com',
	'password'	=>	'fakepasswd'});

my $message = "Test message from sendGmail \n";

ok($sendgmail->sendMessage() == 0, "sendMessage no arguments");
ok($sendgmail->sendMessage('jjcyr@yahoo.com', 'not ref subject', $message), "send message not hashref");

my $sendRef = {};
$sendRef->{to} = 'jjcyr@yahoo.com';
$sendRef->{subject} = 'Ref Subject';
$sendRef->{message} = $message;

ok($sendgmail->sendMessage($sendRef), "send message hasref");

ok($sendgmail->sendMessage({
	'to'	=>	'jjcyr@yahoo.com',
	'subject'	=>	'Test Subject',
	'message'	=>	$message } ), "sendMessage");
	
unlink ('/tmp/sendGmailLog');

#one real message, ucomment and add real name and password then ++ the test number on first line.
#my $realSendGmail = JcUtils::SendGmail::new('your.name@gmail.com', 'yourpasswd');
#ok ($realSendGmail->sendMessage($sendRef), "Real message");

