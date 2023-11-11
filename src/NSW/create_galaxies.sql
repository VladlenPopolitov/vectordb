
create table if not exists  public.galaxies_train_l2 (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies_train_l2_idx on public.galaxies_train_l2 (id);

create table if not exists  public.galaxies_test_l2 (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies_test_l2_idx on public.galaxies_test_l2 (id);

create table if not exists  public.galaxies_test_distances_l2 (
id int NOT NULL,
distances real[] NOT NULL,
neighbours real[] NOT NULL	
);
create UNIQUE index if not exists galaxies_test_distances_l2_idx on public.galaxies_test_distances_l2 (id);

create table if not exists  public.galaxies_train_a (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies_train_a_idx on public.galaxies_train_a (id);

create table if not exists  public.galaxies_test_a (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies_test_a_idx on public.galaxies_test_a (id);

create table if not exists  public.galaxies_test_distances_a (
id int NOT NULL,
distances real[] NOT NULL,
neighbours real[] NOT NULL	
);
create UNIQUE index if not exists galaxies_test_distances_l2_idx on public.galaxies_test_distances_a (id);


--DROP FUNCTION public.fill_galaxiesf(inTrain INT, inTest INT) ;
CREATE OR REPLACE FUNCTION public.fill_galaxiesf(inTrain INT, inTest INT) 
RETURNS TABLE (id INT,v REAL[],d REAL)
LANGUAGE plpgsql AS $BODY1$
DECLARE 
galaxiesCenters REAL[15];
galaxySize REAL;
BEGIN
galaxiesCenters[1]:= 10::REAL;	galaxiesCenters[2]:=  0::REAL;	galaxiesCenters[3]:=  0::REAL;
galaxiesCenters[4]:= 0::REAL;	galaxiesCenters[5]:=100::REAL;	galaxiesCenters[6]:=  0::REAL;
galaxiesCenters[7]:=-100::REAL;	galaxiesCenters[8]:=  0::REAL;	galaxiesCenters[9]:=  0::REAL;
galaxiesCenters[10]:=0::REAL;	galaxiesCenters[11]:=-100::REAL;galaxiesCenters[12]:=  0::REAL;
galaxiesCenters[13]:=100::REAL;	galaxiesCenters[14]:=  0::REAL;	galaxiesCenters[15]:=  0::REAL;
galaxySize:=50::REAL;
RETURN QUERY 
WITH points AS (
select serie,
ARRAY[
	galaxiesCenters[(serie/inTrain)*3+1]+random()::REAL*galaxySize-galaxySize/2.::REAL,
	galaxiesCenters[(serie/inTrain)*3+2]+random()::REAL*galaxySize-galaxySize/2.::REAL,
	galaxiesCenters[(serie/inTrain)*3+3]+random()::REAL*galaxySize-galaxySize/2.::REAL
] as v 
from generate_series(0,inTrain*5-1) as serie)
select a.serie,a.v,SQRT(a.v[1]*a.v[1]+a.v[2]*a.v[2]+a.v[3]*a.v[3])::REAL from points as a
ORDER BY serie;
END;
$BODY1$ ;

CREATE OR REPLACE PROCEDURE public.fill_galaxies(inTrain INT, inTest INT) 
LANGUAGE plpgsql AS $BODY2$
BEGIN

--1 ) delete all lines 
delete from public.galaxies_train_l2;
delete from public.galaxies_test_l2;
delete from public.galaxies_test_distances_l2;
delete from public.galaxies_train_a;
delete from public.galaxies_test_a;
delete from public.galaxies_test_distances_a;
-- 2) generate l2 points
INSERT INTO public.galaxies_train_l2 (id,v,radius) select * from  public.fill_galaxiesf(inTrain,1);
INSERT INTO public.galaxies_test_l2 (id,v,radius) select * from  public.fill_galaxiesf(inTest,1);
-- 3) calculate cosine point from l2 points
INSERT INTO public.galaxies_train_a (id,v,radius) 
select a.id,
ARRAY[a.v[1]/a.radius,a.v[2]/a.radius,a.v[3]/a.radius], 1::REAL
FROM public.galaxies_train_l2 as a ;
INSERT INTO public.galaxies_test_a (id,v,radius) 
select a.id,
ARRAY[a.v[1]/a.radius,a.v[2]/a.radius,a.v[3]/a.radius], 1::REAL
FROM public.galaxies_test_l2 as a;
-- calculate l2 distances amd neighbours
insert into public.galaxies_test_distances_l2
WITH alllines AS (
select a.id,a.v,l2_distance(a.v::vector,b.v::vector) as distance,b.id as neighbour 
from public.galaxies_test_l2 a
join public.galaxies_train_l2 b on 1=1 
), rownumbers AS (
select a.id,a.v,a.distance,a.neighbour,
ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.id,a.distance) as rownum
	FROM alllines a
	), allneighbours AS (
	select a.id,a.v,a.distance,a.neighbour,a.rownum
	from rownumbers as a  WHERE rownum<=100
		)
	select 	a.id,
	array_agg(a.distance order by a.rownum) as distances,
	array_agg(a.neighbour order by a.rownum) as neighbours
	from allneighbours as a
	group by a.id
	order by a.id;

--select * from public.galaxies_test_distances_l2;
-- calculate cosine distances and neighbours
insert into public.galaxies_test_distances_a
WITH alllines AS (
select a.id,a.v,-cosine_distance(a.v::vector,b.v::vector) as distance,b.id as neighbour 
from public.galaxies_test_a a
join public.galaxies_train_a b on 1=1 
), rownumbers AS (

select a.id,a.v,a.distance,a.neighbour,
ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.id,a.distance) as rownum
	FROM alllines a
	), allneighbours AS (
	select a.id,a.v,a.distance,a.neighbour,a.rownum
	from rownumbers as a  WHERE rownum<=100
		)
	select 	a.id,
	array_agg(-a.distance order by a.rownum) as distances,
	array_agg(a.neighbour order by a.rownum) as neighbours
	from allneighbours as a
	group by a.id
	order by a.id;

--select * from public.galaxies_test_distances_a
END;
$BODY2$ ;