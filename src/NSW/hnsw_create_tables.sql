 -- db postgres
  
 CREATE OR REPLACE FUNCTION public.random_array(dim integer, min real, max real) RETURNS REAL[] AS $BODY$
begin
        return (select array_agg(random() * (max - min) + min) from generate_series (0, dim - 1));
end
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.test_array(dim integer, num REAL) RETURNS REAL[] AS $BODY$
begin
        return 
		ARRAY_APPEND(
		ARRAY_APPEND((select array_agg(serie::REAL+num::REAL/10.) from generate_series (0, dim - 3) as serie),
		SIN(num::REAL/100.)),
			COS(num::REAL/100.));
end
$BODY$ LANGUAGE plpgsql;


 CREATE OR REPLACE FUNCTION public.l2distance(v1 real[], v2 real[]) RETURNS REAL AS $BODY$
begin
 		return l2_distance(v1::vector,v2::vector);
        --return (v1[3]-v2[3])*(v1[3]-v2[3])+(v1[1]-v2[1])*(v1[1]-v2[1])+(v1[2]-v2[2])*(v1[2]-v2[2]);
end
$BODY$ LANGUAGE plpgsql;

--CREATE TYPE public.HNSWPOINT AS (id int, distance REAL, v REAL[]);
--select random_array(3,1,3)
CREATE SEQUENCE IF NOT EXISTS public.serial START 10001;
create table if not exists  public.datatable (
id int NOT NULL,
v real[] NOT NULL
);
create index if not exists datatable_idx on public.datatable (id);
-- drop table datatable_index;
create table if not exists  public.datatable_index (
id int NOT NULL,
neighbour int NOT NULL,
hnsw_level int NOT NULL,	
distance real NOT NULL
) ;
create index if not exists datatable_index_idx on public.datatable_index (hnsw_level,id);
create index if not exists datatable_index2_idx on public.datatable_index (hnsw_level,id,neighbour);

create table if not exists  public.datatable_index_save (
id int NOT NULL,
neighbour int NOT NULL,
hnsw_level int NOT NULL,	
distance real NOT NULL
);
-- drop table public.datatable_results;
create table if not exists  public.datatable_results (
id int NOT NULL,
neighbours int[] NOT NULL,
distances REAL[] NOT NULL
) ;
create index if not exists datatable_results_idx on public.datatable_results (id);


/* create type public.hnsw_param as (entrypoint int,eplevel int,epvector REAL[],tablename varchar);
*/


--	delete from public.datatable;
	--SELECT id,l2distance(v,random_array(128, 0, 128)) FROM public.datatable 
	-- ORDER BY l2distance( v , random_array(128, 0, 128))  ASC LIMIT 115;
	
	-- step 1 
	-- assign level for every id.
	--getRandomLevel
	-- double r = -log(distribution(level_generator_)) * reverse_size;
	--delete from datatable_index;
	--select least(floor(-log(random())*10)::INT,20)
	--insert into datatable_index(id,neighbour,hnsw_level,distance)
	--SELECT id,id,least(floor(-log(random())*10)::INT,20),3e38::REAL FROM datatable;
	
	--select hnsw_level,count(*) from datatable_index group by hnsw_level order by hnsw_level;
CREATE OR REPLACE FUNCTION public.search_layer_nearest(arr HNSWPOINT[]) RETURNS INT LANGUAGE plpgsql AS $BODY2$	
DECLARE
 i INT;
 mindistance REAL;
 arraysize INT;
 foundmin INT;
BEGIN
 foundmin=1;
 mindistance=arr[1].distance;
 arraysize=array_length(arr,1);
 i:=2;
 WHILE i<=arraysize LOOP
  IF (arr[i].distance<mindistance) THEN
   foundmin:=i;
   mindistance:=arr[i].distance;
  END IF;
  i:=i+1;
 END LOOP;
 return foundmin;
END;
$BODY2$	;

CREATE OR REPLACE FUNCTION public.search_layer_furthest(arr HNSWPOINT[]) RETURNS INT LANGUAGE plpgsql AS $BODY3$	
DECLARE
 i INT;
 mindistance REAL;
 arraysize INT;
 foundmin INT;
BEGIN
 foundmin=1;
 mindistance=arr[1].distance;
 arraysize=array_length(arr,1);
 i:=2;
 WHILE i<=arraysize LOOP
  IF (arr[i].distance>mindistance) THEN
   foundmin:=i;
   mindistance:=arr[i].distance;
  END IF;
  i:=i+1;
 END LOOP;
 return foundmin;
