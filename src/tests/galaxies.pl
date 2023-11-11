use DBI;
use strict;

use PDL;
use PDL::IO::HDF5;
use PDL::NiceSlice;
use PDL::IO::Dumper;

# .dbaccess file has 1 line with user name and password delimited by colon ":", f.e.:
#user:pass
#
open(IN,"<../../.dbaccess");
my($line,@access);
$line=<IN>;
close(IN);
@access=split(/:/,$line);

my $dbh = DBI->connect('dbi:Pg:dbname=galaxies', $access[0], $access[1], {AutoCommit => 1});

#createfile("./delme_".time.".hdf5","l2");
createfile("../../vectordata/galaxies-3-5000-e.hdf5","l2");

sub createfile {
    my ($filename,$distance)=@_;
my $newfile = new PDL::IO::HDF5($filename);        #  open existing file.
$newfile->attrSet('distance' => (($distance eq 'l2')?'euclidean':'angular'));  # or angular
$newfile->attrSet('point_type' => 'float'); 

# select vector
{
my $sth = $dbh->prepare("select a.id,a.v from public.galaxies_train_$distance as a order by a.id");
my $x1 ; #=pdl(float,[ [ () ]]);
$sth->execute();
while (my @row = $sth->fetchrow_array()) {
   
     if(defined($x1)){
            #$x1=$x1->glue(1,pdl(float,[ [ $row[1] ]])); 
            #$x1=$x1->append(pdl(float,[ [ $row[1] ]])); 
            #$x1=$x1->append( [[ ${$row[1]}[0],${$row[1]}[1],${$row[1]}[2] ]]); 
            $x1=$x1->glue(1,pdl(float,[ [ ${$row[1]}[0],${$row[1]}[1],${$row[1]}[2] ]])); 
     } else {
          $x1=pdl(float, [ [ ${$row[1]}[0],${$row[1]}[1],${$row[1]}[2]  ]]);      
          
     }
}
my $dataset1=$newfile->dataset("train");
$dataset1->set($x1,unlimited=>1);
}

{
my $sth = $dbh->prepare("select a.id,a.v from public.galaxies_test_$distance as a order by a.id");
my $x1 ; #=pdl(float,[ [ () ]]);
$sth->execute();
while (my @row = $sth->fetchrow_array()) {
    #print($row[0]." ".vector($row[1]) . "\n");
   
     if(defined($x1)){
            #$x1=$x1->glue(1,pdl(float,[ [ $row[1] ]])); 
            #$x1=$x1->append(pdl(float,[ [ $row[1] ]])); 
            #$x1=$x1->append( [[ ${$row[1]}[0],${$row[1]}[1],${$row[1]}[2] ]]); 
            $x1=$x1->glue(1,pdl(float,[ [ ${$row[1]}[0],${$row[1]}[1],${$row[1]}[2] ]])); 
     } else {
          $x1=pdl(float, [ [ ${$row[1]}[0],${$row[1]}[1],${$row[1]}[2]  ]]);      
          
     }
}
my $dataset1=$newfile->dataset("test");
$dataset1->set($x1,unlimited=>1);
}

{
my $sth = $dbh->prepare("select a.id,a.neighbours,a.distances from public.galaxies_test_distances_$distance as a order by a.id");
my $x1; 
my $x2;
$sth->execute();
while (my @row = $sth->fetchrow_array()) {
    #print($row[0]." ".vector($row[1]) . "\n");
    
     if(defined($x1)){
            #$x1=$x1->glue(1,pdl(float,[ [ $row[1] ]])); 
            #$x1=$x1->append(pdl(float,[ [ $row[1] ]])); 
            #$x1=$x1->append( [[ ${$row[1]}[0],${$row[1]}[1],${$row[1]}[2] ]]); 
            $x1=$x1->glue(1,pdl(long,[ [ @{$row[1]} ]])); 
            $x2=$x2->glue(1,pdl(float,[ [ @{$row[2]} ]])); 
     } else {
          $x1=pdl(long, [ [ @{$row[1]}  ]]);      
          $x2=pdl(float, [ [ @{$row[2]} ]]);      
          
     }
}
my $dataset1=$newfile->dataset("neighbors");
$dataset1->set($x1,unlimited=>1);
my $dataset2=$newfile->dataset("distances");
$dataset2->set($x2,unlimited=>1);
}
}

$dbh->disconnect;
