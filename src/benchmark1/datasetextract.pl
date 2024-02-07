


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

extract_data($datatest, $datasetname.'_test.txt');
extract_data($datatrain, $datasetname.'_train.txt');
extract_data($datadistances, $datasetname.'_distances.txt');
extract_data($dataneighbours, $datasetname.'_neighbors.txt');

sub extract_data {

     my ($dataset1,$filename) = @_ ; # $newfile->dataset("distances");
    my $datasetpdl = $dataset1->recorddata();
    my ($width,$length)=$datasetpdl->dims;
    my ($recallTotal,$widthFirst,$lastColumn)=(0,0,$width-1);
    open(OUT,">$filename");
    for(my $i=0;$i<$length;++$i){
        my $dataLine=$dataset1->getline_format2($i);
        for(my $j=$widthFirst;$j<=$lastColumn;++$j){
            print OUT $dataLine->at($j);
            if($j<$lastColumn) {
                print OUT "\t";
            } else {
                print OUT "\n";
            }
        }
    }
    close(OUT);
}

=pod
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




foreach my $algodir (@algodirs) {
 my $algoname=basename($algodir);
 
 if($algoname eq 'vectordb'){
  insert_neighbours_to_algorithm_database($algoname,$datadistances,$dataneighbours);
 }
 
}
=cut
sub insert_neighbours_to_algorithm_database {
    my ($algoname,$datadistances,$dataneighbours) = @_;
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
        my $numlines=$datadistances->length();
        {
            #my $data=modules::vectordata->new($datasetname,'train');
           
            if($numlines == -1) {$numlines=$datadistances->length();}
            print "Dataset ".$datadistances->width().":".$datadistances->length().", numlines=$numlines\n";
            # create table and return database connection handler (to decrease waiting time)
            $class->init_connection();
            #$class->init_table($data);
            #$class->drop_index($data); # if init_table does not drop index
            #$logresults->start_benchmark();
            insert_results_from_data($class,$algoname,$datadistances,$dataneighbours,$numlines);
            #$logresults->end_benchmark();
            
 
            #$logresults->logdata( "INSERT",$algoname,$datasetname,$numlines,$numlines,$class->table_size($data),"");
            
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

sub insert_results_from_data {
    my ($self, $algoname,$datadistances,$dataneighbours, $totalLines) = @_;
    my $dbh=$self->{dbh};
    #my $table = $data->tablename();
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        #my ($widthFirst,$widthLast)=(0,$pdl->width()-1);
        my $sth=$dbh->do("COPY public.datatable_results (id,neighbours,distances) FROM STDIN");
        for(my $record=0;$record<$totalLines;++$record){
            my $linen=$dataneighbours->getline_format3($record) ; # {pdlref}->($widthFirst:$widthLast,($record)); $line=~ s/[ ]+/,/g;
            my $lined=$datadistances->getline_format3($record) ; # {pdlref}->($widthFirst:$widthLast,($record)); $line=~ s/[ ]+/,/g;
            $dbh->func($record."\t".$linen."\t".$lined."\n", 'putline');
        }
        $dbh->func("\\.\n", 'putline');
        $dbh->func('endcopy');
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

=pod
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
