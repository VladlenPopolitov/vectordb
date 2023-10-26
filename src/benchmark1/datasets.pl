
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
my $dirname = dirname(abs_path(__FILE__));
if($#ARGV==-1){
my $datasetsnum=modules::vectordata::LENGTH();
for(my $i=0;$i<$datasetsnum;++$i){
    my $dataset=modules::vectordata->new(modules::vectordata::NAME($i));
    print sprintf "%02d %-15s %-15s %-50s %-5s\n" , $i+1, $dataset->name(),modules::vectordata::NAME($i),
    (-f $dirname."/".$dataset->filename())?$dataset->filename():
    "run `perl dataset.pl ".$dataset->name()."` to download dataset",
    $dataset->filesize() ;
}
} else {
    my $downloadname=$ARGV[0];
    my $dataset=modules::vectordata->new($downloadname);
    if($downloadname eq $dataset->name()){
        if($dataset->loaded()){
            print "Dataset $downloadname already downloaded to folder ../../vectordata\n";
        } else {
            print "Downloading $downloadname\n";
            DownloadFile($dataset,$dirname);
        }

    } else {
        print "Dataset $downloadname is not known. Run `perl datasets.pl` to see datasets list.\n";
    }
}

sub DownloadFile {
    my ($dataset,$dirname) =@_;
    my ($filename,$http)=($dirname.'/'.$dataset->filename(), $dataset->http());
    print "Download $http to $filename\n";
    open(WGET,"which wget|");
    my $wgetname=<WGET>;
    close(WGET);
    if(length($wgetname)==0){
        print "wget is not installed. I use wget do download dataset. Install it and run again.\n."
    } else {
        chop($wgetname);
        if(-f $wgetname){
            system("$wgetname -v -O $filename $http");

        }
        
    }
}
