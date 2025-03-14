# Test of vector type: create extensions, create database for every extension, run benchmarks.
```
git clone https://github.com/VladlenPopolitov/vectordb
cd vectordb
```
clone pgvector, pg_embedding, lantern repositories as submodules
```
git submodule update --init --recursive
```
create postgres source directory in external/postgres-15.4
```
cd external 
wget https://ftp.postgresql.org/pub/source/v15.4/postgresql-15.4.tar.gz
tar xvf postgresql-15.4.tar.gz
```
make postgres 
```
cd postgresql-15.4
./configure
make all
```
install to /usr/local/pgsql (run with sudo if needed)
```
make install
cd ../..
```
 configure and start postgresql server,f.e.:
 https://www.postgresql.org/docs/current/postgres-user.html etc

# Build extensions

1) setting the PATH

bash: `export PATH=/usr/local/pgsql/bin:$PATH`

csh: `set path = ( /usr/local/pgsql/bin $path )`

2) compile and install extention pgvector
```
cd external/pgvector
make USE_PGXS=1
sudo make USE_PGXS=1 install
cd ../..
```
3) compile and install extention pg_embedding
```
cd external/pg_embedded
make USE_PGXS=1
sudo make USE_PGXS=1 install
cd ../..
```
4) compile and install extention lantern
```
cd external/lantern
mkdir build
cd build
cmake ..
make 
sudo make install
cd ../../..
```

# Install Perl support for Postgresql
```
cpan DBD::Pg
```
ini file support to load site specific data
```
cpan Config::IniFiles
```

# Create local ini files with database credentials

a. File src/benchmark1/db.ini with content (example in src/benchmark1/sample_db.ini )
```
[postgresql]
adminuser=userNameToCreateDatabases
adminpass=passwordOfadminuser
```
b. in every algorithm folder create db.ini (example in sample_db.ini)
```
[postgresql]
dbname=dataBaseNameForThisAlgorithm
user=userName
pass=userPassword
```
install PDL (Perl Data Language) - packages to read and write HDF5 datasets with sample vectors and benchmark results.
```
cpan install PDL
HDF5_LIBDIR=/path_to_libhdf5.a cpan install PDL::IO::HDF5
```

# Benchmark results:

Dataset galaxies-16-1000000-e (euclidean distance, 16d vectors, 1 mln rows in the dataset, query 10 rows).

![Benchmark](results/galaxies-16-1000000-e/10/benchmark2.png?raw=true "Benchmark")

Dataset lastfm (angular distance, query 10 rows).

![Benchmark](results/lastfm/10/benchmark.png?raw=true "Benchmark")

![Benchmark](results/lastfm/10/benchmark2.png?raw=true "Benchmark")


Dataset glove-100-angular (angular distance, query 10 rows).

![Benchmark](results/glove-100-a/10/benchmark.png?raw=true "Benchmark")

![Benchmark](results/glove-100-a/10/benchmark2.png?raw=true "Benchmark")

Dataset fashion-mnist-784-e (angular distance, query 10 rows).

![Benchmark](results/fashion-mnist-784-e/10/benchmark.png?raw=true "Benchmark")

![Benchmark](results/fashion-mnist-784-e/10/benchmark2.png?raw=true "Benchmark")

Index creation time, dataset lastfm (angular distance, query 10 rows).

![Benchmark](results/lastfm/10/benchmarkIndex.png?raw=true "Benchmark")


Index creation time, dataset glove-100-angular (angular distance, query 10 rows).

![Benchmark](results/glove-100-a/10/benchmarkIndex.png?raw=true "Benchmark")


Index creation time, dataset fashion-mnist-784-e (angular distance, query 10 rows).

![Benchmark](results/fashion-mnist-784-e/10/benchmarkIndex.png?raw=true "Benchmark")


# How to run benchmark, see the link [Run benchmarks description](src/benchmark1/README.md).
