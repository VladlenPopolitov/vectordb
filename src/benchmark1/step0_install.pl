
use strict;
use File::Basename;
use Cwd 'abs_path';
use Config::IniFiles;
use DBI;

BEGIN {
my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;
unshift (@INC,$dirname."/algorithm/");
}

#use pgvector_hnsw::benchmark;

my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;
my $configAdmin = Config::IniFiles->new( -file => $dirname."/db.ini" );

# read config from db.ini
my $algorithmIncludeRegex=$configAdmin->val("step0","algorithmIncludeRegex");
$algorithmIncludeRegex=".*" unless defined($algorithmIncludeRegex);
my $algorithmExcludeRegex=$configAdmin->val("step0","algorithmExcludeRegex");
$algorithmExcludeRegex="<>" unless defined($algorithmExcludeRegex);


foreach my $algodir (@algodirs) {
 my $algoname=basename($algodir);
 if($algoname =~ m/$algorithmIncludeRegex/){
    unless($algoname =~ m/^$algorithmExcludeRegex$/){      
        install_algorithm($algoname);
    } else {
        print "Algorith $algoname skipped due to db.ini algorithmExcludeRegex setting (excluded)\n";
    }
 } else {
    print "Algorith $algoname skipped due to db.ini algorithmIncludeRegex setting (not included)\n";
 }    
}

sub install_algorithm {
    my $algoname = shift @_;
    if(-f $dirname."/algorithm/$algoname/benchmark.pm") {
    if( -f $dirname."/algorithm/$algoname/db.ini") {
        print "$algoname dir ";
        my $module="${algoname}::benchmark";
        eval "require $module";
        if( $@ ) {  die $@; }
        my $config = Config::IniFiles->new( -file => $dirname."/algorithm/$algoname/db.ini" );
        my ($class)="$module"->new($config->val("postgresql","dbname"),$config->val("postgresql","user"),$config->val("postgresql","pass"));
        print " , class name >>".$class->name()."<<\n";
        # creat user and database (as admin)
        my $dbh=DBI->connect('dbi:Pg:db='.$configAdmin->val("postgresql","admindb"), $configAdmin->val("postgresql","adminuser"), $configAdmin->val("postgresql","adminuser"), {AutoCommit => 1});
        $class->create_user($dbh);
        $class->create_database($dbh);
        # reconnect with new database as current database (as admin)
        $dbh=DBI->connect('dbi:Pg:dbname='.$config->val("postgresql","dbname"), $configAdmin->val("postgresql","adminuser"), $configAdmin->val("postgresql","adminuser"), {AutoCommit => 1});
        $class->init_database($dbh);
    } else {
        print "Algorith $algoname skipped, there is no DB configuration\nCreate file $dirname/algorithm/$algoname/db.ini with content\n[postgresql]
dbname=dataBaseNameForThisAlgorithm
user=userName
pass=userPassword
";
    }
 }
 
}