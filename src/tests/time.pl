
use strict;

#use Time::Moment;
#print Time::Moment->now->strftime("%Y%m%d %T%3f"), "\n";

use Time::HiRes qw(time);
use POSIX qw(strftime);

my $t = time;
my $date = strftime "%Y%m%d %H:%M:%S", localtime $t;
$date .= sprintf ".%03d", ($t-int($t))*1000; # without rounding

print $date, "\n";
my $t1 = time;
print $t1-$t, ' ',$t1, ' ', $t, "\n";