END;
$BODY3$	;



CREATE OR REPLACE FUNCTION public.hnsw_search_layer(q_point HNSWPOINT, ep HNSWPOINT[],ef INT, l INT) 
RETURNS HNSWPOINT[] 
LANGUAGE plpgsql AS $BODY1$
DECLARE 
W_retvalue HNSWPOINT[];
v_visited INT[];
C_candidates HNSWPOINT[];
tmp HNSWPOINT;
nearestC INT;
furthestW INT;
c_nearest HNSWPOINT;
f_furthest HNSWPOINT;
e_neighbour INT;
e_neighbours INT[];
e_point HNSWPOINT;
cursor_neighbours refcursor;
iCounter INT;
iLength INT;
--t1 timestamp;
--tdiff1 REAL;
--t2 timestamp;
--tdiff2 REAL;
--t3 timestamp;
--tdiff3 REAL;
--t4 timestamp;
--tdiff4 REAL;
--t5 timestamp;
--tdiff5 REAL;
--ttmp timestamp;

begin
--tdiff1:=0::REAL;
--tdiff2:=0::REAL;
--tdiff3:=0::REAL;
--tdiff4:=0::REAL;
--tdiff5:=0::REAL;
--raise info ' hnsw_search_layer NEIGHBOUR at level=%, returned %,q=%',l,array_length(ep,1),q_point.id;
iLength:=array_length(ep,1);
iCounter:=1;
WHILE iCounter<=iLength LOOP
 v_visited[iCounter]:=(ep[iCounter]).id;
 iCounter:=iCounter+1;
END LOOP;
--raise info ' hnsw_search_layer NEIGHBOUR at level=%, returned %,q=%',l,array_length(v_visited,1),q_point.id;
C_candidates:=ep;
--raise info ' hnsw_search_layer NEIGHBOUR at level=%, returned %,q=%',l,array_length(C_candidates,1),q_point.id;
W_retvalue:=ep;

--raise info ' hnsw_search_layer NEIGHBOUR at level=%, returned %,q=%',l,array_length(W_retvalue,1),q_point.id;
--t1:=timeofday();
WHILE array_length(C_candidates,1)>0 LOOP
 nearestC:=public.search_layer_nearest(C_candidates);
 c_nearest:=C_candidates[nearestC];
 C_candidates:=array_remove(C_candidates,c_nearest);
 furthestW:=public.search_layer_furthest(W_retvalue);
 
 EXIT WHEN (c_nearest.distance > W_retvalue[furthestW].distance );
 --open cursor_neighbours for 
 --select a.neighbour from public.datatable_index as a 
 --	where a.hnsw_level=l and a.id=c_nearest.id and a.id<>a.neighbour ;
  SELECT ARRAY(select a.neighbour from public.datatable_index as a 
	where a.hnsw_level=l and a.id=c_nearest.id and a.id<>a.neighbour) INTO e_neighbours ;
  iLength:=array_length(e_neighbours,1);
  iCounter:=1;
  --t2:=timeofday();
  WHILE iCounter<=iLength LOOP
      --FETCH cursor_neighbours INTO e_neighbour;
    e_neighbour:=e_neighbours[iCounter];  
     -- exit when no more row to fetch
     --exit when not found;
	 --t3:=timeofday();
	 IF NOT ( e_neighbour=ANY(v_visited) ) THEN 
	  v_visited:=array_append(v_visited,e_neighbour);
	  --t5:=timeofday();
	  furthestW:=search_layer_furthest(W_retvalue);
	  --ttmp=timeofday();
	  --tdiff5:=tdiff5+ extract(epoch from ttmp)-extract(epoch from t5);
	  
	  -- if distance(e, q) < distance(f, q) or │W│ < ef
	  e_point.id:=e_neighbour;
	  
	  select v into e_point.v from public.datatable as dt where dt.id=e_neighbour; 
	  e_point.distance:=l2distance(e_point.v,q_point.v);
	  --t4:=timeofday();
	  IF (e_point.distance < W_retvalue[furthestW].distance) OR array_length(W_retvalue,1)<ef THEN 
	   C_candidates:=array_append(C_candidates,e_point);
	   W_retvalue:=array_append(W_retvalue,e_point);
	   --raise info ' hnsw_search_layer APPEND at level=%, returned W_retvalue % from %',l,array_length(W_retvalue,1),ef;
	   -- if │W│ > ef
	   IF array_length(W_retvalue,1)>ef THEN 
	    W_retvalue:=array_remove(W_retvalue,W_retvalue[furthestW]);
	   END IF;
	  END IF;
      --ttmp=timeofday();
	  --tdiff4:=tdiff4+ extract(epoch from ttmp)-extract(epoch from t4);
	 END IF;
	 --ttmp=timeofday();
	 --tdiff3:=tdiff3+ extract(epoch from ttmp)-extract(epoch from t3);

   iCounter:=iCounter+1; 
	end loop;
	--ttmp=timeofday();
	--tdiff2:=tdiff2+ extract(epoch from ttmp)-extract(epoch from t2);

  --CLOSE cursor_neighbours;
