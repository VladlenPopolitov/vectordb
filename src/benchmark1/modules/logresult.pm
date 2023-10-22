package modules::logresult;
# for benchmark
use Time::HiRes qw(time);
use POSIX qw(strftime);

sub new {
    my ($class) = shift;
    my ($dir) = @_;
    my $self = { 
        numfilename => '',
        filename => '',
        runNumber => 0,
        loaded => 0 ,
        start => 0 ,
        end => 0
     };
     $self->{numfilename}="$dir/../../results/logrun.txt";
     if( defined($dir)){
        unless( -f $self->{numfilename} ) {
            open(LOGNUM,">".$self->{numfilename}) || die("Cannot open ".">".$self->{numfilename});
            print LOGNUM "0";
            close(LOGNUM);
        }
        open(LOGNUM,"<".$self->{numfilename}) || die("Cannot open logrun.txt");
        $self->{runNumber}=<LOGNUM>;
        close(LOGNUM);
        $self->{runNumber}=$self->{runNumber}+1;
        open(LOGNUM,">".$self->{numfilename}) || die("Cannot open logrun.txt");
        print LOGNUM $self->{runNumber};
        close(LOGNUM); 
        $self->{filename}= $dir."/../../results/logdata.txt"; 
        $self->{loaded}= 1 ; 
     }
     
    bless $self, $class;
    return $self;
}

sub logdata {
    my ($self,$logname,$algoname,$datasetname,$numlines,$size,$parameters)=@_;
    my $timediff = $self->{end} - $self->{start};
    if($self->{loaded}) {
    open(LOG,">>".$self->{filename}) || die("Cannot open logresult.txt");
    print LOG $self->{runNumber}."\t$logname\t$algoname\t$datasetname\t$numlines\t".($timediff)."\t".($numlines/$timediff)."\t".$size."\t".($size/$numlines)."\t".$parameters."\n";
    close(LOG);
    } else {
        die "logresults object is not initialized.";
    }
}

sub start_benchmark {
    my ($self)=@_;
    $self->{start}=time;
}

sub end_benchmark {
    my ($self)=@_;
    $self->{end}=time;
}

1;

