
use strict;

my (@lines,%datarecall,%speed,%maxspeed, $parameters,$m);

open(IN, "<../../results/logdata.txt");
@lines = <IN>;
close(IN);

for(my $i=1;$i<=$#lines;++$i)
{
    my (@line,@fileds);
    @line = split(/\t/,$lines[$i]);
    if($line[0] >=116 && $line[1] eq "INDEXWAL" )
    {
        #print $line[1],$line[2],$line[3]*100000,$line[4],"\n";
        #if(!exists($datarecall{$line[1]}{$line[3]}) || $datarecall{$line[1]}{$line[3]}<$line[4] )
        $parameters=eval($line[10]);
        #print %$parameters; print "\n";
        {
            $datarecall{$line[2]}{$parameters->{m}}=$line[8];
        }
    }
}

#print %{%datarecall{'pgvector_hnsw'}};
my @all=reverse sort keys(%{%datarecall{'pgvector_hnsw'}});
#print $all[0];
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
open(OUT,">../../results/fashion-mnist-784-e/10/benchmarkwalunit.csv");
print OUT "Algorithm\tM\tWalSize\tWalSizeMb\n";
foreach $m ( @all)
{
    print " M=$m\n";
    
    #print 1-$j/100000;
    #print "\t";
    foreach my $algo ( sort keys %datarecall)
    {
        if($algo ne 'pgvector_hnsw' && exists($datarecall{$algo}{$m}) )
        {
            print OUT $algo."\t".($m)."\t".($datarecall{$algo}{$m} / $datarecall{'pgvector_hnsw'}{$m} )."\t".($datarecall{$algo}{$m}/1024/1024)."\n";
            #print  $algo."\t".($m)."\t".($datarecall{$algo}{$m} / $datarecall{'pgvector_hnsw'}{$m} )."\t".($datarecall{$algo}{$m}/1024/1024)."\n";
        }
        #print "\t"; 
    }
    #print "\n"
    
}
close(OUT);