END LOOP;
	--ttmp=timeofday();
	--tdiff1:=tdiff1+ extract(epoch from ttmp)-extract(epoch from t1);

  --raise info ' hnsw_search_layer RETURN at level=%, returned W_retvalue % from %',l,array_length(W_retvalue,1),ef;
  --IF l=0 THEN
  --raise info ' hnsw_search_layer RETURN at level=%, loop %, loop2 %, IF1 %, IF1select %, IF2 %',
  --l,tdiff1,tdiff2,tdiff3,tdiff5,tdiff4;
  --END IF;
  return W_retvalue;
end;
$BODY1$ ;

--select search_layer(10104,10103,10,10);

--select 1 where 4=ANY(ARRAY[1,2,3])


CREATE OR REPLACE PROCEDURE public.hnsw_index(INOUT hnswinfo hnsw_param , q_point HNSWPOINT, paramM INT,paramMmax INT,efConstruction INT, paramMl INT) 
LANGUAGE plpgsql AS $BODY5$
DECLARE 
W_retvalue HNSWPOINT[];
neighbours HNSWPOINT[];
cursor_neighbours refcursor;
l_newelementlevel INT;
lc INT;
entrypoint HNSWPOINT;
entrypointnum INT;
rowsaffected INT;
entrypoints HNSWPOINT[];
begin
 entrypoint.id:=hnswinfo.entrypoint;
 entrypoint.distance=3e38;
 entrypoint.v:=hnswinfo.epvector;
 entrypoints[1]=entrypoint;
 l_newelementlevel:=least(floor(-log(random())*10)::INT,20);
 --raise info ' INSIDE at level=%,q=%',l_newelementlevel,q_point.id;
 insert into public.datatable_index(id,neighbour,hnsw_level,distance)
 SELECT q_point.id,q_point.id,serie,3e38::REAL FROM generate_series(0,l_newelementlevel) as serie;
