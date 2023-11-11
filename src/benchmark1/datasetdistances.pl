


use strict;
use File::Basename;
use Cwd 'abs_path';
use Config::IniFiles;
use Time::HiRes qw(time);
use POSIX qw(strftime);

use PDL;
use PDL::IO::HDF5;
use PDL::NiceSlice;
use PDL::IO::Dumper;

BEGIN {
my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;
unshift (@INC,$dirname."/algorithm/");
unshift (@INC,$dirname."/");
$| = 1; # autoflush STDOUT
}

use modules::vectordata;
use modules::distance;

my $datasetname="fashion-mnist-784-e";

my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;

my $datatest=modules::vectordata->new($datasetname,'test');
my $datatrain=modules::vectordata->new($datasetname,'train');
my $datadistances=modules::vectordata->new($datasetname,'distances');
my $dataneighbours=modules::vectordata->new($datasetname,'neighbors');
for(my $j=0;$j<1;++$j){
my $testRecord=$datatest->getline_format2($j);
my $testRecordNeighbours=$dataneighbours->getline_format2($j);
my $testRecordDistances=$datadistances->getline_format2($j);

#print $testRecordNeighbours;
#print "\n";
#print $testRecordDistances;
#print "\n";
my $calculatedDistances = pdl(float,[ [ () ]]); # empty column 
my ($i,$length)=(0,$dataneighbours->width());
for($i=0;$i<$length;++$i){
    my $n=$testRecordNeighbours->at($i);
    #print " $n ";
    #print "\n";
    my $trainRecord=$datatrain->getline_format2($n);
    #print $trainRecord;
#print "\n";    
    my $distance=modules::distance::distance('a',$testRecord,$trainRecord);
    $calculatedDistances=$calculatedDistances->append($distance);
    #print " $distance";
    #print "";
}
#print $calculatedDistances;
#print "\nError\n";
print modules::distance::distance('l2',$calculatedDistances,$testRecordDistances);
print " ";
}


sub calculateDistances {
    my ($dataTrain,$neighbours)=@_;
    my $calculatedDistances = pdl(float,[ [ () ]]); # empty column 
    my $metric=$dataTrain->distancetype();
    foreach my $n (@$neighbors) {
        my $trainRecord=$dataTrain->getline_format2($n);
        my $distance=modules::distance::distance($metric,$testRecord,$trainRecord);
        $calculatedDistances=$calculatedDistances->append($distance);
    }
    return calculatedDistances;
}

=pod

foreach my $algodir (@algodirs) {
 my $algoname=basename($algodir);
 my @benchmarkRecords= (-1); 
 my $queryRecordCount = 10; # query 10 lines, compare with correct lines
 foreach my $i (@benchmarkRecords) {
  index_and_query_algorithm($algoname,$datasetname,$i,$queryRecordCount);
 }
}

sub index_and_query_algorithm {
    my ($algoname,$datasetname,$numlines,$queryRecordCount) = @_;
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
            my $data=modules::vectordata->new($datasetname,'train');
            if($numlines>$data->length()){
                return 0;
            }
            if($numlines == -1) {$numlines=$data->length();}
            print "Dataset ".$data->width().":".$data->length().", numlines=$numlines\n";
            # create table and return database connection handler (to decrease waiting time)
            $class->init_connection();
            $class->init_table($data);
            $class->drop_index($data); # if init_table does not drop index
            $logresults->start_benchmark();
            $class->insert_from_data($data,$numlines);
            $logresults->end_benchmark();
            
 
            $logresults->logdata( "INSERT",$algoname,$datasetname,$numlines,$numlines,$class->table_size($data),"");
            
            foreach my $indexParam (@$indexParams) {
                my $parameter={ %$indexParam };
                # save parameters in the one line string
                my $text=parameters2text($parameter);
                print $text."\n";
                $class->drop_index($data,$parameter);
                $logresults->start_benchmark();
                $class->create_index($data,$parameter);
                $logresults->end_benchmark();
            
                $logresults->logdata( "INDEX",$algoname,$datasetname,$numlines,$numlines,$class->index_size($data),$text);
                my $datatest=modules::vectordata->new($datasetname,'test');
                foreach my $queryParam (@$queryParams) {
                    my $parameter={ %$indexParam, %$queryParam };
                    # save parameters in the one line string
                    my $text=parameters2text($parameter);
                    print "$text\n";
                    $class->query_parameter_set($parameter);
                    $logresults->start_benchmark();
                    my $totalTime=benchmark_query($class,$datatest,$parameter,$queryRecordCount);
                    $logresults->end_benchmark();
                    $logresults->logdata( "QUERY",$algoname,$datasetname,$numlines,$datatest->length(),$totalTime,$text);
                }
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

sub benchmark_query {
    my ($class,$data,$parameter,$queryRecordCount)=@_;
    # init variables
    my ($totalTime,$linesQuantity,$start,$stop,$vector)=(0.000000,$data->length(),0,0,'');
    # set parameter if needed
    # loop through test records set and query every line
    for(my $i=0;$i<$linesQuantity;++$i){
        # get vector
        $vector=$data->getline_format1($i);
        # start timer
        $start=time;
        # run query
        my $result=$class->query($data,$queryRecordCount,$vector);
        # stop counter and calculate time, calculate total time
        $stop=time;
        $totalTime+=($stop-$start);
        # add result arrays with id and distances to dataset
        #print join('-',@$result);print "\n";
        # end loop
    }
    # store dataset
    # return total time
    return $totalTime;
}

sub parameters2text {
    my ($paramref)=@_;
    my $retvalue='{';
    foreach my $key (sort keys %$paramref){
        if(length($retvalue)>1){
            $retvalue.=",";
        }
        $retvalue.="'".$key."'=>".$paramref->{$key};
    }
    $retvalue.="}";
    return $retvalue;
}

=cut
