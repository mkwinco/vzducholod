-- Name: create_random_map(name, integer, integer, integer, integer); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.create_random_map(sch name, xright integer, xleft integer, yright integer, yleft integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
	r real;
	t int;
BEGIN 

if NOT (SELECT * FROM general.schemaexists(sch)) THEN return 0; END if;
EXECUTE 'SET search_path TO ' ||  sch;

FOR x IN xright..xleft LOOP
	FOR y IN yright..yleft LOOP

		r = random()*20;

		if (r<6) THEN t := 500001;
		ELSIF (r<7) THEN t:=500001;
		else t:=500002;
		END IF;

		EXECUTE 'INSERT INTO ' || sch || '.tile(x,y,type_tileID) VALUES ($2,$3,$4)' USING sch,x,y,t;
		
	END LOOP;
END LOOP;


return 1;

END;
$_$;


--