--q_point.id:=q;
--select v into q_point.v from datatable as dt where dt.id=q; 
--tmp.id=ep;
--select v into tmp.v from datatable as dt where dt.id=ep; 
--tmp.distance=l2distance(tmp.v,q_point.v);
 lc:=hnswinfo.eplevel;
 --raise info ' ENTRYLEVEL at level=%,q=%',lc,q_point.id;
 WHILE lc>=(l_newelementlevel+1) LOOP
 --raise info ' LOOK at level=%,q=%',lc,q_point.id;
  W_retvalue:=hnsw_search_layer(q_point,entrypoints,1,lc);
  --raise info ' SEARCHED % at level=%,q=%',array_length(W_retvalue,1),lc,q_point.id;
  entrypointnum:=public.search_layer_nearest(W_retvalue);
  entrypoints[1]=W_retvalue[entrypointnum];
  lc:=lc-1;
 END LOOP;
 lc:=LEAST(hnswinfo.entrypoint,l_newelementlevel);
 WHILE lc>=0 LOOP
 --raise info ' BUILD at level=%,q=%',lc,q_point.id;
  W_retvalue:=public.hnsw_search_layer(q_point,entrypoints,efConstruction,lc);
  --raise info ' SEARCHED LAYER at level=%, returned %,q=%',lc,array_length(W_retvalue,1), q_point.id;
  neighbours:=public.select_heighbours(q_point,W_retvalue,paramM,lc);
  --raise info ' SELECTED NEIGHBOUR at level=%, returned %,q=%',lc,array_length(neighbours,1),q_point.id;
  INSERT INTO public.datatable_index (id,neighbour,hnsw_level,distance)
  WITH neighboursList AS (
	  SELECT DISTINCT UNNEST(neighbours) as neighbour
  )--, maxdistances AS (
   --select a.id,max(a.distance) as maxdistance 
--	  from public.datatable_index as a
--	  join neighboursList as b on a.id=(b.neighbour).id
--	  WHERE a.hnsw_level=lc and a.id<>a.neighbour
--	  group by a.id
-- )  
  SELECT (a.neighbour).id,q_point.id,lc,(a.neighbour).distance 
  FROM neighboursList as a
  --JOIN maxdistances as b on (a.neighbour).id=b.id
  --WHERE (a.neighbour).distance < b.maxdistance
  UNION ALL
  SELECT q_point.id,(a.neighbour).id,lc,(a.neighbour).distance 
  FROM neighboursList as a;
  GET DIAGNOSTICS rowsaffected = ROW_COUNT;
  --raise info ' INSERTED qty = % at level=%,for q=%',rowsaffected,lc,q_point.id;
  -- SHRINK CONNECTIONS
  WITH neighboursList AS (
	  SELECT DISTINCT UNNEST(neighbours) as neighbour
  ), neighboursIdList AS (
	  SELECT (a.neighbour).id as neighbourid FROM neighboursList as a
  ), rownumbers AS (
  select b.id,b.neighbour,b.distance, 
	  ROW_NUMBER() OVER (PARTITION BY b.id ORDER BY b.id,b.distance) as rownumber 
	  from neighboursIdList as a
	  join datatable_index as b on a.neighbourid=b.id
	  WHERE hnsw_level=lc
  )
  DELETE FROM datatable_index as a
  USING rownumbers as b WHERE  a.id=b.id AND a.neighbour=b.neighbour and a.hnsw_level=lc
  AND b.rownumber>paramMmax;
  GET DIAGNOSTICS rowsaffected = ROW_COUNT;
  --raise info 'DELETED in SHRINK qty = % at level=%,q=%',rowsaffected,lc,q;
  entrypoints:=W_retvalue;
  lc:=lc-1;
 END LOOP;
 IF l_newelementlevel>hnswinfo.eplevel THEN
  hnswinfo.eplevel=l_newelementlevel;
  hnswinfo.entrypoint=q_point.id; 
  hnswinfo.epvector=q_point.v;
 END IF;
end;
$BODY5$;

CREATE OR REPLACE FUNCTION public.select_heighbours(q_point HNSWPOINT, Candidates HNSWPOINT[],Mquantity INT, lc INT) RETURNS HNSWPOINT[] LANGUAGE plpgsql AS $BODY6$
DECLARE 
W_retvalue HNSWPOINT[];
intCandidates INT[];
iCounter INT;
lengthCandidates INT;
BEGIN
 lengthCandidates:=array_length(Candidates,1);
 iCounter:=1;
 WHILE iCounter<=lengthCandidates LOOP
  intCandidates:=array_append(intCandidates,Candidates[iCounter].id);
  iCounter:=iCounter+1;
 END LOOP;
 --raise info ' select_heighbours qty = % at level=%,q=%',array_length(intCandidates,1),lc,q;
 WITH list AS (
  select DISTINCT a.neighbour from public.datatable_index as a 
	where a.hnsw_level=lc and a.id=ANY(intCandidates)   
 ), distances AS (
  select a.id,a.v,l2distance(a.v,q_point.v) as rDistance 
	 FROM public.datatable as a
	 join list as b on b.neighbour=a.id
 )
 SELECT array_agg(ROW(a.id,a.rDistance,a.v)::HNSWPOINT ORDER BY a.rDistance) INTO W_retvalue
 FROM distances as a LIMIT Mquantity;
 RETURN W_retvalue;
END;
$BODY6$ ;

CREATE OR REPLACE PROCEDURE hnsw_index_test(MQuantity INT, efConstruction INT)
LANGUAGE plpgsql AS $BODY6$
DECLARE
hnswinfo hnsw_param;
readcursor refcursor;
elementid INT;
elementvector REAL[];
elementq HNSWPOINT;
iCounter INT;
BEGIN
hnswinfo.entrypoint:=-1;
hnswinfo.eplevel:=-1;
hnswinfo.epvector:=ARRAY[0,0,0];
hnswinfo.tablename:='data';
DELETE FROM public.datatable_index;
OPEN readcursor for 
 SELECT a.id,a.v 
 FROM public.datatable as a 
 ORDER BY a.id;
 iCounter:=0;
 LOOP
 FETCH readcursor INTO elementid,elementvector;
     -- exit when no more row to fetch
     exit when not found;
 elementq.id:=elementid;
 elementq.v:=elementvector;
 elementq.distance=3e38;
 IF MOD(elementid,100)=0 THEN
  raise info 'Time %, entrypoint=%, level=%, vector num=%',
  timeofday(),hnswinfo.entrypoint ,hnswinfo.eplevel,elementid;
 END IF;
 CALL public.hnsw_index(hnswinfo,elementq,MQuantity,MQuantity*2,efConstruction,MQuantity*2);
 iCounter:=iCounter+1;
 --EXIT WHEN iCounter>2000;
