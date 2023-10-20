package pgvector_i::benchmark;

sub new    
{
    my $class = shift;
    my $self = {
                name => "pgvector_i"
               };
    bless $self, $class;
    return $self;
}

sub name {
    my ($self) = @_;
    return $self->{name};
}
1;
