use Test::More tests => 40;
use Test::Output;
use JcUtils::Logger;
use JcUtils::FileDB;

BEGIN {
    use_ok( 'JcUtils::FileDB' ) || print "Bail out!\n";
}

diag( "Testing JcUtils::Logger $JcUtils::Logger::VERSION, Perl $], $^X" );


my $defaultdb = JcUtils::FileDB::new();
ok($defaultdb->openDb(), "open DB");
ok(-e "/tmp/defaultDbFileLog", "default DbFileLog exists");
ok(-e "/tmp/defaultDbFile", "default Dbfile exists");
ok($defaultdb->closeDb(), "close DB");

can_ok($defaultdb, qw(create update new delete find openDb closeDb fetch recordCount));

my $entry = {};
	
$entry->{'logFile'} = '/tmp/defaultLog';
$entry->{'maxLogSize'} = 100000;
$entry->{'another'} = 'testnoe';

ok($defaultdb->create($entry), "create first entry");
ok($defaultdb->create($entry), "create second entry");
ok(-s "/tmp/defaultDbFile" > 1, "default DB file not empty");

my $logger = JcUtils::Logger::new("/tmp/myLogfile");

my $mydb = JcUtils::FileDB::new($logger, "/tmp/myDbFile");
ok($mydb->openDb(), "open my DB");
ok(-e "/tmp/myLogfile", "myLogFile file exists");
ok(-e "/tmp/myDbFile", "myDbFile file exists");
ok($mydb->closeDb(), "close my DB");

ok($mydb->create($entry), "create first entry");
ok($mydb->create($entry), "create second entry");
ok(-s "/tmp/myDbFile" > 1, "myDbfile DB file not empty");

ok($mydb->create() == 0, "create with no argument");

my $id = $mydb->create($entry);
ok($id > 1, "uuid");
ok($mydb->fetch() == 0, "fetch no argument");
$entry = $mydb->fetch($id);
ok($entry->{UUID} eq $id, "fetch record");
$entry = $mydb->fetch(12345);
ok(!exists $entry->{UUID}, "fetch record, not there");

ok($mydb->find() == 0, "find no argument");
my @fresults = $mydb->find('another', 'testnoe');
ok(my $fsize = @fresults == 3, "find records");

my @hresults = $mydb->find('another', 'estn');
ok(my $hsize = @hresults == 3, "find contains records");

my @nresults = $mydb->find();
ok(my $nsize = @nresults == 0, "No arguments to find");

my @oresults = $mydb->find('uyy');
ok(my $osize = @oresults == 0, "One arguments to find");

my $centry = {};
my $ccount = 0;
while ($mydb->hasMoreEntries()) {
	$centry = $mydb->getNext();
	$ccount++
}

ok($ccount == 3, "get next");

$ccount = 0;
while ($mydb->hasMoreEntries()) {
	$centry = $mydb->getNext();
	$ccount++
}
ok($ccount == 3, "get next, again");

ok($mydb->setIndex(99) == 0, "set index fail");
ok($mydb->setIndex(2) == 1, "set index success");

$ccount = 0;
while ($mydb->hasMoreEntries()) {
	$centry = $mydb->getNext();
	$ccount++
}

ok($ccount == 1, "get after set correct index");

my $update = {};
	
$update->{'logFile'} = '/tmp/defaultLog';
$update->{'maxLogSize'} = 100000;
$update->{'another'} = 'test none';

ok($mydb->update($update) == 0, "update no key");

$entry = $mydb->fetch($id);
$entry->{another} = 'test None';
ok ($mydb->update($entry), "upDate entry");

my @ignoreResults = $mydb->find('another', 'test none', 1);
ok (my $isize = @ignoreResults == 1, "Ignore case");

my @nignoreResults = $mydb->find('another', 'test none');
ok (my $nisize = @nignoreResults == 0, "Ignore case, fail");

ok ($mydb->recordCount() == 3, "Record count");

my $hashDb = JcUtils::FileDB::new({
	'dbFile'	=>	'/tmp/hashDbFile'
});

$hashDb->create($entry);
ok(-s "/tmp/hashDbFile" > 10, "hashDb test");

$entry->{another} = 'record two';
$hashDb->create($entry);
$entry->{another} = 'record three';
$hashDb->create($entry);
$entry->{another} = 'record four';
$hashDb->create($entry);

ok($hashDb->recordCount() == 4, "Adding to hashDb");

@uuids = $hashDb->find("another", "record three");
foreach $uuid (@uuids){
	$hashDb->delete($uuid);
}

ok($hashDb->recordCount() == 3, "Delete a record");
ok($hashDb->delete(4343) == 0, "Delete no entry");


#cleanup
unlink ("/tmp/defaultDbFileLog");
unlink ("/tmp/defaultDbFile");
unlink ("/tmp/myDbFile");
unlink ("/tmp/myLogfile");
unlink ("/tmp/hashDbFile");
