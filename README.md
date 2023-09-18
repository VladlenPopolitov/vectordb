Test of vector type.

git clone https://github.com/VladlenPopolitov/vectordb
cd vectordb
# clone pgvector repository as submodule
git submodule update --init --recursive
# create pstgres source directory in external/postgres-15.4
cd external 
wget https://ftp.postgresql.org/pub/source/v15.4/postgresql-15.4.tar.gz
tar xvf postgresql-15.4.tar.gz
# make postgres 
cd postgresql-15.4
./configure
make all
# install to /usr/local/pgsql
# run sudo
make install
cd ../..
# configure and start postgresql server:
# https://www.postgresql.org/docs/current/postgres-user.html etc
# build extension
# 1) setting the PARH
export PATH=/usr/local/pgsql/bin:$PATH
# csh: set path = ( /usr/local/pgsql/bin $path )

# 2) compile extention
cd external/pgvector
make USE_PGXS=1
# 3) install extension
make USE_PGXS=1 install
