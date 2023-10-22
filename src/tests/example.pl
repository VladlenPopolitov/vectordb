use DBI;
use strict;
# .dbaccess file has 1 line with user name and password delimited by colon ":", f.e.:
#user:pass
#
open(IN,"<../../.dbaccess");
my($line,@access);
$line=<IN>;
close(IN);
@access=split(/:/,$line);

my $dbh = DBI->connect('dbi:Pg:dbname=pgvector_perl_test', $access[0], $access[1], {AutoCommit => 1});

$dbh->do('CREATE EXTENSION IF NOT EXISTS vector');
$dbh->do('DROP TABLE IF EXISTS items');
$dbh->do('CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))');

sub vector {
    return '[' . join(',', @{$_[0]}) . ']';
}

# insert vector as reference to perl array
my $sth = $dbh->prepare('INSERT INTO items (embedding) VALUES ($1), ($2), ($3)');
my @embedding1 = (1, 1, 1);
my @embedding2 = (2, 2, 2);
my @embedding3 = (1, 1, 2);
$sth->execute(vector(\@embedding1), vector(\@embedding2), vector(\@embedding3));

# insert vector as bulk copy
$sth=$dbh->do("COPY items (embedding) FROM STDIN");
for(my $i=0;$i<10;++$i){
    my $line="[".($i*100+1)." , ".($i*100+2).",".($i*100+3)."]\n";
    my $ret = $dbh->func($line, 'putline');
    print $ret . "\n";
}
$dbh->func("\\.\n", 'putline');
$dbh->func('endcopy');

# select vector
my $sth = $dbh->prepare('SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 10');
my @embedding = (501, 1, 1);
$sth->execute(vector(\@embedding));
while (my @row = $sth->fetchrow_array()) {
    print($row[1] . "\n");
}

$dbh->do('CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)');
$dbh->disconnect;
