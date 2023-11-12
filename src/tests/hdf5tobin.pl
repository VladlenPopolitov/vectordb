
use strict;
use PDL;
use PDL::IO::HDF5;
use PDL::NiceSlice;
use PDL::IO::FastRaw;
use PDL::IO::FlexRaw;

my ($filein,$fileout);
$filein="../../vectordata/lastfm-64-dot.hdf5";
$fileout=$filein.".train.bin";
savebin($filein,$fileout,'train');

$fileout=$filein.".test.bin";
savebin($filein,$fileout,'test');

sub savebin {
  my ($filein,$fileout,$recordName)=@_;
  my $newfile = new PDL::IO::HDF5($filein);        #  open existing file.
  my @attrValue = $newfile->attrGet('distance'); 

#print join('-',@attrValue);
#print scalar(@attrValue);

my @groups = $newfile->groups;  
my @datasets =  $newfile->datasets; 
print scalar(@datasets);
print @datasets;
foreach my $datasetName (@datasets) {
    my $dataset=$newfile->dataset($datasetName);
    if( $datasetName eq $recordName) {
      my ($width,$length)=$dataset->dims();  
      my ($widthFirst,$widthLast)=(0,$width-1);
      open(OUT,">",$fileout);
      binmode(OUT);
      print OUT pack('i', $length);  
      print OUT pack('i', $width);  

      print $datasetName." ($width,$length) ";  
      
      print join(" ", $dataset->dims());
      print "\n";
      
      my $pdl = $dataset->get();
      for(my $record=0;$record<$length;++$record){
        my $line=$pdl->($widthFirst:$widthLast,($record));

    

       unless($record % 100) { print "$record\n";}
           #my @pdls = ($line);
           #my $hdr = writeflex(OUT,@pdls);
       #    $PDL::IO::FlexRaw::writeflexhdr = 1; # set so we don't have to call writeflexhdr
       # my $hdr = glueflex($fileout, $line,'');  # remember, $file must be filename
#glueflex($file, $pdl[, $hdr])         # remember, $file must be filename
       for(my $column=0;$column<$width;++$column){
        print OUT pack('f', sclr($line->($column:$column)));  
       }
       #$line=~ s/\[[ ]*/\{/g;
       #$line=~ s/[ ]*\]/\}/g;
       #$line=~ s/[ ]+/,/g;
       #print $line->(0:0);print ">>";
       # print $line->(0:0)*1.0000000;print ">>";
       
       #print $line->(1:1);
       #exit;
      }
      close(OUT);
    }
}
}
#close(OUT);