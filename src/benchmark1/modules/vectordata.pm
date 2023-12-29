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
        recordtest=>'test',
        recorddistances=>'distances',
        recordneighbors=>'neighbors',
        http=> 'http://ann-benchmarks.com/glove-100-angular.hdf5',
        tablename => 'items2',
        indexname => 'items2_idx',
        vectorsize => 100 ,
        size=>'463M'
    } ,
    'lastfm' => 
    {   file => "../../vectordata/lastfm-64-dot.hdf5", 
        type => 'a', 
        record=>'train' , 
        recordtest=>'test',
        recorddistances=>'distances',
        recordneighbors=>'neighbors',
        http=> 'http://ann-benchmarks.com/lastfm-64-dot.hdf5',
        tablename => 'itemslastfm',
        indexname => 'itemslastfm_idx',
        vectorsize => 64 ,
        size=>'135M'
    },
    'fashion-mnist-784-e' => 
    {   file => "../../vectordata/fashion-mnist-784-euclidean.hdf5", 
        type => 'l2', 
        record=>'train' , 
        recordtest=>'test',
        recorddistances=>'distances',
        recordneighbors=>'neighbors',
        http=> 'http://ann-benchmarks.com/fashion-mnist-784-euclidean.hdf5',
        tablename => 'itemsfashionmnist',
        indexname => 'itemsfashionmnist_idx',
        vectorsize => 784 ,
        size=>'217M'
    },
    'galaxies-3-5000-e' => 
    {   file => "../../vectordata/galaxies-3-5000-e.hdf5", 
        type => 'l2', 
        record=>'train' , 
        recordtest=>'test',
        recorddistances=>'distances',
        recordneighbors=>'neighbors',
        http=> 'https://github.com/VladlenPopolitov/vectordb/raw/main/vectordata/galaxies-3-5000-e.hdf5',
        tablename => 'itemsgalaxies',
        indexname => 'itemsgalaxies_idx',
        vectorsize => 3 ,
        size=>'1M'
    },
    'galaxies-16-1000000-e' => 
    {   file => "../../vectordata/galaxies-16-1000000-e.hdf5", 
        type => 'l2', 
        record=>'train' , 
        recordtest=>'test',
        recorddistances=>'distances',
        recordneighbors=>'neighbors',
        http=> 'https://github.com/VladlenPopolitov/vectordb/raw/main/vectordata/galaxies-16-1000000-e.hdf5',
        tablename => 'itemsgalaxies16',
        indexname => 'itemsgalaxies16_idx',
        vectorsize => 16 ,
        size=>'62M'
    }
};

sub new {
    my ($class) = shift;
    my ($name,$recordsetname) = @_;
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
        $self->{name}= $name; 
        $self->{filename}= $datainfo->{file} ; 
        
        $self->{tablename}=$datainfo->{tablename};
        $self->{indexname}=$datainfo->{indexname};
        if( -f $datainfo->{file} ) {
         my $newfile = new PDL::IO::HDF5($datainfo->{file});
         if(!defined($recordsetname)){
            $recordsetname='train';
         }
         if($recordsetname eq 'train'){
            $recordsetname=$datainfo->{record};
         } elsif ($recordsetname eq 'test'){
            $recordsetname=$datainfo->{recordtest};
         } elsif ($recordsetname eq 'distances'){
            $recordsetname=$datainfo->{recorddistances};
         } elsif ($recordsetname eq 'neighbors'){
            $recordsetname=$datainfo->{recordneighbors};
         } else {
            die("Unknown dataset name $recordsetname");
         }
         $self->{recordname}= $recordsetname; 

         my $dataset=$newfile->dataset($self->{recordname});
         my $pdl = $dataset->get();
         my ($width,$length)=$dataset->dims();
         if(defined($dataset) && $width>0 && $length>0){   
            $self->{width}= $width; 
            $self->{length}= $length; 
            $self->{pdlref}= $pdl;             
            $self->{loaded}= 1; 
         }
        }
     }
    bless $self, $class;
    return $self;
}

sub NAME {
    my ($num) = @_;
    my @names=sort keys %$vectordata;
    return $names[$num];
}

sub LENGTH {
    my ($num) = @_;
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

sub vectorsize {
    my ($self) = @_;
    return $vectordata->{$self->{name}}->{vectorsize};
}

sub distancetype {
    my ($self) = @_;
    return $vectordata->{$self->{name}}->{type};
}

sub filesize {
    my ($self) = @_;
    return $vectordata->{$self->{name}}->{size};
}

sub http {
    my ($self) = @_;
    return $vectordata->{$self->{name}}->{http};
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
       $line=~ s/\[[\,]*/\[/g;
       $line=~ s/[\,]*\]/\]/g;
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

sub getline_format3 {
    my ($self,$linenum) = @_;
    if($self->{loaded}) {
       my ($widthFirst,$widthLast)=(0,$self->width-1);
       my $line=$self->{pdlref}->($widthFirst:$widthLast,($linenum));
       $line=~ s/[ ]+/,/g;
       $line=~ s/\[[\,]*/\{/g;
       $line=~ s/[\,]*\]/\}/g;
        return $line;
    } else {
        return '';
    }
}
