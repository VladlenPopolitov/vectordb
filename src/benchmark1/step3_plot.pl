


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
#use modules::logresult;
use modules::distance;


my $datasetname="lastfm";
my $queryRecordCount = 10; # query 10 lines, compare with correct lines
my $tolerance=0.0001; # tolerance to compare distance difference
my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/../../results/$datasetname/$queryRecordCount/*>;
my $dataDistances=modules::vectordata->new($datasetname,'distances');

# create output file
unless(-f "$dirname/../../results/$datasetname/$queryRecordCount/benchmark.csv") {
    open(RESULT,">","$dirname/../../results/$datasetname/$queryRecordCount/benchmark.csv");
    print RESULT "Dataset\tAlgorithm\tRecall\tRecordsPerSecond\n";
    close(RESULT);
}

foreach my $algodir (@algodirs) {
    unless($algodir =~ /.*benchmark\.csv/){
        scan_and_collect_data($algodir,$dataDistances,$queryRecordCount);
    }
}

sub scan_and_collect_data {
    my ($algodir,$dataDistances,$queryRecordCount) = @_;
    my $algoname=basename($algodir);
    my $outputfilename=$algodir."/../benchmark.csv";
       print "$algoname dir ";
       my (@resultfiles)=<$algodir/*>;
       foreach my $resultfile (@resultfiles) {
            
            
            print "Dataset ".$dataDistances->width().":".$dataDistances->length()." File $resultfile\n";
            # create table and return database connection handler (to decrease waiting time)
            scan_file($resultfile,$dataDistances);
            
        }
 return 1;
}

sub scan_file {
    my ($filename,$dataDistances)=@_;
    my $newfile = new PDL::IO::HDF5($filename);        #  open existing file.
    my $attr={
    'parameters' => $newfile->attrGet('parameters'), 
    'parameters2filename' => $newfile->attrGet('parameters2filename'), 
    'algorithm' => $newfile->attrGet('algorithm'),
    'queryCount' => $newfile->attrGet('queryCount'),
    'totalTime' => $newfile->attrGet('totalTime'),
    'queries' => $newfile->attrGet('queries'),
    'dataset' => $newfile->attrGet('dataset'),
    'distance' => $newfile->attrGet('distance')
    } ; 
    #print parameters2text($attr);
    my $dataset1=$newfile->dataset("distances");
    my $datasetpdl = $dataset1->get();
    my ($width,$length)=$dataset1->dims;
    my ($recallTotal,$widthFirst,$lastColumn)=(0,0,$attr->{queryCount}-1);
    for(my $i=0;$i<$length;++$i){
        my $distancesLine=$dataDistances->getline_format2($i);
        my $lastDistance=$distancesLine->at($lastColumn)+$tolerance;
        
        my $resultLine=$datasetpdl->($widthFirst:$lastColumn,($i));
        my $recallLine=$lastColumn;
        while($recallLine>=0){
            last if $resultLine->at($recallLine)<=$lastDistance ;
            --$recallLine;
        }
        print $recallLine.">".$resultLine->at($recallLine)."<=".$lastDistance.":";
        print "$i $lastDistance $widthFirst , $lastColumn,$i ($recallLine) >> ";
        $recallTotal += $recallLine+1;
    }
    print "Recall=".($recallTotal/$length/($lastColumn+1))."\n";
    
}


sub benchmark_query {
    my ($class,$dataTest,$dataTrain,$parameter,$queryRecordCount)=@_;
    # init variables
    my ($totalTime,$linesQuantity,$start,$stop,$vector,$testRecord)=(0.000000,$dataTest->length(),0,0,'','');
    my ($resultNeighbors,$resultDistances); # PDL variables wit result
    # set parameter if needed
    # loop through test records set and query every line
    for(my $i=0;$i<100 #$linesQuantity
    ;++$i){
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
    'distance' => $dataTrain->distancetype()
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

