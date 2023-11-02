
use PDL;
use PDL::IO::HDF5;
use PDL::NiceSlice;
use PDL::IO::Dumper;

#my $newfile = new PDL::IO::HDF5("../../../../benchmark/ann-benchmarks/data/glove-100-angular.hdf5");        #  open existing file.
#my $newfile = new PDL::IO::HDF5("../../vectordata/glove-100-angular.hdf5");        #  open existing file.
my $newfile = new PDL::IO::HDF5("../../vectordata/lastfm-64-dot.hdf5");        #  open existing file.
my @attrValue = $newfile->attrGet('distance'); 

#print join('-',@attrValue);
#print scalar(@attrValue);

my @groups = $newfile->groups;  
my @datasets =  $newfile->datasets; 
print scalar(@datasets);
print @datasets;
foreach my $datasetName (@datasets) {
    my $dataset=$newfile->dataset($datasetName);
    if( $datasetName eq "test") {
      my ($width,$length)=$dataset->dims();  
      my ($widthFirst,$widthLast)=(0,$width-1);

      print $datasetName." ($width,$length) ";  
      
      print join(" ", $dataset->dims());
      print "\n";
      $length=3;
      my $pdl = $dataset->get();
      for(my $record=0;$record<$length;++$record){
        my $line=$pdl->($widthFirst:$widthLast,($record));
       unless($record % 100000) { print "$record\n";}
       $line=~ s/\[[ ]*/\{/g;
       $line=~ s/[ ]*\]/\}/g;
       $line=~ s/[ ]+/,/g;
       print "$line\n";
       exit;
      }
    }
}