call setconfig.cmd 

SET POSTGRES_SOURCE=%POSTGRESPROFILE%\postgres\source\%PG_SET_VERSION%\%PG_SET_CONFIG%

SET POSTGRES_HOME=%POSTGRESPROFILE%\postgres\install\%PG_SET_VERSION%\%PG_SET_CONFIG%
ECHO %POSTGRES_HOME%
SET PGDATA=%POSTGRESPROFILE%\postgres\data\%PG_SET_VERSION%\%PG_SET_CONFIG%
SET PGLOGFILE=%POSTGRESPROFILE%\postgres\log\%PG_SET_VERSION%\%PG_SET_CONFIG%
MKDIR  %POSTGRES_HOME%
MKDIR  %POSTGRES_SOURCE%

%InstallDrive%
cd %POSTGRES_SOURCE%
dir
if EXIST postgresql-%PG_SET_VERSION% (
cd postgresql-%PG_SET_VERSION%
) else (
echo No PostgreSQL source dir. Trying to create it

 IF EXIST  postgresql-%PG_SET_VERSION%.tar.gz (
  tar xvf postgresql-%PG_SET_VERSION%.tar.gz 
  cd postgresql-%PG_SET_VERSION
 ) else ( 
  curl -o postgresql-%PG_SET_VERSION%.tar.gz https://ftp.postgresql.org/pub/source/v%PG_SET_VERSION%/postgresql-%PG_SET_VERSION%.tar.gz
  tar xvf postgresql-%PG_SET_VERSION%.tar.gz 
  cd postgresql-%PG_SET_VERSION%
 ) 
)

call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 

rem echo %PATH%
rem cl /help
rem SET PATH="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\";%PATH%
rem cd src\tools\msvc
ECHO ON
rem meson setup "build" "C:\postgres\postgres\source\master\release\postgresql-master"  --prefix="%POSTGRES_HOME%"
cd build
meson test 
rem ninja install


exit
REM SET PKG_CONFIG_PATH=\opt\homebrew\opt\icu4c\lib\pkgconfig\
make clean
if [[ %PG_SET_CONFIG = debug  ]]
then
.\configure --prefix=%POSTGRES_HOME --enable-debug  --enable-cassert   CFLAGS="-ggdb -O0 -fno-omit-frame-pointer" CPPFLAGS="-g -O0"
else
.\configure --prefix=%POSTGRES_HOME  
fi
make
export PATH=%POSTGRES_HOME\bin:%PATH
mkdir -p %PGDATA
mkdir -p %PGLOGFILE
make install

