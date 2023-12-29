
use strict;
use File::Basename;
use Cwd 'abs_path';
use Config::IniFiles;
use Data::Dumper;
use Time::HiRes qw(time);
use POSIX qw(strftime);

BEGIN {
my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;
unshift (@INC,$dirname."/algorithm/");
unshift (@INC,$dirname."/");
}

use modules::vectordata;
use modules::logresult;

my $dirname = dirname(abs_path(__FILE__));

# read config from db.ini
my $configAdmin = Config::IniFiles->new( -file => $dirname."/db.ini" );
my $datasetname=$configAdmin->val("step1","datasetname");
$datasetname="lastfm" unless defined($datasetname);
my @benchmarkRecords= eval($configAdmin->val("step1","benchmarkRecords")); 
@benchmarkRecords= (500) if($@ || !defined($benchmarkRecords[0])) ;
my $algorithmIncludeRegex=$configAdmin->val("step1","algorithmIncludeRegex");
$algorithmIncludeRegex=".*" unless defined($algorithmIncludeRegex);
my $algorithmExcludeRegex=$configAdmin->val("step1","algorithmExcludeRegex");
$algorithmExcludeRegex="<>" unless defined($algorithmExcludeRegex);

my (@algodirs)=<$dirname/algorithm/*>;

my $logresults=modules::logresult->new($dirname);

foreach my $algodir (@algodirs) {
 my $algoname=basename($algodir);
 if($algoname =~ m/$algorithmIncludeRegex/){
    unless($algoname =~ m/^$algorithmExcludeRegex$/){      
        foreach my $i (@benchmarkRecords) {
            insert_and_index_algorithm($algoname,$datasetname,$i);
        }
    } else {
        print "Algorith $algoname skipped due to db.ini algorithmExcludeRegex setting (excluded)\n";
    }
 } else {
    print "Algorith $algoname skipped due to db.ini algorithmIncludeRegex setting (not included)\n";
 }
}

sub insert_and_index_algorithm {
    my ($algoname,$datasetname,$numlines) = @_;
    if(-f $dirname."/algorithm/$algoname/benchmark.pm") {
    if( -f $dirname."/algorithm/$algoname/db.ini") {
        print "$algoname dir ";
        my $module="${algoname}::benchmark";
        eval "require $module";
        if( $@ ) {  die $@; }
        my $config = Config::IniFiles->new( -file => $dirname."/algorithm/$algoname/db.ini" );
        my $indexParamStr=$config->val("parameters","index");
        my $indexParams=eval($indexParamStr);
        print "\nindexParamStr=$indexParamStr indexParams=$indexParams\n";
        my $queryParamStr=$config->val("parameters","query");
        my $queryParams=eval($queryParamStr);

        my ($class)="$module"->new($config->val("postgresql","dbname"),$config->val("postgresql","user"),$config->val("postgresql","pass"));
        print " , class name >>".$class->name()."<<\n";
        {
            my $data=modules::vectordata->new($datasetname);
            if($numlines>$data->length()){
                return 0;
            }
            if($numlines == -1) {$numlines=$data->length();}
            if($numlines > $data->length() ) {$numlines=$data->length();}
            my $epoch = time();
            print strftime("%d-%m-%Y %H:%M:%S", localtime($epoch)) . " Dataset ".$data->width().":".$data->length().", numlines=$numlines\n";
            # create table and return database connection handler (to decrease waiting time)
            $class->init_connection();
            $class->init_table($data);
            my $walfrom=$class->wal_position();
            $logresults->start_benchmark();
            $class->insert_from_data($data,$numlines);
            $logresults->end_benchmark();
            my $walto=$class->wal_position();
            my $walchange=$class->wal_position_change($walfrom,$walto);
            $logresults->logdata( "INSERT",$algoname,$datasetname,$numlines,$numlines,$class->table_size($data),"",$data->vectorsize());
            $logresults->logdata( "INSERTWAL",$algoname,$datasetname,$numlines,$numlines,$walchange,"".$class->table_size($data),$data->vectorsize());
            
            foreach my $indexParam (@$indexParams) {
                my $parameter={ %$indexParam };
                # save parameters in the one line string
                $parameter->{vsize}=$data->vectorsize();
                my $text =Dumper($parameter);
                $text=~s/\n| |\t|\;//g;
                $text=~s/|\$(VAR1)(=)//g;
                print "$text\n";
                $class->drop_index($data,$parameter);
                my $walfrom=$class->wal_position();
                $logresults->start_benchmark();
                $class->create_index($data,$parameter);
                $logresults->end_benchmark();
                my $walto=$class->wal_position();
                my $walchange=$class->wal_position_change($walfrom,$walto);
            
                $logresults->logdata( "INDEX",$algoname,$datasetname,$numlines,$numlines,$class->index_size($data),$text,$data->vectorsize());
                $logresults->logdata( "INDEXWAL",$algoname,$datasetname,$numlines,$numlines,$walchange,$text,$data->vectorsize());
            }       
            
        }

    } else {
        print "Algorith $algoname skipped, there is no DB configuration\nCreate file $dirname/algorithm/$algoname/db.ini with content\n[postgresql]
dbname=dataBaseNameForThisAlgorithm
user=userName
pass=userPassword
";
return 0;
    }
 } else {
    return 0;
 }
 return 1;
}