END LOOP;
CLOSE readcursor;
INSERT INTO public.datatable_index (id,neighbour,hnsw_level,distance)
VALUES (-1,hnswinfo.entrypoint,hnswinfo.eplevel,0);
end;
$BODY6$;


--select * from generate_series(1,1000000) as serie
--select hnsw_level,id,count(*) from datatable_index group by hnsw_level,id order by count(*) desc

--select * FROM 
--(select ARRAY[ROW(1,1,ARRAY[1])::HNSWPOINT,ROW(2,2,ARRAY[2])::HNSWPOINT,ROW(3,3,ARRAY[3])::HNSWPOINT] as arr) as a
--where 1=ANY((a.arr))
  /*
  WITH rownumbers AS (
  select id,neighbour,distance, ROW_NUMBER() OVER (ORDER BY id,distance) as rownumber 
	  from datatable_index WHERE hnsw_level=0
  )
  DELETE FROM datatable_index as a
  USING rownumbers as b WHERE  a.id=b.id AND a.neighbour=b.neighbour and a.hnsw_level=0
  AND b.rownumber>20
  */
  --ORDER BY id,distance
  
CREATE OR REPLACE PROCEDURE hnsw_generate_test_data(Quantity INT)
LANGUAGE plpgsql AS $BODY7$
DECLARE
iCounter INT;
BEGIN
DELETE FROM public.datatable;
iCounter:=0;
 WHILE iCounter<Quantity LOOP
  INSERT INTO public.datatable (id, v) VALUES 
    (iCounter, test_array(3, iCounter::REAL));
  EXIT WHEN iCounter>Quantity;
  iCounter:=iCounter+1;
 END LOOP;
end;
$BODY7$;

--call hnsw_generate_test_data();

CREATE OR REPLACE PROCEDURE hnsw_generate_test_query(testvalue REAL, Mquantity INT, sfSearch INT)
LANGUAGE plpgsql AS $BODY7$
DECLARE
hnswinfo hnsw_param;
iCounter INT;
q_point HNSWPOINT;
retvalue INT[];
BEGIN
--hnswinfo.entrypoint:=-1;
--hnswinfo.eplevel:=-1;
hnswinfo.epvector:=ARRAY[0];
hnswinfo.tablename:='data';
q_point.id=-1;
q_point.distance=0;
q_point.v=test_array(3, testvalue);
SELECT a.neighbour,a.hnsw_level INTO hnswinfo.entrypoint,hnswinfo.eplevel  
 FROM datatable_index as a 
 WHERE a.id=-1;
SELECT a.v INTO hnswinfo.epvector  
 FROM datatable as a 
 WHERE a.id=hnswinfo.entrypoint;

iCounter:=0;
-- WHILE iCounter<1000 LOOP
--  INSERT INTO public.datatable (id, v) VALUES 
    select public.hnsw_knn_search(hnswinfo,q_point ,Mquantity,sfSearch) INTO retvalue;
	raise info 'Vector % % % % %', retvalue[1],retvalue[2],retvalue[3],retvalue[4],retvalue[5];
	raise info 'Vector % % % % %', retvalue[6],retvalue[7],retvalue[8],retvalue[9],retvalue[10];
--  EXIT WHEN iCounter>1000;
  iCounter:=iCounter+1;
-- END LOOP;
end;
$BODY7$;

CREATE OR REPLACE FUNCTION hnsw_query_l2(testvalue REAL[], Mquantity INT, sfSearch INT)
RETURNS INT[]
LANGUAGE plpgsql AS $BODY9$
DECLARE
hnswinfo hnsw_param;
iCounter INT;
q_point HNSWPOINT;
retvalue INT[];
BEGIN
--raise info '% hnsw_query_l2 START',timeofday();
hnswinfo.tablename:='data';
q_point.id=-1;
q_point.distance=0;
q_point.v=testvalue;
SELECT a.neighbour,a.hnsw_level INTO hnswinfo.entrypoint,hnswinfo.eplevel  
 FROM datatable_index as a 
 WHERE a.id=-1;
