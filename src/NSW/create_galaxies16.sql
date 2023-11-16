
create table if not exists  public.galaxies16_train_l2 (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies16_train_l2_idx on public.galaxies16_train_l2 (id);

create table if not exists  public.galaxies16_test_l2 (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies16_test_l2_idx on public.galaxies16_test_l2 (id);

create table if not exists  public.galaxies16_test_distances_l2 (
id int NOT NULL,
distances real[] NOT NULL,
neighbours real[] NOT NULL	
);
create UNIQUE index if not exists galaxies16_test_distances_l2_idx on public.galaxies16_test_distances_l2 (id);

create table if not exists  public.galaxies16_train_a (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies16_train_a_idx on public.galaxies16_train_a (id);

create table if not exists  public.galaxies16_test_a (
id int NOT NULL,
v real[] NOT NULL,
radius real NOT NULL	
);
create UNIQUE index if not exists galaxies16_test_a_idx on public.galaxies16_test_a (id);

create table if not exists  public.galaxies16_test_distances_a (
id int NOT NULL,
distances real[] NOT NULL,
neighbours real[] NOT NULL	
);
create UNIQUE index if not exists galaxies16_test_distances_l2_idx on public.galaxies16_test_distances_a (id);


--DROP FUNCTION public.fill_galaxies16f(inTrain INT, inTest INT) ;
CREATE OR REPLACE FUNCTION public.fill_galaxies16f(inTrain INT, inTest INT) 
RETURNS TABLE (id INT,v REAL[],d REAL)
LANGUAGE plpgsql AS $BODY1$
DECLARE 
galaxies16Centers REAL[15];
galaxySize REAL;
BEGIN
galaxies16Centers[1]:= 10::REAL;	galaxies16Centers[2]:=  0::REAL;	galaxies16Centers[3]:=  0::REAL;
galaxies16Centers[4]:= 0::REAL;	galaxies16Centers[5]:=100::REAL;	galaxies16Centers[6]:=  0::REAL;
galaxies16Centers[7]:=-100::REAL;	galaxies16Centers[8]:=  0::REAL;	galaxies16Centers[9]:=  0::REAL;
galaxies16Centers[10]:=0::REAL;	galaxies16Centers[11]:=-100::REAL;galaxies16Centers[12]:=  0::REAL;
galaxies16Centers[13]:=100::REAL;	galaxies16Centers[14]:=  0::REAL;	galaxies16Centers[15]:=  0::REAL;
galaxySize:=50::REAL;
RETURN QUERY 
WITH points AS (
select serie,
ARRAY[
	galaxies16Centers[(serie/inTrain)*3+1]+random()::REAL*galaxySize-galaxySize/2.::REAL,
	galaxies16Centers[(serie/inTrain)*3+2]+random()::REAL*galaxySize-galaxySize/2.::REAL,
	galaxies16Centers[(serie/inTrain)*3+3]+random()::REAL*galaxySize-galaxySize/2.::REAL,
	random()::REAL*2.-1.,random()::REAL*2.-1.,random()::REAL*2.-1.,random()::REAL*2.-1.,
	random()::REAL*2.-1.,random()::REAL*2.-1.,random()::REAL*2.-1.,random()::REAL*2.-1.,
	random()::REAL*2.-1.,random()::REAL*2.-1.,random()::REAL*2.-1.,random()::REAL*2.-1.,
	random()::REAL*2.-1.
]::REAL[] as v 
from generate_series(0,inTrain*5-1) as serie)
select a.serie,a.v,
SQRT(a.v[1]*a.v[1]+a.v[2]*a.v[2]+a.v[3]*a.v[3]+a.v[4]*a.v[4]+a.v[5]*a.v[5]+a.v[6]*a.v[6]+a.v[7]*a.v[7]+a.v[8]*a.v[8]+
a.v[9]*a.v[9]+a.v[10]*a.v[10]+a.v[11]*a.v[11]+a.v[12]*a.v[12]+a.v[13]*a.v[13]+a.v[14]*a.v[14]+a.v[15]*a.v[15]+a.v[16]*a.v[16]
)::REAL from points as a
ORDER BY serie;
END;
$BODY1$ ;

CREATE OR REPLACE PROCEDURE public.fill_galaxies16(inTrain INT, inTest INT) 
LANGUAGE plpgsql AS $BODY2$
BEGIN

--1 ) delete all lines 
delete from public.galaxies16_train_l2;
delete from public.galaxies16_test_l2;
delete from public.galaxies16_test_distances_l2;
delete from public.galaxies16_train_a;
delete from public.galaxies16_test_a;
delete from public.galaxies16_test_distances_a;
-- 2) generate l2 points
INSERT INTO public.galaxies16_train_l2 (id,v,radius) select * from  public.fill_galaxies16f(inTrain,1);
INSERT INTO public.galaxies16_test_l2 (id,v,radius) select * from  public.fill_galaxies16f(inTest,1);
-- 3) calculate cosine point from l2 points
IF 1=0 THEN
INSERT INTO public.galaxies16_train_a (id,v,radius) 
select a.id,
ARRAY[a.v[1]/a.radius,a.v[2]/a.radius,a.v[3]/a.radius,a.v[4]/a.radius,a.v[5]/a.radius,a.v[6]/a.radius,a.v[7]/a.radius,a.v[8]/a.radius,
a.v[9]/a.radius,a.v[10]/a.radius,a.v[11]/a.radius,a.v[12]/a.radius,a.v[13]/a.radius,a.v[14]/a.radius,a.v[15]/a.radius,a.v[16]/a.radius
]
, 1::REAL
FROM public.galaxies16_train_l2 as a ;
INSERT INTO public.galaxies16_test_a (id,v,radius) 
select a.id,
ARRAY[a.v[1]/a.radius,a.v[2]/a.radius,a.v[3]/a.radius,a.v[4]/a.radius,a.v[5]/a.radius,a.v[6]/a.radius,a.v[7]/a.radius,a.v[8]/a.radius,
a.v[9]/a.radius,a.v[10]/a.radius,a.v[11]/a.radius,a.v[12]/a.radius,a.v[13]/a.radius,a.v[14]/a.radius,a.v[15]/a.radius,a.v[16]/a.radius], 1::REAL
FROM public.galaxies16_test_l2 as a;
END IF;
-- calculate l2 distances amd neighbours
insert into public.galaxies16_test_distances_l2
WITH alllines AS (
select a.id,a.v,l2_distance(a.v::vector,b.v::vector) as distance,b.id as neighbour 
from public.galaxies16_test_l2 a
join public.galaxies16_train_l2 b on 1=1 
), rownumbers AS (
select a.id,a.v,a.distance,a.neighbour,
ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.id,a.distance) as rownum
	FROM alllines a
	), allneighbours AS (
	select a.id,a.v,a.distance,a.neighbour,a.rownum
	from rownumbers as a  WHERE rownum<=10
		)
	select 	a.id,
	array_agg(a.distance order by a.rownum) as distances,
	array_agg(a.neighbour order by a.rownum) as neighbours
	from allneighbours as a
	group by a.id
	order by a.id;

