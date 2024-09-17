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
rem SET PATH="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\";%PATH%
rem cd src\tools\msvc
ECHO ON
rem ^"C^:^\postgres^\postgres^\install^\master^\release^\bin^\pg^_ctl^" -D ^"C^:^\postgres^\postgres^\data^\master^\release^" -l logfile start
%POSTGRES_HOME%/bin/pg_ctl -D %PGDATA% -l %PGLOGFILE stop


