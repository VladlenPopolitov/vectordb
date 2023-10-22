package modules::vectordata;

use strict;
use PDL;
use PDL::IO::HDF5;
use PDL::NiceSlice;

my $vectordata = {
    'glove-100-a' => 
    {   file => "../../vectordata/glove-100-angular.hdf5", 
        type => 'a', 
        record=>'train' , 
        http=> 'http://ann-benchmarks.com/glove-100-angular.hdf5',
        tablename => 'items1',
        indexname => 'items1_idx'
        } 
};

sub new {
    my ($class) = shift;
    my ($name) = @_;
    my $self = { 
        name => '',
        filename => '',
        recordname => '' ,
        width => 0,
        length => -1,
        pdlref => undef,
        loaded => 0
     };
     my $datainfo=$vectordata->{$name};
     if( defined($datainfo)){
        if( -f $datainfo->{file} ) {
         my $newfile = new PDL::IO::HDF5($datainfo->{file});
         my $dataset=$newfile->dataset($datainfo->{record});
         my $pdl = $dataset->get();
         my ($width,$length)=$dataset->dims();
         if(defined($dataset) && $width>0 && $length>0){
            $self->{name}= $name; 
            $self->{filename}= $datainfo->{file} ; 
            $self->{recordname}= $datainfo->{record}; 
            $self->{width}= $width; 
            $self->{length}= $length; 
            $self->{pdlref}= $pdl ; 
            $self->{tablename}=$datainfo->{tablename};
            $self->{indexname}=$datainfo->{indexname};
            $self->{loaded}= 1 ; 
         }
        }
     }
    bless $self, $class;
    return $self;
}

sub NAME {
    my $num = @_;
    my @names=sort keys %$vectordata;
    return $names[$num];
}

sub LENGTH {
    my $num = @_;
    my @names=sort keys %$vectordata;
    return scalar(@names);
}

sub loaded {
    my ($self) = @_;
    return $self->{loaded};
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

sub distancetype {
    my ($self) = @_;
    return $vectordata->{$self->{name}}->{type};
}

sub tablename {
    my ($self) = @_;
    return $self->{tablename};
}

sub indexname {
    my ($self) = @_;
    return $self->{indexname};
}


# format [ 1, 2, 3, 4 ]
sub getline_format1 {
    my ($self,$linenum) = @_;
    if($self->{loaded}) {
       my ($widthFirst,$widthLast)=(0,$self->width-1);
       my $line=$self->{pdlref}->($widthFirst:$widthLast,($linenum));
       $line=~ s/[ ]+/,/g;
        return $line;
    } else {
        return '';
    }
}

# format [ 1 2 3 4 ]
sub getline_format2 {
    my ($self,$linenum) = @_;
    if($self->{loaded}) {
       my ($widthFirst,$widthLast)=(0,$self->width-1);
       my $line=$self->{pdlref}->($widthFirst:$widthLast,($linenum));
       return $line;
    } else {
        return '';
    }
}
