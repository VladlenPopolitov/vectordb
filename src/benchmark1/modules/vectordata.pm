package modules::vectordata;


sub new {
    my $class = shift;
    my ($filename,$recordname) = @_;
    my $self = { 
        filename => $filename,
        recordname => $recordname ,
        width => 0,
        length => -1,
        pdlref => undef
     };
    bless $self, $class;
    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub filename {
    my ($self) = @_;
    return $self->{filename};
}


sub recordname {
    my ($self) = @_;
    return $self->{recordname};
}

sub recorddata {
    my ($self) = @_;
    return $self->{pdlref};
}

sub width {
    my ($self) = @_;
    return $self->{width};
}

sub length {
    my ($self) = @_;
    return $self->{length};
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
