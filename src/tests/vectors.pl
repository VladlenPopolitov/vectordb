
use strict;
use PDL;
#use PDL::IO::HDF5;
#use PDL::NiceSlice;
#use PDL::IO::Dumper;

my @x1array=(1,0,0);
my @x2array=(0,2,0);
my $x1 = pdl(float,[ [@x1array] ] );
my $x2 = pdl(float,[ [@x2array] ] );
my $xdiff=$x1-$x2;
#print $xdiff;
my $square = $xdiff * $xdiff;
my $sumover = $square->sumover();
#print $sumover;
my $distance=$sumover->sqrt();
#print $distance;
print distance('a',$x1,$x2);
print "\n";
print distance('l2',$x1,$x2);
print "\n";

sub angular {
    my ($x1,$x2)=@_;
    my $dot = $x2 x transpose($x1) ;
    $dot=$dot/(norm($x1)*norm($x2));
    $dot=1.0-$dot;
    return $dot->sumover();
}

sub norm {
    my ($x)=@_;
    my $square = $x * $x;
    my $sumover = $square->sumover();
    my $distance=$sumover->sqrt();
    return $distance;
}
    
sub euclidean {
    my ($x1,$x2)=@_;
    my $xdiff=$x1-$x2;
    my $distance=norm($xdiff);
    return $distance;
}

sub distance {
    my ($metric,$x1,$x2)=@_;
    if($metric eq 'l2'){
        return euclidean($x1,$x2);
    } elsif($metric eq 'a') {
        return angular($x1,$x2);
    } else {
        die('Unknown metric '.$metric);
    }
}
