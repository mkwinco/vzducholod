-- Name: distance(name, integer, integer); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.distance(sch name, aid integer, bid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE 
	a u_simple1.tile%ROWTYPE;
	b u_simple1.tile%ROWTYPE;
BEGIN

-- check existence of the schema
	if NOT (SELECT * FROM general.schemaexists(sch)) THEN return FALSE; END if;
	EXECUTE 'SET search_path TO ' ||  sch;

	SELECT * INTO a FROM tile WHERE tileID=aid;
	SELECT * INTO b FROM tile WHERE tileID=bid;

--RAISE NOTICE 'Tiles (%,%)',aid,bid;

	IF (a IS NULL) OR (b IS NULL) THEN RETURN NULL; END IF;

	return (abs(a.x-b.x)+abs(a.y-b.y));

END;
$$;


--
