package pgvector_i::benchmark;

sub new    
{
    my $class = shift;
    my ($dbname,$user,$password) = @_;
    my $self = {
                name => "pgvector_i",
        dbname => $dbname ,
        user => $user,
        password => $password ,
         width => 0
               };
    bless $self, $class;
    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub create_user {
    my ($self,$dbh) = @_;
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        $dbh->do("CREATE USER ".$self->{user}." WITH ENCRYPTED PASSWORD '".$self->{password}."'");
        $dbh->do("ALTER USER ".$self->{user}." SET maintenance_work_mem = '4GB'");
        $dbh->do("ALTER SYSTEM SET shared_buffers = '4GB'");
        #make actions in database
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

sub create_database {
    my ($self,$dbh) = @_;
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        $dbh->do("CREATE DATABASE ".$self->{dbname});
        $dbh->do("GRANT ALL PRIVILEGES ON DATABASE ".$self->{dbname}." TO ".$self->{user});
        #make actions in database
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

sub init_database {
    my ($self,$dbh) = @_;
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        $dbh->do("CREATE EXTENSION IF NOT EXISTS vector");
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

sub init_table {
    my ($self,$dbh,$width) = @_;
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        $self->{width}=$width;
        $dbh->do("DROP TABLE IF EXISTS items");
        $dbh->do("CREATE TABLE items (id int, embedding vector($width))");
        $dbh->do("ALTER TABLE items ALTER COLUMN embedding SET STORAGE PLAIN");
        
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}


1;
