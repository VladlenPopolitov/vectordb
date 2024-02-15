

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
use File::Path('make_path');

BEGIN {
my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;
unshift (@INC,$dirname."/algorithm/");
unshift (@INC,$dirname."/");
$| = 1; # autoflush STDOUT
}

use modules::vectordata;
use modules::logresult;
use modules::distance;



my $dirname = dirname(abs_path(__FILE__));

# read config from db.ini
my $configAdmin = Config::IniFiles->new( -file => $dirname."/db.ini" );
my $datasetname=$configAdmin->val("step2","datasetname");
$datasetname="lastfm" unless defined($datasetname);
my $algorithmIncludeRegex=$configAdmin->val("step2","algorithmIncludeRegex");
$algorithmIncludeRegex=".*" unless defined($algorithmIncludeRegex);
my $algorithmExcludeRegex=$configAdmin->val("step2","algorithmExcludeRegex");
$algorithmExcludeRegex="<>" unless defined($algorithmExcludeRegex);
my $queryRecordCount=$configAdmin->val("step2","queryRecordCount");
$queryRecordCount=10 unless defined($queryRecordCount); # query 10 lines, compare with correct lines


my (@algodirs)=<$dirname/algorithm/*>;

my $logresults=modules::logresult->new($dirname);

foreach my $algodir (@algodirs) {
 my $algoname=basename($algodir);
 if($algoname =~ m/$algorithmIncludeRegex/){
    unless($algoname =~ m/^$algorithmExcludeRegex$/){      
        index_and_query_algorithm($algoname,$datasetname,$queryRecordCount);
    } else {
        print "Algorith $algoname skipped due to db.ini algorithmExcludeRegex setting (excluded)\n";
    }
  } else {
    print "Algorith $algoname skipped due to db.ini algorithmIncludeRegex setting (not included)\n";
  }
 }

sub index_and_query_algorithm {
    my ($algoname,$datasetname,$queryRecordCount) = @_;
    my $numlines=-1; # -1 : use all lines
    if(-f $dirname."/algorithm/$algoname/benchmark.pm") {
    if( -f $dirname."/algorithm/$algoname/db.ini") {
        print "$algoname dir ";
        my $module="${algoname}::benchmark";
        eval "require $module";
        if( $@ ) {  die $@; }
        my $config = Config::IniFiles->new( -file => $dirname."/algorithm/$algoname/db.ini" );
        my $indexParamStr=$config->val("parameters","index");
        my $indexParams=eval($indexParamStr);
        print "\nindexParamStr=$indexParamStr\n";
        my $queryParamStr=$config->val("parameters","query");
        my $queryParams=eval($queryParamStr);

        my ($class)="$module"->new($config->val("postgresql","dbname"),$config->val("postgresql","user"),$config->val("postgresql","pass"));
        print " , class name >>".$class->name()."<<\n";
        {
            my $dataTrain=modules::vectordata->new($datasetname,'train');
            if($numlines>$dataTrain->length()){
                return 0;
            }
            if($numlines == -1) {$numlines=$dataTrain->length();}
            my $epoch = time();
            print strftime("%d-%m-%Y %H:%M:%S", localtime($epoch)) ." Dataset ".$dataTrain->width().":".$dataTrain->length().", numlines=$numlines\n";
            # create table and return database connection handler (to decrease waiting time)
            $class->init_connection();
            $class->init_table($dataTrain);
            $class->drop_index($dataTrain); # if init_table does not drop index
            $logresults->start_benchmark();
            $class->insert_from_data($dataTrain,$numlines);
            $logresults->end_benchmark();
            
 
            my $insertTime=$logresults->logdata( "INSERT",$algoname,$datasetname,$numlines,$numlines,$class->table_size($dataTrain),"");
            
            foreach my $indexParam (@$indexParams) {
                my $parameter={ %$indexParam };
                # current time
                my $epoch = time();
                my $microsecs = ($epoch - int($epoch)) *1e6;
                # save parameters in the one line string
                my $text=parameters2text($parameter);
                print strftime("%d-%m-%Y %H:%M:%S", localtime($epoch)) . "." . sprintf("%06.0f", $microsecs)." ".$text."\n";
                $class->drop_index($dataTrain,$parameter);
                my $walfrom=$class->wal_position();
                $logresults->start_benchmark();
                $class->create_index($dataTrain,$parameter);
                $logresults->end_benchmark();
                my $walto=$class->wal_position();
                my $walchange=$class->wal_position_change($walfrom,$walto);
                my $indexTime=
                    $logresults->logdata( "INDEX",$algoname,$datasetname,$numlines,$numlines,$class->index_size($dataTrain),$text);
                    $logresults->logdata( "INDEXWAL",$algoname,$datasetname,$numlines,$numlines,$walchange,$text,$dataTrain->vectorsize());
                my $datatest=modules::vectordata->new($datasetname,'test');
                foreach my $queryParam (@$queryParams) {
                    my $parameter={ %$indexParam, %$queryParam };
                    my $savedata={indextime=>$indexTime,inserttime=>$insertTime,tablesize=>$class->table_size($dataTrain),indexsize=>$class->index_size($dataTrain)};
                    # save parameters in the one line string
                    my $text=parameters2text($parameter);
                    $epoch = time();
                    print strftime("%d-%m-%Y %H:%M:%S", localtime($epoch))." $text\n";
                    $class->query_parameter_set($datatest,$parameter);
                    $logresults->start_benchmark();
                    my $totalTime=benchmark_query($class,$datatest,$dataTrain,$parameter,$queryRecordCount,$savedata);
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
    my ($class,$dataTest,$dataTrain,$parameter,$queryRecordCount,$savedata)=@_;
    # init variables
    my ($totalTime,$linesQuantity,$start,$stop,$vector,$testRecord)=(0.000000,$dataTest->length(),0,0,'','');
    my ($resultNeighbors,$resultDistances); # PDL variables wit result
    # set parameter if needed
    # loop through test records set and query every line
    for(my $i=0;$i<$linesQuantity;++$i){
        # get vector
        $vector=$dataTest->getline_format1($i);
        $testRecord=$dataTest->getline_format2($i);
        # start timer
        $start=time;
        # run query
        my $result=$class->query($dataTest,$queryRecordCount,$vector);
        # stop counter and calculate time, calculate total time
        $stop=time;
        $totalTime+=($stop-$start);
        if(scalar(@$result)!=$queryRecordCount){
            while(scalar(@$result)<$queryRecordCount){
                push(@$result,0);
            
            }

        }
        # add result arrays with id and distances to dataset
        my $distances=calculateDistances($dataTrain,$result,$testRecord);
        if(defined($resultNeighbors)){
            $resultNeighbors=$resultNeighbors->glue(1,pdl(long,[ [ @$result]])); 
        } else {
          $resultNeighbors=pdl(float,[ [ @$result]]);      
        }
        if(defined($resultDistances)){
            $resultDistances=$resultDistances->glue(1,$distances);
        } else {
          $resultDistances=$distances;      
        }
        # end loop
    }
    # store dataset
    store_dataset($class,$resultNeighbors,$resultDistances,{
    'parameters' => parameters2text($parameter), 
    'parameters2filename' => $dataTrain->distancetype().parameters2filename($parameter), 
    'algorithm' => $class->name(),
    'queryCount' => $queryRecordCount,
    'totalTime' => $totalTime,
    'queries' => $linesQuantity,
    'dataset' => $dataTrain->name(),
    'distance' => $dataTrain->distancetype(),
    %$savedata
    });
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

sub parameters2filename {
    my ($paramref)=@_;
    my $retvalue='';
    foreach my $key (sort keys %$paramref){
        $retvalue.="_".$paramref->{$key};
    }
    return $retvalue;
}


sub calculateDistances {
    my ($dataTrain,$neighbors,$testRecord)=@_;
    my $calculatedDistances = pdl(float,[ [ () ]]); # empty column 
    my $metric=$dataTrain->distancetype();
    foreach my $n (@$neighbors) {
        my $trainRecord=$dataTrain->getline_format2($n);
        my $distance=modules::distance::distance($metric,$testRecord,$trainRecord);
        $calculatedDistances=$calculatedDistances->append($distance);
    }
    return $calculatedDistances;
}

sub store_dataset {
    my ($class,$resultNeighbors,$resultDistances,$attributes)=@_;
    my ($dirname,$filename)=("../../results/".$attributes->{dataset}.'/'.$attributes->{queryCount}.'/'.$attributes->{algorithm}.'/',$attributes->{parameters2filename}.'.hdf5');
    make_path($dirname);
    unlink $dirname.$filename;
  my $newfile = new PDL::IO::HDF5($dirname.$filename);        #  open existing file.
=pod    
    $newfile->attrSet('parameters' => parameters2text($parameter)); 
    $newfile->attrSet('algorithm' => $class->name()); 
    $newfile->attrSet('queryCount' => $queryRecordCount); 
    $newfile->attrSet('totalTime' => $totalTime); 
    $newfile->attrSet('queries' => $linesQuantity); 
    $newfile->attrSet('dataset' => $dataTrain->name()); 
    $newfile->attrSet('distance' => $dataTrain->distancetype()); 
=cut    
    $newfile->attrSet(%$attributes); 
    my $dataset1=$newfile->dataset("neighbors");
    $dataset1->set($resultNeighbors,unlimited=>1);
    my $dataset2=$newfile->dataset("distances");
    $dataset2->set($resultDistances,unlimited=>1);
}