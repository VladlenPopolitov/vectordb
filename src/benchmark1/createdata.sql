CREATE TABLE IF NOT EXISTS benchmark1 (id bigserial PRIMARY KEY, embedding vector(4));
ALTER TABLE benchmark1 ALTER COLUMN embedding SET STORAGE PLAIN;
CREATE TABLE IF NOT EXISTS benchmark768 (id bigserial PRIMARY KEY, embedding vector(768));
ALTER TABLE benchmark768 ALTER COLUMN embedding SET STORAGE PLAIN;

-- create index
CREATE INDEX ON benchmark768 USING hnsw(embedding vector_l2_ops) WITH (m=16, ef_construction=64);
--NOTICE:  hnsw graph no longer fits into maintenance_work_mem after 17991 tuples
--DETAIL:  Building will take significantly more time.
--HINT:  Increase maintenance_work_mem to speed up builds.


create OR REPLACE procedure createdata("p_quantity" INTEGER)
LANGUAGE plpgsql
AS  $BODY$
DECLARE 
 var_from REAL;
 var_to REAL;
 var_i REAL;
 var_step REAL;
BEGIN
var_from:=0.;
var_to:=3.14159265*1.5;
var_step:=(var_to-var_from)/"p_quantity";
var_i:=var_from;
WHILE var_i<var_to LOOP
INSERT INTO benchmark1 (embedding) VALUES (CONCAT('[',SIN(var_i)::VARCHAR(40),',',COS(var_i)::VARCHAR(40),',',SIN(var_i)::VARCHAR(40),',',COS(var_i)::VARCHAR(40),']')::vector(4));
var_i:=var_i+var_step;
END LOOP;

END;
$BODY$ ;

create OR REPLACE procedure createdata768("p_quantity" INTEGER,"p_vectorlength" INTEGER)
LANGUAGE plpgsql
AS  $BODY$
DECLARE 
 var_from REAL;
 var_to REAL;
 var_i REAL;
 var_step REAL;
 var_insert VARCHAR(10000000);
 var_j INTEGER;
BEGIN
var_from:=0.;
var_to:=3.14159265*1.5;
var_step:=(var_to-var_from)/"p_quantity";
var_i:=var_from;
WHILE var_i<var_to LOOP
var_insert:=CONCAT(SIN(var_i)::VARCHAR(40),',',COS(var_i)::VARCHAR(40));
var_insert:=CONCAT(var_insert,',',var_insert); -- 4
var_insert:=CONCAT(var_insert,',',var_insert); -- 8
var_insert:=CONCAT(var_insert,',',var_insert); -- 16
var_insert:=CONCAT(var_insert,',',var_insert); -- 32
var_insert:=CONCAT(var_insert,',',var_insert); -- 64
var_insert:=CONCAT(var_insert,',',var_insert); -- 128
var_insert:=CONCAT(var_insert,',',var_insert); -- 258
var_insert:=CONCAT(var_insert,',',var_insert,',',var_insert); -- 768
INSERT INTO benchmark768 (embedding) VALUES (CONCAT('[',var_insert,']')::vector(768));
var_i:=var_i+var_step;
END LOOP;

END;
$BODY$ ;


create OR REPLACE procedure benchmartdata768(in "p_cycles" INTEGER, inout "p_count" INTEGER ,inout "p_starttime" timestamp, inout "p_endtime" timestamp)
LANGUAGE plpgsql
AS  $BODY$
DECLARE 
 var_from INTEGER;
 var_to INTEGER;
 var_i INTEGER;
 var_step INTEGER;
 var_value1 VECTOR(768);
 var_value2 VECTOR(768);
 var_value3 VECTOR(768);
 var_valuetmp INTEGER;
 var_count INTEGER;
BEGIN
select embedding INTO var_value1 from benchmark768 where id=3;
select embedding INTO var_value2 from benchmark768 where id=50000;
select embedding INTO var_value3 from benchmark768 where id=90000;
var_count:=0;
var_from:=1;
var_to:="p_cycles";
"p_starttime":=clock_timestamp();
WHILE var_to>0 LOOP
select id INTO var_valuetmp from benchmark768 ORDER BY embedding <-> var_value1 LIMIT 1;
IF var_valuetmp=3 THEN var_count:=var_count+1; END IF;
select id INTO var_valuetmp from benchmark768 ORDER BY embedding <-> var_value2 LIMIT 1;
IF var_valuetmp=50000 THEN var_count:=var_count+1; END IF;
select id INTO var_valuetmp from benchmark768 ORDER BY embedding <-> var_value3 LIMIT 1;
IF var_valuetmp=90000 THEN var_count:=var_count+1; END IF;
var_to:=var_to-1;
END LOOP;
"p_endtime":=clock_timestamp();
"p_count":=var_count;

END;
$BODY$;
