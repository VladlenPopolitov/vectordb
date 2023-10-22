
use strict;
use File::Basename;
use Cwd 'abs_path';
use Config::IniFiles;
use Data::Dumper;

my $dirname = dirname(abs_path(__FILE__));
my $config = Config::IniFiles->new( -file => $dirname."/../benchmark1/algorithm/pgvector_i/db.ini" );
my $indexParamStr=$config->val("parameters","index");
print "$indexParamStr\n";

my $indexParams=eval($indexParamStr);

#print Dumper($indexParams);

#print @$indexParams[0]; print "\n";
#print Dumper(@$indexParams[0]); print "\n";

foreach my $indexParam (@$indexParams) {
    print Dumper($indexParam); 
    print $indexParam->{list}."\n";
}

my $queryParamStr=$config->val("parameters","query");
print "$queryParamStr\n";

my $queryParams=eval($queryParamStr);

#print Dumper($indexqueryParamsParams);

#print @$queryParams[0]; print "\n";
#print Dumper(@$queryParams[0]); print "\n";

foreach my $queryParam (@$queryParams) {
    print Dumper($queryParam); 
    print $queryParam->{probe}."\n";
}

foreach my $indexParam (@$indexParams) {
foreach my $queryParam (@$queryParams) {
 my $parameter={ %$indexParam,%$queryParam};
 my $text =Dumper($parameter);
 $text=~s/\n| |\t|\;//g;
 $text=~s/|\$(VAR1)(=)//g;
 print $text." ".$parameter->{probe}." ".$parameter->{list}."\n";
}
}

my $indexParamStr=$config->val("parameters","index");
my $indexParams=eval($indexParamStr);
my $queryParamStr=$config->val("parameters","query");
my $queryParams=eval($queryParamStr);
