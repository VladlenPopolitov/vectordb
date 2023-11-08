package vectordb::benchmark;
use strict;
use DBI;
use PDL;
use PDL::IO::HDF5;
#use PDL::NiceSlice;
#use PDL::IO::Dumper;

sub new {
    my $class = shift;
    my ($dbname,$user,$password) = @_;
    my $self = { 
        name => "vectordb",
        dbname => $dbname ,
        user => $user,
        password => $password ,
        width => 0,
        distancetype=>''
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
        $dbh->do("GRANT USAGE ON SCHEMA public TO ".$self->{user});
        $dbh->do("GRANT ALL ON SCHEMA public TO ".$self->{user});
        $dbh->do("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ".$self->{user});
        $dbh->do("GRANT pg_write_all_data TO ".$self->{user});
        $dbh->do("CREATE TYPE public.HNSWPOINT AS (id int, distance REAL, v REAL[])");
        $dbh->do("create type public.hnsw_param as (entrypoint int,eplevel int,epvector REAL[],tablename varchar)");
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

sub init_connection {
    my ($self) = @_;
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        $self->{dbh}=DBI->connect('dbi:Pg:dbname='.$self->{dbname}, $self->{user}, $self->{password}, {AutoCommit => 1});
    }
}

sub init_table {
    my ($self,$data) = @_;
    my $dbh=$self->{dbh};
    my $width = $data->width();
    my $table = $data->tablename();
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        $self->{width}=$width;
        $dbh->do("DROP TABLE IF EXISTS public.datatable");
        $dbh->do("DROP TABLE IF EXISTS public.datatable_index");
        $dbh->do("CREATE TABLE public.datatable (id int, v REAL[])");
        $dbh->do("ALTER TABLE public.datatable ALTER COLUMN v SET STORAGE PLAIN");
        $dbh->do("create index if not exists datatable_idx on public.datatable (id)");
        $dbh->do("create UNLOGGED table  public.datatable_index (id int,neighbour int,hnsw_level int,distance real)");
        $dbh->do("create index if not exists datatable_index_idx on public.datatable_index (hnsw_level,id)");
        $dbh->do("create index if not exists datatable_index2_idx on public.datatable_index (hnsw_level,id,neighbour)");
        return $dbh;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

sub insert_from_data {
    my ($self, $data, $totalLines) = @_;
    my $dbh=$self->{dbh};
    my $table = $data->tablename();
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        #my ($widthFirst,$widthLast)=(0,$pdl->width()-1);
        my $sth=$dbh->do("COPY public.datatable (id,v) FROM STDIN");
        for(my $record=0;$record<$totalLines;++$record){
            my $line=$data->getline_format3($record) ; # {pdlref}->($widthFirst:$widthLast,($record)); $line=~ s/[ ]+/,/g;
            $dbh->func($record."\t".$line."\n", 'putline');
        }
        $dbh->func("\\.\n", 'putline');
        $dbh->func('endcopy');
        $self->{distancetype}=$data->distancetype();
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

sub create_index {
    my ($self, $data,$parameters) = @_;
    my $dbh=$self->{dbh};
    my $table = $data->tablename();
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        my ($m,$fConstruction)=($parameters->{m},$parameters->{fConstruction});
        
        if($self->{distancetype} eq 'a') { # angular 
         my $sth=$dbh->do(" ");
        } elsif ($self->{distancetype} eq 'l2') { # L2 distance - euclidian - x**2+y**2+... 
         my $sth=$dbh->do("CALL hnsw_index_test($m,$fConstruction)");
        }
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}


sub drop_index {
    my ($self, $data,$parameters) = @_;
    my $dbh=$self->{dbh};
    my $table = $data->tablename();
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        my ($lists)=$parameters->{lists};
        my $sth=$dbh->do("DELETE FROM public.datatable_index");
        return 1;
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}


sub index_size {
    my ($self, $data) = @_;
    my $dbh=$self->{dbh};
    my $size=0;
    my $table = $data->tablename();
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        #my ($widthFirst,$widthLast)=(0,$pdl->width()-1);
        
         my $sth=$dbh->prepare("SELECT pg_relation_size('public.datatable_index')");
         $sth->execute();
         my @row = $sth->fetchrow_array();
         if(@row){
            $size+=$row[0];
         } 
         $sth=$dbh->prepare("SELECT pg_relation_size('public.datatable_index_idx')");
         $sth->execute();
         my @row = $sth->fetchrow_array();
         if(@row){
            $size+=$row[0];
         } 
         $sth=$dbh->prepare("SELECT pg_relation_size('public.datatable_index2_idx')");
         $sth->execute();
         my @row = $sth->fetchrow_array();
         if(@row){
            $size+=$row[0];
         } 
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
    return $size;
}

sub table_size {
    my ($self, $data) = @_;
    my $dbh=$self->{dbh};
    my $table = $data->tablename();
    if(defined($self->{user}) && defined($self->{password}) && defined($self->{dbname}) ) {
        #my ($widthFirst,$widthLast)=(0,$pdl->width()-1);
        
         my $sth=$dbh->prepare("SELECT pg_relation_size('public.datatable')");
         $sth->execute();
         my @row = $sth->fetchrow_array();
         if(@row){
            return $row[0];
         } else {
            return 0;
         }
    } else {
        die "Algorithm ".$self->name()." database credentials not set in db.ini";
        return 0;
    }
}

sub query_parameter_set {
  my ($self,$data,$parameter)=@_;
  my $dbh=$self->{dbh};
  $self->{eSearch}=$parameter->{eSearch};
}

sub query {
    my ($self,$data,$count,$vector)=@_;
    $vector=~ s/\[[\,]*/\{/g;
    $vector=~ s/[\,]*\]/\}/g;
    my $dbh=$self->{dbh};
    my $table = $data->tablename();
    my $query='';
    my $distancetype = $self->{distancetype};
    if($distancetype eq "a") {
        $query = ' ';
    } elsif( $distancetype eq "l2") {
        $query = 'SELECT hnsw_query_l2($1::real[],'.$count.",". $self->{eSearch} . ")";
    } else {
            die("unknown metric '$distancetype'");
    }
    my $sth=$dbh->prepare($query);
    $sth->execute($vector);
    my (@id, @row);
    while(@row = $sth->fetchrow_array()){
         push(@id, $row[0]);         
    } 
    return \@id;
}


1;
