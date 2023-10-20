
#use strict;
use File::Basename;
use Cwd 'abs_path';
use Config::IniFiles;

BEGIN {
my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;
unshift (@INC,$dirname."/algorithm/");
}

#use pgvector_hnsw::benchmark;

my $dirname = dirname(abs_path(__FILE__));
my (@algodirs)=<$dirname/algorithm/*>;


foreach my $algodir (@algodirs) {
 my $algoname=basename($algodir);
 if(-f $dirname."/algorithm/$algoname/benchmark.pm") {
  print "$algoname dir ";
  my $module="${algoname}::benchmark";
  eval "require $module";
  if( $@ ) {  die $@; }
  my ($class)="$module"->new();
  print " , class name >>".$class->name()."<<\n";
 }
 
}