
use Test::More tests => 3;

BEGIN {
    use_ok( 'JcUtils::Logger' ) || print "Bail out!\n";
    use_ok( 'JcUtils::FileDB' ) || print "Bail out!\n";
    use_ok( 'JcUtils::SendGmail' ) || print "Bail out!\n";
}

diag( "Testing JcUtils::Logger $JcUtils::Logger::VERSION, Perl $], $^X" );
