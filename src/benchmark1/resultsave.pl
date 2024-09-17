
use strict;

my (@lines,%datarecall,%speed,%maxspeed);

open(IN, "<../../results/fashion-mnist-784-e/10/benchmark.csv");
@lines = <IN>;
close(IN);

for(my $i=1;$i<=$#lines;++$i)
{
    my (@line,@fileds);
    @line = split(/\t/,$lines[$i]);
    #print $line[1],$line[2],$line[3]*100000,$line[4],"\n";
    if(!exists($datarecall{$line[1]}{$line[3]}) || $datarecall{$line[1]}{$line[3]}<$line[4] )
    {
        $datarecall{$line[1]}{$line[3]*100000}=$line[4];
    }
}

#print %{%datarecall{'pgvector_hnsw'}};
my @all=reverse sort keys(%{%datarecall{'pgvector_hnsw'}});
print $all[0];
#my $maxX = ${sort keys(%{%datarecall{'pgvector_hnsw'}})}[0]; 
#print $maxX;
foreach my $algo ( sort keys %datarecall)
{
    $maxspeed{$algo} =  1;
}
my $speedchanged;
#print "Recall\t";    
#foreach my $algo ( sort keys %datarecall) { print "$algo\t"}    
#print "\n";
open(OUT,">../../results/fashion-mnist-784-e/10/benchmarkunit.csv");
print OUT "Algorithm\tRecall\tSpeed\n";
for(my $j=$all[0];$j>85800;--$j)
{
    $speedchanged = 0;
    foreach my $algo ( sort keys %datarecall)
    {
        if( exists($datarecall{$algo}{$j}) && $maxspeed{$algo} <  $datarecall{$algo}{$j} )
        {
            $speedchanged = 1;
            $maxspeed{$algo} = $datarecall{$algo}{$j};
        }    
    }
    if($speedchanged)
    {
    
    #print 1-$j/100000;
    #print "\t";
    foreach my $algo ( sort keys %datarecall)
    {
        if($algo ne 'pgvector_hnsw')
        {
            print OUT $algo."\t".(1-$j/100000)."\t".($maxspeed{$algo}/$maxspeed{'pgvector_hnsw'})."\n";
        }
        #print "\t"; 
    }
    #print "\n"
    }
}
close(OUT);