SELECT a.v INTO hnswinfo.epvector  
 FROM datatable as a 
 WHERE a.id=hnswinfo.entrypoint;
SELECT public.hnsw_knn_search(hnswinfo,q_point ,Mquantity,sfSearch) INTO retvalue;
	--raise info 'Vector % % % % %', retvalue[1],retvalue[2],retvalue[3],retvalue[4],retvalue[5];
	--raise info 'Vector % % % % %', retvalue[6],retvalue[7],retvalue[8],retvalue[9],retvalue[10];
	--raise info '% hnsw_query_l2 FINISH',timeofday();
RETURN retvalue;
end;
$BODY9$;

--DROP FUNCTION hnsw_knn_search(hnsw_param,hnswpoint,integer,integer)
CREATE OR REPLACE FUNCTION public.hnsw_knn_search(IN hnswinfo hnsw_param , q_point HNSWPOINT, 
												  "Kquantity" INT, efSearch INT) 
RETURNS INT[]
LANGUAGE plpgsql AS $BODY8$
DECLARE 
W_retvalue HNSWPOINT[];
I_retvalue INT[];
lc INT;
entrypoint HNSWPOINT;
entrypointnum INT;
entrypoints HNSWPOINT[];
begin
 entrypoint.id:=hnswinfo.entrypoint;
 entrypoint.distance=3e38;
 entrypoint.v:=hnswinfo.epvector;
 entrypoints[1]=entrypoint;
  lc:=hnswinfo.eplevel;
 --raise info '% ENTRYLEVEL at level=%,q=%',timeofday(),lc,q_point.id;
 WHILE lc>=1 LOOP
 --raise info ' LOOK at level=%,q=%',lc,q_point.id;
  W_retvalue:=hnsw_search_layer(q_point,entrypoints,1,lc);
  --raise info ' SEARCHED % at level=%,q=%',array_length(W_retvalue,1),lc,q_point.id;
  entrypointnum:=public.search_layer_nearest(W_retvalue);
  entrypoints[1]=W_retvalue[entrypointnum];
  lc:=lc-1;
 END LOOP;
 
 --raise info '% BUILD at level=%,q=%',timeofday(),lc,q_point.id;
  W_retvalue:=public.hnsw_search_layer(q_point,entrypoints,efSearch,0);
  --raise info '% SEARCHED at level=%,q=%',timeofday(),lc,q_point.id;
-- return K nearest elements from W to q
  WITH retvalue1 AS (
  SELECT UNNEST(W_retvalue) as returned
  ), retvalue2 AS (
   SELECT (a.returned).id as id, (a.returned).distance as distance from retvalue1 a
  ), retvalue3 AS (
  SELECT a.id,a.distance
  from retvalue2 as a 
  order by a.distance 
  LIMIT "Kquantity"
 )	  SELECT array_agg(a.id order by a.distance) INTO I_retvalue 
  from retvalue3 as a ;
  --raise info '% RETURN at level=%,q=%',timeofday(),lc,q_point.id;
  RETURN I_retvalue;
end;
$BODY8$;

--CALL hnsw_generate_test_data(100)
--CALL hnsw_index_test(12,20);
-- SELECT hnsw_query_l2(ARRAY[1,1,1]::INT[],10,20)
--select * from datatable_index where id<>neighbour

