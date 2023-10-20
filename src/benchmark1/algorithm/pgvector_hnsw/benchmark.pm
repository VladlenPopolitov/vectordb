package pgvector_hnsw::benchmark;
#use strict;

sub new {
    my $class = shift;
    my $self = { name => "pgvector_hnsw" };
    bless $self, $class;
    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{name};
}
1;
