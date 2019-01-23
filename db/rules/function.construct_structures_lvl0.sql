-- Name: construct_structures_lvl0(name, integer, integer[]); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.construct_structures_lvl0(sch name, tsid integer, tileids integer[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	st rules.type_structure%ROWTYPE;
	xsize int;
	ysize int;
	tnum int;
	area int;
	xplusy int;
	sid INT; --structure.structureID%TYPE;
BEGIN

-- check existence of the schema
	if NOT (SELECT * FROM general.schemaexists(sch)) THEN return FALSE; END if;
	EXECUTE 'SET search_path TO ' ||  sch;

	-- having structure type info will be handy
	SELECT * INTO st FROM rules.type_structure;
	-- as well as having tile infos
	CREATE TEMPORARY TABLE t ON COMMIT DROP AS (SELECT * FROM tile WHERE tileID IN (tileIDs) ) ;

-- check whether tile structure allows this type of structure (whether tiles array contains valid tileID-s in rect shape of appropriate size)
	-- find size of the selected rectangle
	SELECT max(x)-min(x),max(y)-min(y),count(x) INTO xsize,ysize,tnum FROM t;
	-- area and radii/2 (radii/2=x+y) are important to limit size of the structure
	area:=xsize * ysize; xplusy:=xsize + ysize;
	-- now the sizes must fit and tnum == xsize * ysize - ALL tiles inside rectangle must be from the input array tileids
	IF (tnum <> area) THEN RETURN FALSE; END IF;
	-- now compare the area and radii against allowed values for the type (NULL values behaviour questionable)
	IF NOT ( (area BETWEEN st.area_min AND st.area_max) AND (xplusy between st.xplusy_min and st.xplusy_max) ) THEN 
		-- not in allowed type structure size range
		return FALSE;
	END IF;
	

-- check whether the tiles are free and eligible for construction
	-- are all tiles empty? (all new structures require empty ground)
	IF NOT (SELECT EXISTS(SELECT 1 FROM t WHERE structureID IS NOT NULL LIMIT 1)) THEN 
		return FALSE;
	END IF;
	-- and allowing this type of construction?
	-- find if there is any field, which type is not among the ones allowed in the table (the one with long name)
	IF (SELECT EXISTS(SELECT 1 FROM t WHERE type_tileID NOT IN (SELECT type_tileID FROM rules.type_structures_allowed_on_type_tiles WHERE type_structureID=tsid))) THEN
		RETURN FALSE;
	END IF;
	
-- UP TO HERE, THE CODE IS VIRTUALY THE SAME FOR CONSTRUCTION OF A HIGHER LEVEL STRUCTURE - I.E. FIRST PLACING THE CONSTRUCTION SITE, THEN ASSIGNING THE APPROPRIATE ACTIVITY
-- So the good start is then to identify whether this is a lvl0 or higher.
-- Let's take a look into type_activity_progress and check for the final product being our type_structure. If the structure is built after 0 stamina spent, then we are here....

-- check for lvl0 structures limit

-- create structure
	INSERT INTO structure(type_structureID) VALUEs (tsid) RETUrning structureID INTO sid;
	UPDATE tile SET structureID=tsid WHERE tileID IN (tileids);

	return TRUE;

END;
$$;


--