--CALL  select  hnsw_generate_test_query(2.6,10,11)
--select * from datatable_index where id<>neighbour and id=11 order by hnsw_level,distance ;
--select id,count(*) from datatable_index where hnsw_level=0 group by id order by id 
--select -1,id,max(hnsw_level),3e38::REAL from datatable_index where hnsw_level>=20 group by id order by id LIMIT 1
--where id<>neighbour and id=11 order by hnsw_level,distance 
--BEGIN;
--ROLLBACK;
/*
   WITH neighboursList AS (
	  -- SELECT DISTINCT UNNEST(neighbours) as neighbour
	  select ROW(id,0,ARRAY[0])::HNSWPOINT as neighbour from  datatable
  ), neighboursIdList AS (
	  SELECT (a.neighbour).id as neighbourid FROM neighboursList as a
  ), rownumbers AS (
  select b.id,b.neighbour,b.distance, ROW_NUMBER() OVER (
	  PARTITION BY b.id
	  ORDER BY b.id,b.distance) as rownumber 
	  from neighboursIdList as a
	  join datatable_index as b on a.neighbourid=b.id
	  WHERE hnsw_level=0 -- lc
  )
  --DELETE FROM datatable_index as a
  --USING rownumbers as b WHERE  a.id=b.id AND a.neighbour=b.neighbour and a.hnsw_level=0 -- lc
  --AND b.rownumber>20; --paramMmax;
  select a.*,b.* FROM datatable_index as a
  JOIN rownumbers as b ON  a.id=b.id AND a.neighbour=b.neighbour and a.hnsw_level=0 -- lc
  WHERE b.rownumber>20; --paramMmax;
  */
  
  --BEGIN;
  --DELETE FROM datatable_index;
  /* -- generate hnsw index by random values
  INSERT INTO datatable_index (id,neighbour,hnsw_level,distance)
  WITH serie AS (
   select least(floor(-log(random())*10)::INT,20) as maxlevel,generate_series(1,59999) as serie
  ), members AS (
   select serie as id,genlevel as hnsw_level from serie as a
	  join generate_series(0,a.maxlevel) as genlevel on 1=1
  ), lines AS (
  select c.id,
  c.hnsw_level,floor(random()*59999)::INT+1 as neighbour,genside
 from members as c
  join generate_series(1,20) as genneighbour on 1=1
  join generate_series(0,1) as genside on 1=1
  ), alllines AS (
  select DISTINCT
  CASE WHEN d.genside=0 THEN d.id ELSE d.neighbour END  as id ,
  CASE WHEN d.genside=1 THEN d.id ELSE d.neighbour END  as neighbour ,
  d.hnsw_level from lines as d
  ) 
  select e.id,e.neighbour,e.hnsw_level,
  CASE WHEN e.id=e.neighbour THEN 3e38 ELSE random()*100 END as distance 
  from alllines as e
  --order by e.hnsw_level,e.id,e.neighbour
  ;
  INSERT INTO datatable_index (id,neighbour,hnsw_level,distance)
  select -1,id,max(hnsw_level),3e38::REAL 
  from datatable_index 
  where hnsw_level>=20 
  group by id order by id LIMIT 1;
  */
  
  CREATE OR REPLACE PROCEDURE hnsw_index_test60000(MQuantity INT, efConstruction INT)
LANGUAGE plpgsql AS $BODY6$
DECLARE
hnswinfo hnsw_param;
readcursor refcursor;
elementid INT;
elementvector REAL[];
elementq HNSWPOINT;
iCounter INT;
BEGIN
hnswinfo.tablename:='data';
SELECT a.neighbour,a.hnsw_level INTO hnswinfo.entrypoint,hnswinfo.eplevel  
 FROM datatable_index as a 
 WHERE a.id=-1;
SELECT a.v INTO hnswinfo.epvector  
 FROM datatable as a 
 WHERE a.id=hnswinfo.entrypoint;
OPEN readcursor for 
 SELECT a.id,a.v 
 FROM public.datatable as a
 WHERE id=0
 ORDER BY a.id;
 iCounter:=0;
 LOOP
 FETCH readcursor INTO elementid,elementvector;
     -- exit when no more row to fetch
     exit when not found;
 elementq.id:=elementid;
 elementq.v:=elementvector;
 elementq.distance=3e38::REAL;
 IF MOD(elementid,100)=0 THEN
  --raise info 'Time1 %, entrypoint=%, level=%, vector num=%',
  --timeofday(),hnswinfo.entrypoint ,hnswinfo.eplevel,elementid;
 END IF;
 CALL public.hnsw_index(hnswinfo,elementq,MQuantity,MQuantity*2,efConstruction,MQuantity*2);
 iCounter:=iCounter+1;
 --raise info 'Time2 %, entrypoint=%, level=%, vector num=%',
 -- timeofday(),hnswinfo.entrypoint ,hnswinfo.eplevel,elementid;
 --EXIT WHEN iCounter>2000;
END LOOP;
CLOSE readcursor;
end;
$BODY6$;

--CALL hnsw_index_test60000(20,20);

--SELECT hnsw_query_l2(test_array(784,11),10,20);
--SELECT hnsw_query_l2(test_array(784,12),10,20);
--test_array
--
--select cTID,*
--delete 
--from datatable_index where id=0 OR neighbour=0;
--analyze datatable_index;
--vacuum datatable_index;

