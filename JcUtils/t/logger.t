use Test::More tests => 12;
use Test::Output;
use JcUtils::Logger;

BEGIN {
    use_ok( 'JcUtils::Logger' ) || print "Bail out!\n";
}

diag( "Testing JcUtils::Logger $JcUtils::Logger::VERSION, Perl $], $^X" );

my $defaultLogger = JcUtils::Logger::new();
ok(-e "/tmp/defaultLog", "defaultLog file exists");
ok ($defaultLogger->closeLog(), "defaultlog closelog");

my $logger = JcUtils::Logger::new("/tmp/testLog");

ok(-e "/tmp/testLog", "testLog file exists");

$logger->log("Some Text");
$logger->log("Other Text");
ok ($logger->closeLog(), "testLog close loger");

ok(-s "/tmp/testLog" > 1, "testLog file greate than 1");

my $filesizeLogger = JcUtils::Logger::new("/tmp/testLog", 10);
ok(-e "/tmp/testLog.bak", "testLog.bak file exists");
ok(-e "/tmp/testLog", "testLog file exists");

$filesizeLogger->warn->log("Warning log");
$filesizeLogger->error->log("Error log");
$filesizeLogger->log("Back to INFO log");

my $newLogger = JcUtils::Logger::new("/tmp/newtestlog");
$newLogger->log("one entry");
#$newLogger->closeLog();
unlink ("/tmp/newtestlog");
$newLogger->log("after delete");
ok(-e "/tmp/newtestlog", "testLog file exists");

my $errorOnly = JcUtils::Logger::new("/tmp/errorOnlyLog");
$errorOnly->setLogLevelError();
$errorOnly->warn()->log("Warning log");
ok(-s "/tmp/errorOnlyLog" == 0, "Error only");
$errorOnly->setLogLevelWarn();
$errorOnly->warn()->log("Warning log");
$errorOnly->error()->log("Error Log");
ok(-s "/tmp/errorOnlyLog" > 50, "warn and error");
$errorOnly->setLogLevelInfo();
$errorOnly->warn()->log("Warning log");
$errorOnly->error()->log("Error Log");
$errorOnly->info()->log("Info Log");
ok(-s "/tmp/errorOnlyLog" > 125, "warn and error");

#cleanup
unlink ("/tmp/testLog");
unlink ("/tmp/defaultLog");
unlink ("/tmp/testLog.bak");
unlink ("/tmp/newtestlog");
unlink ("/tmp/errorOnlyLog");