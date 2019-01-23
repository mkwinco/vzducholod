-- Name: OBSOLETE_set_flow(name, integer[], integer); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules."OBSOLETE_set_flow"(sch name, tileids integer[], bhid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	tid 			u_simple1.tile.tileID%TYPE;
	prevtid 		u_simple1.tile.tileID%TYPE default NULL;
	tiles 			int; -- size of the array tileIDs
	l 			u_simple1.flow.length%TYPE; --real
	mm 			u_simple1.tile.movement_multiplicator%TYPE; --real

	structure_beginning 	u_simple1.structure%ROWTYPE;
	structure_end 		u_simple1.structure%ROWTYPE;
	tf			rules.type_flow.type_flowID%TYPE;
	fid			u_simple1.flow.flowID%TYPE;

	i			int default 0;
BEGIN

-- check existence of the schema
	if NOT (SELECT * FROM general.schemaexists(sch)) THEN return FALSE; END if;
	EXECUTE 'SET search_path TO ' ||  sch;

----------------------
-- size of the array will be useful
	tiles := array_upper(tileIDs,1);
RAISE NOTICE 'Array length is %',tiles;

-- a good sanity check for the length of the tileids[] list (like no flow can ever be longer than 100 tiles)

	-- certainly we will need info about all tiles in tileids[]
	CREATE TEMPORARY TABLE t ON COMMIT DROP AS (SELECT * FROM tile WHERE tileID= ANY (tileIDs) );

-- at normal circumstances, there is no reason to have any tileID twice in any flow
	IF ( (SELECT count(*)::int FROM t) != tiles) THEN RETURN FALSE; END IF;

-------------------------------------
-- check integrity of path (tileids[]) 
-- whether the tiles are roads or empty and passable
-- and calculate length for correct paths
	l:=0;
	FOREACH tid IN ARRAY tileIDs LOOP
--RAISE NOTICE 'looping tid: % ' ,tid;

		-- neighbouring tiles? (skip check for the first tile in array)
		IF (prevtid IS NOT NULL) THEN IF ( rules.distance(sch,tid,prevtid)!=1 ) THEN 
			RAISE NOTICE 'Tiles % and % are not exactly neighbours', prevtid,tid;
			RETURN FALSE; 
		END IF; END IF;


		-- tu niekde by sa dal zakomponovat fakt, ze sikmy pohyb je odmocnica z 2 krat rychlejsi ako rovny - ale zatial to tam nie je
		
		-- if it is not the first or last element, then check for road or passability and calculate flow length
		IF (tileIDs[1]!=tid) AND (tileIDs[tiles]!=tid) THEN 
			SELECT movement_multiplicator INTO mm FROM t WHERE tileID=tid;
			IF (mm IS NULL) OR (mm=0) THEN 
				RAISE NOTICE 'Impassable terrain at tile %',tid;
				RETURN FALSE;
			END IF;

			l:=l+1./mm;  -- longing for an exponential rule here... :(
		END IF;
	
	prevtid:=tid; 
	END LOOP;

RAISE NOTICE 'Length: % ' ,l;

--------------------------------
-- check existence of endpoints

	-- is there a structure?
	IF ((SELECT structureID FROM t WHERE tileID=tileIDs[1]) IS NULL OR (SELECT structureID FROM t WHERE tileID=tileIDs[tiles]) IS NULL ) THEN 
		RAISE NOTICE 'Missing structure at the end or beginning! ';
		RETURN FALSE;
	END IF;
	
	-- structure info is always nice to have
	SELECT * INTO structure_beginning FROM structure WHERE structureID=(SELECT structureID FROM t WHERE tileID=tileIDs[1]);
	SELECT * INTO structure_end FROM structure WHERE structureID=(SELECT structureID FROM t WHERE tileID=tileIDs[tiles]);

-------------------------
-- and whether they correspond to a type_flow
-- if they do ==> identify the type_flow 
-- we hiddent that into separate function returning ID of the flow_type
	tf:=rules.identify_type_flow(structure_beginning.type_structureID,structure_end.type_structureID,(bhid IS NOT NULL));

-------------------------------
-- check whether such type_flow can exist for this user/schema (some flow types are limited to 1 for given structure or bh)
	-- Bonhomme can have only one WFAssignement
	IF (tf ~ 'WFA') AND (SELECT flowID FROM bh WHERE bh=bhid) IS NOT NULL THEN

		-- then there already is a flow
		-- we will stop here and ask player to remove the old WFA first
		RAISE NOTICE 'Remove existing WFA assignement on bonhomme % first!',bhid;
		RETURN FALSE;
	END IF;

	
	-- House can be served only by one market
	IF (tf ~ 'HS') AND (SELECT flowID FROM flow WHERE end_structureID=structure_end.structureID) IS NOT NULL THEN

		-- then there already is a flow
		-- we will stop here and ask player to remove the old HS first
		RAISE NOTICE 'Remove existing HS assignement on house % first!',structure_end.structureID;
		RETURN FALSE;
	END IF;


	-- RF can by worked only by one CAMP
	IF (tf ~ 'RF') AND (SELECT flowID FROM flow WHERE end_structureID=structure_end.structureID) IS NOT NULL THEN

		-- then there already is a flow
		-- we will stop here and ask player to remove the old RF first
		RAISE NOTICE 'Remove existing RF assignement on workfield % first!',structure_end.structureID;
		RETURN FALSE;
	END IF;
	

	-- There can be only one IF between given two structures
	IF (tf ~ 'IF') AND (SELECT flowID FROM flow WHERE end_structureID=structure_end.structureID AND  structure_beginning=structure_beginning.structureID) IS NOT NULL THEN

		-- then there already is a flow
		-- we will stop here and ask player to remove the old IF first
		RAISE NOTICE 'Duplicit IF between % and % !',structure_beginning.structureID, structure_end.structureID;
		RETURN FALSE;
	END IF;	


	-- one good news, no need to check for market supply flow, as there is no limit on that - so far
----------------------------------

---------------------------- CREATE THE FLOW ---------------------------
-- insert into flow table
	INSERT INTO flow (type_flowID,start_structureID,start_structureID,"length") VALUES (tf,structure_beginning.structureID,tructure_end.structureID,l) RETURNING flowID into fid;

	-- make a sanity check about non-null fid

-- and then assign the tiles to the flow
	i:=1;
	FOREACH tid IN ARRAY tileIDs LOOP
		INSERT INTO flows_on_tiles (tileID, flowID, "order") VALUES (tid, fid, i);

		i:=i+1;
	END LOOP;
-----------------------------------

	return TRUE;

END;
$$;


--