CREATE OR REPLACE FUNCTION hnsw_query_l2_delme(testvalue REAL[], Mquantity INT, sfSearch INT)
RETURNS INT[]
LANGUAGE plpgsql AS $BODY9$
DECLARE
hnswinfo hnsw_param;
iCounter INT;
q_point HNSWPOINT;
retvalue INT[];
BEGIN
--raise info '% hnsw_query_l2 START',timeofday();
hnswinfo.tablename:='data';
q_point.id=-1;
q_point.distance=0;
q_point.v=testvalue;
--raise info '% hnsw_query_l2 START1',timeofday();
SELECT a.neighbour,a.hnsw_level INTO hnswinfo.entrypoint,hnswinfo.eplevel  
 FROM datatable_index as a 
 WHERE a.id=-1;
 --raise info '% hnsw_query_l2 START2',timeofday();
SELECT a.v INTO hnswinfo.epvector  
 FROM datatable as a 
 WHERE a.id=hnswinfo.entrypoint;
	--raise info '% hnsw_query_l2 FINISH',timeofday();
RETURN retvalue;
end;
$BODY9$;



CREATE OR REPLACE FUNCTION hnsw_query_ep_l2(testvalue REAL[],epid INT,eplevel INT,Mquantity INT, sfSearch INT)
RETURNS TABLE (neighbours INT)
LANGUAGE plpgsql AS $BODY9$
DECLARE
hnswinfo hnsw_param;
iCounter INT;
q_point HNSWPOINT;
retvalue INT[];
t1 timestamp;
tdiff1 REAL;
ttmp timestamp;

BEGIN
tdiff1=0::REAL;
--raise info '% hnsw_query_l2 START',timeofday();
t1:=timeofday();
hnswinfo.tablename:='data';
q_point.id=-1;
q_point.distance=0;
q_point.v=testvalue;
hnswinfo.entrypoint:=epid;
hnswinfo.eplevel := eplevel;
SELECT a.v INTO hnswinfo.epvector  
 FROM datatable as a 
 WHERE a.id=hnswinfo.entrypoint;
SELECT public.hnsw_knn_search(hnswinfo,q_point ,Mquantity,sfSearch) INTO retvalue;
	--raise info 'Vector % % % % %', retvalue[1],retvalue[2],retvalue[3],retvalue[4],retvalue[5];
	--raise info 'Vector % % % % %', retvalue[6],retvalue[7],retvalue[8],retvalue[9],retvalue[10];
	ttmp=timeofday();
	tdiff1:=tdiff1+ extract(epoch from ttmp)-extract(epoch from t1);
	--raise info '% hnsw_query_l2 FINISH diff=%',timeofday(),tdiff1;
	
RETURN QUERY SELECT unnest(retvalue) as neighbours;
end;
$BODY9$;

--SELECT hnsw_query_ep_l2(test_array(784,10),3,20,10,300);
CREATE OR REPLACE PROCEDURE save_data_index()

LANGUAGE plpgsql AS $BODY10$
BEGIN
INSERT INTO public.datatable_index_save select * from public.datatable_index;
END;
$BODY10$;

CREATE OR REPLACE PROCEDURE restore_data_index()

LANGUAGE plpgsql AS $BODY10$
BEGIN
INSERT INTO public.datatable_index select * from public.datatable_index_save;
END;
$BODY10$;

CREATE OR REPLACE FUNCTION hnsw_get_entrypoint() RETURNS table (epoint INT, elevel INT)
LANGUAGE plpgsql AS $BODY11$
BEGIN
RETURN QUERY SELECT a.neighbour as epoint,a.hnsw_level as elevel
 FROM datatable_index as a 
 WHERE a.id=-1;
 END;
$BODY11$ ;

-- select * from hnsw_get_entrypoint()
-- drop function hnsw_get_entrypoint()
-- CALL save_data_index();
-- CALL restore_data_index();
-- DROP PROCEDURE restore_data_index()
-- DROP PROCEDURE save_data_index()
-- DROP FUNCTION  hnsw_query_ep_l2(testvalue REAL[],epid INT,eplevel INT,Mquantity INT, sfSearch INT)
-- DROP FUNCTION hnsw_query_l2_delme(testvalue REAL[], Mquantity INT, sfSearch INT)
-- DROP PROCEDURE hnsw_index_test60000(MQuantity INT, efConstruction INT)

-- select unnest(ARRAY[1,2,3]) as neighbour
