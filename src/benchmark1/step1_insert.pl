
use strict;
use File::Basename;
use Cwd 'abs_path';
use Config::IniFiles;
use Data::Dumper;

BEGIN {
my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;
unshift (@INC,$dirname."/algorithm/");
unshift (@INC,$dirname."/");
}

use modules::vectordata;
use modules::logresult;


my $datasetname="glove-100-a";

my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;

my $logresults=modules::logresult->new($dirname);

foreach my $algodir (@algodirs) {
 my $algoname=basename($algodir);
 my @benchmarkRecords= (5000); #  (10,100,1000,5000,10000,50000,100000,500000,-1);
 foreach my $i (@benchmarkRecords) {
  insert_and_index_algorithm($algoname,$datasetname,$i);
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
            if($numlines == -1) {$numlines=$data->length();}
            if($numlines > $data->length() ) {$numlines=$data->length();}
            print "Dataset ".$data->width().":".$data->length().", numlines=$numlines\n";
            # create table and return database connection handler (to decrease waiting time)
            my $dbh=$class->init_table($data);
            $logresults->start_benchmark();
            $class->insert_from_data($dbh,$data,$numlines);
            $logresults->end_benchmark();
            
 
            $logresults->logdata( "INSERT",$algoname,$datasetname,$numlines,$class->table_size($dbh,$data),"");
            
            foreach my $indexParam (@$indexParams) {
                my $parameter={ %$indexParam };
                # save parameters in the one line string
                my $text =Dumper($parameter);
                $text=~s/\n| |\t|\;//g;
                $text=~s/|\$(VAR1)(=)//g;
                print "$text\n";
                $class->drop_index($dbh,$data,$parameter);
                $logresults->start_benchmark();
                $class->create_index($dbh,$data,$parameter);
                $logresults->end_benchmark();
            
                $logresults->logdata( "INDEX",$algoname,$datasetname,$numlines,$class->index_size($dbh,$data),$text);
            }       
            
        }

    } else {
        print "Algorith $algoname skipped, there is no DB configuration\nCreate file $dirname/algorithm/$algoname/db.ini with content\n[postgresql]
dbname=dataBaseNameForThisAlgorithm
user=userName
pass=userPassword
";
    }
 }
 
}


sub lognumber {
    open(LOGNUM,"<logrun.txt");
    my $number=<LOGNUM>;
    close(LOGNUM);
    $number=$number+1;
    open(LOGNUM,">logrun.txt");
    print LOGNUM $number;
    close(LOGNUM);
    return $number;

}