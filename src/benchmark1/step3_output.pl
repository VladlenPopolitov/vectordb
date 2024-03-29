
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
use modules::distance;

my $dirname = dirname(abs_path(__FILE__));

# read config from db.ini
my $configAdmin = Config::IniFiles->new( -file => $dirname."/db.ini" );
my $datasetname=$configAdmin->val("step3","datasetname");
$datasetname="lastfm" unless defined($datasetname);
my $algorithmIncludeRegex=$configAdmin->val("step3","algorithmIncludeRegex");
$algorithmIncludeRegex=".*" unless defined($algorithmIncludeRegex);
my $algorithmExcludeRegex=$configAdmin->val("step3","algorithmExcludeRegex");
$algorithmExcludeRegex="<>" unless defined($algorithmExcludeRegex);
my $queryRecordCount=$configAdmin->val("step3","queryRecordCount");
$queryRecordCount=10 unless defined($queryRecordCount); # query 10 lines, compare with correct lines
my $tolerance=$configAdmin->val("step3","tolerance");
$tolerance=0.0001 unless defined($tolerance); # tolerance to compare distance difference


my (@algodirs)=<$dirname/../../results/$datasetname/$queryRecordCount/*>;
my $dataDistances=modules::vectordata->new($datasetname,'distances');

# create output file
unless(-f "$dirname/../../results/$datasetname/$queryRecordCount/benchmark.csv") {
    open(RESULT,">","$dirname/../../results/$datasetname/$queryRecordCount/benchmark.csv");
    print RESULT "Dataset\tAlgorithm\tParameters\tRecall\tRecordsPerSecond\tIndexTime\tInsertTime\n";
    close(RESULT);
}

foreach my $algodir (@algodirs) {
    if(-d $algodir){
        my $algoname=basename($algodir);
        if($algoname =~ m/$algorithmIncludeRegex/){
            unless($algoname =~ m/^$algorithmExcludeRegex$/){      
                scan_and_collect_data($algodir,$dataDistances,$queryRecordCount);
            } else {
                print "Algorith $algoname skipped due to db.ini algorithmExcludeRegex setting (excluded)\n";
            }
        } else {
            print "Algorith $algoname skipped due to db.ini algorithmIncludeRegex setting (not included)\n";
        }
    }
}

sub scan_and_collect_data {
    my ($algodir,$dataDistances,$queryRecordCount) = @_;
    my $algoname=basename($algodir);
    my $outputfilename=$algodir."/../benchmark.csv";
       print "$algoname dir ";
       my (@resultfiles)=<$algodir/*.hdf5>;
       foreach my $resultfile (@resultfiles) {
            
            
            print "\nDataset ".$dataDistances->width().":".$dataDistances->length()." File $resultfile\n";
            # create table and return database connection handler (to decrease waiting time)
            my ($dataset,$algorithm,$parameters,$recall,$queryPerSecond,$indexTime,$insertTime)=scan_file($resultfile,$dataDistances);
            #open(LOG,">>",$outputfilename);
            #print LOG "$dataset\t$algorithm\t$parameters\t$recall\t$queryPerSecond\t$indexTime\t$insertTime\n";
            #close(LOG);
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
    'distance' => $newfile->attrGet('distance'),
    'indextime' => $newfile->attrGet('indextime'),
    'inserttime' => $newfile->attrGet('inserttime'),
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
        print sprintf "%5d %d ",$i,$recallLine if $recallLine<9;
        $recallTotal += $recallLine+1;
    }
    return ($attr->{dataset},$attr->{algorithm}, $attr->{parameters}, $recallTotal/$length/($lastColumn+1) , $attr->{queries}/$attr->{totalTime}, $attr->{indextime}, $attr->{inserttime} ) ;
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

