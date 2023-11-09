# Setup benchmarks

a. Create db.ini with admin settings (to create databases for every algorithm, 
create user and provide access for user to that database), and benchmark settings. The example of db.ini file is in sample_db.ini .
```
[postgresql]
adminuser=
adminpass=
admindb=
[step0]
algorithmIncludeRegex=.*
algorithmExcludeRegex=<>
[step1]
datasetname=lastfm
# benchmarkRecords - perl array in form (10,20,30)
benchmarkRecords=(10,100)
# regex expression to choose datasets, f.e. 
# algorithmIncludeRegex=lastfm
# algorithmIncludeRegex=lastfm|glove-100-a
algorithmIncludeRegex=.*
# regex expression to exclude datasets, f.e. 
# algorithmExcludeRegex=lastfm
algorithmExcludeRegex=<>
[step2]
datasetname=lastfm
queryRecordCount=10
algorithmIncludeRegex=.*
algorithmExcludeRegex=<>
[step3]
datasetname=lastfm
queryRecordCount=10
algorithmIncludeRegex=.*
algorithmExcludeRegex=<>
# value to compare result with target to avoid rounding error of REAL data type: found=(result+tolerance)<target
tolerance=0.0001
```

b. Dowaload a dataset for tests and benchmarks.
```
cd src/benchmark1
perl datasets.pl
```
To download, f.e. ```lastfm``` dataset, use command:
```
perl datasets.pl lastfm
```

c. Create db.ini file in every algorithm subfolder. Example is in sample_db.ini files of every algorithm. Chose your username and password.

# Run benchmark

a. Go to src/benchmark1
```
cd src/benchmark
```

b. Step 0 - create databases, users for every algorithm
```
perl step-_install.pl
```

c. Step 1 - create tables, fill tables, make index.
```
perl step1_insert.pl
```

d. Step 2 - benchmark ( create table, insert ```train``` dataset, create indexes and run queries for ```test``` dataset)
```
perl step2_run_benchmark.pl
```

e. Step 3 - create report
```
perl step3_plot.pl
```
Data are stored in file ```results/datasetname/recordcount/benchmark.csv```

f. Create PNG files ```results/datasetname/recordcount/benchmark.png```, 
```results/datasetname/recordcount/benchmark2.png```, ```results/datasetname/recordcount/benchmarkIndex.png```: run R language script ```plot/plot_lastfm_10.R```, chose dataset name and record count (if not equal to 10) in first lines of the script.