--select * from public.galaxies16_test_distances_l2;
IF 1=0 THEN
-- calculate cosine distances and neighbours
insert into public.galaxies16_test_distances_a
WITH alllines AS (
select a.id,a.v,-cosine_distance(a.v::vector,b.v::vector) as distance,b.id as neighbour 
from public.galaxies16_test_a a
join public.galaxies16_train_a b on 1=1 
), rownumbers AS (

select a.id,a.v,a.distance,a.neighbour,
ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.id,a.distance) as rownum
	FROM alllines a
	), allneighbours AS (
	select a.id,a.v,a.distance,a.neighbour,a.rownum
	from rownumbers as a  WHERE rownum<=10
		)
	select 	a.id,
	array_agg(-a.distance order by a.rownum) as distances,
	array_agg(a.neighbour order by a.rownum) as neighbours
	from allneighbours as a
	group by a.id;

--select * from public.galaxies16_test_distances_a
END IF;
END;
$BODY2$ ;

CREATE OR REPLACE PROCEDURE public.fill_galaxies16_1(inTrain INT, inTest INT) 
LANGUAGE plpgsql AS $BODY2$
BEGIN

--1 ) delete all lines 
delete from public.galaxies16_train_l2;
delete from public.galaxies16_test_l2;
delete from public.galaxies16_test_distances_l2;
delete from public.galaxies16_train_a;
delete from public.galaxies16_test_a;
delete from public.galaxies16_test_distances_a;
-- 2) generate l2 points
INSERT INTO public.galaxies16_train_l2 (id,v,radius) select * from  public.fill_galaxies16f(inTrain,1);
INSERT INTO public.galaxies16_test_l2 (id,v,radius) select * from  public.fill_galaxies16f(inTest,1);


END;
$BODY2$ ;


CREATE OR REPLACE PROCEDURE public.fill_galaxies16_2(inTrain INT, inTest INT, fromId INT, toId INT) 
LANGUAGE plpgsql AS $BODY2$
BEGIN

insert into public.galaxies16_test_distances_l2
WITH alllines AS (
select a.id,a.v,l2_distance(a.v::vector,b.v::vector) as distance,b.id as neighbour 
from public.galaxies16_test_l2 a
join public.galaxies16_train_l2 b on 1=1 
where a.id between fromId and toId
), rownumbers AS (
select a.id,a.v,a.distance,a.neighbour,
ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.id,a.distance) as rownum
	FROM alllines a
	), allneighbours AS (
	select a.id,a.v,a.distance,a.neighbour,a.rownum
	from rownumbers as a  WHERE rownum<=10
		)
	select 	a.id,
	array_agg(a.distance order by a.rownum) as distances,
	array_agg(a.neighbour order by a.rownum) as neighbours
	from allneighbours as a
	group by a.id;
	

END;
$BODY2$ ;
