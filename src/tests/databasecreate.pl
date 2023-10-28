
use strict;
use PDL;
use PDL::IO::HDF5;
use PDL::NiceSlice;
use PDL::IO::Dumper;
my $x = ones(1,10);
my $y = ones(3,3);

my $newfile = new PDL::IO::HDF5("./delme_".time.".hdf5");        #  open existing file.
$newfile->attrSet('AttrNameS' => 'AttrValue'); 
$newfile->attrSet('AttrNameI' => 100); 
$newfile->attrSet('AttrNameF' => 1000.0); 
$newfile->attrSet('AttrNameB' => 1); 
$newfile->attrSet('AttrNamePDL' => $x); 
$newfile->attrSet('AttrNamePDL33' => $y); 

# save attributes from hash
my $a = {float=>pdl(float,1),long=>pdl(long,2),byte=>pdl(byte,1)};
$newfile->attrSet(%$a); 
# save array of integer32
my @x1array=(1,2,3,4,5,6,7,8,9);
my $x1 = pdl(long,[ [@x1array] ] );
my $x2 = pdl(long,[ [@x1array] ] )*2;
$x1=$x1->glue(1,$x2);
my $dataset1=$newfile->dataset("integers");
$dataset1->set($x1,unlimited=>1);
# save  array of float32
{
    my @x1array=(1,2,3,4,5,6,7,8,9);
my $x1 = pdl(float,[ [@x1array] ] );
my $x2 = pdl(float,[ [@x1array] ] )*2.1234;
$x1=$x1->glue(1,$x2);
my $dataset1=$newfile->dataset("float");
$dataset1->set($x1,unlimited=>1);
}
# operations with arrays (add and multiply)

