--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: econmod_v03; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE econmod_v03 WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C';


ALTER DATABASE econmod_v03 OWNER TO postgres;

\connect econmod_v03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: general; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA general;


ALTER SCHEMA general OWNER TO postgres;

--
-- Name: rules; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA rules;


ALTER SCHEMA rules OWNER TO postgres;

--
-- Name: plperl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plperl;


ALTER PROCEDURAL LANGUAGE plperl OWNER TO postgres;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


SET search_path = general, pg_catalog;

--
-- Name: schemaexists(name); Type: FUNCTION; Schema: general; Owner: postgres
--

CREATE FUNCTION schemaexists(sch name) RETURNS boolean
    LANGUAGE sql
    AS $$

-- faster way
SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = sch);

-- purist way
-- SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = sch);

$$;


ALTER FUNCTION general.schemaexists(sch name) OWNER TO postgres;

SET search_path = rules, pg_catalog;

--
-- Name: CHECK_THIS_set_activity(name, integer, integer); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION "CHECK_THIS_set_activity"(sch name, taid integer, sid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	ta rules.type_activity%ROWTYPE;
	ts rules.type_structure%ROWTYPE;
	s u_simple1.structure%ROWTYPE; -- BAD SCHEMA!! here should be user template schema
	-- construction_site_type_structure_id int;
BEGIN

-- check existence of the schema
	if NOT (SELECT * FROM general.schemaexists(sch)) THEN return FALSE; END if;
	EXECUTE 'SET search_path TO ' ||  sch;


	-- having structure, type_structure and type_activity info will be handy
	SELECT * INTO s FROM structure where structureID=sid;
	SELECT * INTO ts FROM rules.type_structure WHERE type_structureID=s.type_structureID;
	select * INTO ta FROM rules.type_activity WHERE type_activityID=taid;

	-- Check whether the present structure can have activity taid (this is a negative check)
	IF (s.type_structureID NOT IN (SELECT starting_type_structureID FROM rules.type_activities_on_type_structure WHERE type_activityID=taid)) THEN
		RETURN FALSE;
	END IF;


	-- if taid activity is structure upgrade, then ....
	IF (ta.is_upgrade) THEN
	-- REPLACE the structure, using its own ids with construction site, i.e. the original structure is NOT removed just re-typed
		UPDATE structure SET type_structureID=(SELECT type_structureID FROM rules.type_structure WHERE type_structure_name='CONSTRUCTION_SITE' LIMIT 1) WHERE type_structureID=sid; -- + remove items from structure, rename, etc....
	END IF;


	-- the _activity_ table should be updated here
	UPDATE activity SET type_activityID=taid WHERE structureID=sid;
	-- note, that the activity is currently assigned to a CONSTRUCTION SITE type structure and the check at
	-- type_activities_on_type_structure was about the original structure


	return true;
END;
$$;


ALTER FUNCTION rules."CHECK_THIS_set_activity"(sch name, taid integer, sid integer) OWNER TO postgres;

--
-- Name: OBSOLETE_set_flow(name, integer[], integer); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION "OBSOLETE_set_flow"(sch name, tileids integer[], bhid integer) RETURNS boolean
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


ALTER FUNCTION rules."OBSOLETE_set_flow"(sch name, tileids integer[], bhid integer) OWNER TO postgres;

--
-- Name: aux_devel_productions_hierarchy(); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION aux_devel_productions_hierarchy() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	l Integer;
	maxapl integer;
	minapl integer;
	level_exists boolean;
	a rules.all_productions%rowtype;
BEGIN
	-- (re-)set all item production levels below zero to be able to distinguish items which were not handled yet
	UPDATE rules.type_item SET aux_production_level = -1;
	-- do the same with activities
	UPDATE rules.type_activity SET aux_production_level = NULL;

	-- start looping throuch all levels (first is l=0)
	l=-1;
	loop
		level_exists = FALSE;
		l=l+1;
		RAISE NOTICE '===================== Level % ===================',l;

		-- go through all productions, which production level was not determined yet
		FOR a IN SELECT * FROM rules.all_productions WHERE aux_production_level IS NULL LOOP

			-- if maximum level of input items is not exactly current level "l", then take next action
			-- (if there are no inputs  => the selection result is NULL, which is turned by coalsece into 0)
			-- (if there are only inputs with -1 (minapl<0) => the items production was not yet organized AND level will never match)
			SELECT COALESCE(max(aux_production_level),0),COALESCE(min(aux_production_level),0)  INTO maxapl,minapl FROM ( ( (SELECT type_itemid FROM json_object_keys(a.inputs) AS type_itemid) UNION (SELECT key AS type_itemid FROM json_each_text(a.tools) AS type_itemid WHERE value='true') ) AS inps JOIN rules.type_item USING (type_itemid) ) AS i;

RAISE NOTICE ' ------------ Level: %  :: Prodution % with level % and current (max,min) input level: (%,%) -----------',l,a.aid,a.aux_production_level,maxapl,minapl;
RAISE NOTICE 'inputs: %',a.inputs::text;
RAISE NOTICE 'outputs: %',a.outputs::text;
			continue when  l != maxapl OR minapl < 0 ;

			-- if we are here, we know we have to assign higher level to output production items and the activity itself
			UPDATE rules.type_activity SET aux_production_level=l WHERE type_activityid = a.aid;
			-- do not update if the aux_production_level is not -1 -> it means, that this item is already categorized
			UPDATE rules.type_item SET aux_production_level=l+1 WHERE aux_production_level=-1 AND type_itemid IN (SELECT type_itemid FROM json_object_keys(a.outputs) AS type_itemid);

RAISE NOTICE 'These output items are getting level %: %', l+1, (SELECT type_itemid FROM json_object_keys(a.outputs) AS type_itemid);

			-- and confirm that there were at least one activity on this level (if there were none, the loop should finish)
			level_exists = true;

		-- go to check another activity
		END LOOP;

		-- now just check whether to continue with next level
		EXIT WHEN NOT level_exists;

	END LOOP;

	-- actually to have it nice, some cosmetics is needed (in case there is NULL in aux_production_level)
	IF (SELECT 1 FROM rules.type_activity WHERE aux_production_level IS NULL) THEN
		-- first replace NULLs with -1
		UPDATE rules.type_activity SET aux_production_level=-1 WHERE aux_production_level IS NULL;
		-- and second - shift all production levels one up (to match with items and GUI)
		UPDATE rules.type_activity SET aux_production_level=aux_production_level+1;
	END IF;

	-- this is just for information whether there are any items left which cannot be produced (and how many)
	RETURN (SELECT count(aux_production_level) AS type_items_to_resolve FROM rules.type_item WHERE aux_production_level = -1);



END;
$$;


ALTER FUNCTION rules.aux_devel_productions_hierarchy() OWNER TO postgres;

--
-- Name: construct_structures_lvl0(name, integer, integer[]); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION construct_structures_lvl0(sch name, tsid integer, tileids integer[]) RETURNS boolean
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


ALTER FUNCTION rules.construct_structures_lvl0(sch name, tsid integer, tileids integer[]) OWNER TO postgres;

--
-- Name: create_random_map(name, integer, integer, integer, integer); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION create_random_map(sch name, xright integer, xleft integer, yright integer, yleft integer) RETURNS integer
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


ALTER FUNCTION rules.create_random_map(sch name, xright integer, xleft integer, yright integer, yleft integer) OWNER TO postgres;

--
-- Name: create_the_map_perlway(name, integer, integer, integer, integer); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION create_the_map_perlway(name, integer, integer, integer, integer) RETURNS integer
    LANGUAGE plperl
    AS $_$
#!/usr/bin/perl -w
BEGIN { strict->import(); }


my $values="";
my ($sch, $xm,$xp, $ym, $yp)=@_;

for (my $x = -$xm; $x <= $xp; $x++) {
	for (my $y = -$ym; $y <= $yp; $y++) {


		my $random_number = rand(20);
		my $type = "";
		if ($random_number < 1) {$type = "'RCK'";}
		elsif ($random_number < 2) {$type = "'RCK'";}
		elsif ($random_number < 4) {$type = "'RCK'";}
		elsif ($random_number < 5) {$type = "'RCK'";}
		elsif ($random_number < 6) {$type = "'RCK'";}
		else {$type = "'PLA'";};

		my $add = "( $x,$y,$type)";

		if ($values eq "") {
			$values = $add;
		} else {
			$values = $values.", ".$add;
		};


	};
};

my $query = qq(INSERT INTO $sch.tile(x,y, type_tileID) VALUES ).$values;

elog(INFO,$query);

my $rv = spi_exec_query($query);

return undef;

END
$_$;


ALTER FUNCTION rules.create_the_map_perlway(name, integer, integer, integer, integer) OWNER TO postgres;

--
-- Name: distance(name, integer, integer); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION distance(sch name, aid integer, bid integer) RETURNS integer
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


ALTER FUNCTION rules.distance(sch name, aid integer, bid integer) OWNER TO postgres;

--
-- Name: identify_type_flow(integer, integer); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION identify_type_flow(type_beg integer, type_end integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	eligible_flows INTEGER;
	eligible_subflows INTEGER;
BEGIN

	CREATE TEMPORARY TABLE t ON COMMIT DROP AS (
		SELECT type_flowid FROM (
		(SELECT type_flowid FROM (SELECT * FROM rules.type_flows_allowed_on_type_structures WHERE is_starting_here) AS beg1 join (SELECT * FROM rules.type_structure WHERE type_structureid = type_beg) AS beg2 using (type_structure_classid) ) AS b
		JOIN
		(SELECT type_flowid FROM (SELECT * FROM rules.type_flows_allowed_on_type_structures WHERE NOT is_starting_here) AS end1 join (SELECT * FROM rules.type_structure WHERE type_structureid = type_end) AS end2 using (type_structure_classid) ) AS e
		USING (type_flowid)
	));

	GET DIAGNOSTICS eligible_flows = ROW_COUNT;

	RAISE NOTICE 'Number of eligible flows is (%), FOUND variable is (%)',eligible_flows,FOUND;

	IF (eligible_flows = 0) THEN
		RAISE WARNING 'No such flow can be created';
		RETURN NULL;
	END IF;

	IF (eligible_flows = 1) THEN
		-- it's time to check whether subclasses match
		PERFORM type_flow_subclassid  FROM rules.type_structure WHERE type_structureid=type_beg OR type_structureid=type_end GROUP BY type_flow_subclassid;
		GET DIAGNOSTICS eligible_subflows = ROW_COUNT;

		IF (eligible_subflows = 1) THEN
			RETURN (SELECT type_flowid FROM t);
		else
			RAISE WARNING 'Incorrect subflows, these structures do not match together!';
			RETURN NULL;
		END IF;
	ELSE
		RAISE WARNING 'Too many flows (%) can be created, this function is not returning valid results anymore!',eligible_flows;
		return NULL;
	END if;

END;
$$;


ALTER FUNCTION rules.identify_type_flow(type_beg integer, type_end integer) OWNER TO postgres;

--
-- Name: is_correct_type_flow(integer, integer, text); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION is_correct_type_flow(type_beg integer, type_end integer, tfid text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	tb 	rules.type_structure%ROWTYPE;
	te 	rules.type_structure%ROWTYPE;
BEGIN

	-- good to know type structure class
	SELECT * INTO tb FROM rules.type_structure WHERE type_structureID=type_beg;
	SELECT * INTO te FROM rules.type_structure WHERE type_structureID=type_end;

	-- is there any line, that satisfy the condition?
	RETURN (SELECT count(*)>0 FROM rules.type_flows_allowed_on_type_structures_list
		WHERE type_flowid=tfid AND sb=tb.type_structure_classid AND se=te.type_structure_classid);

END;
$$;


ALTER FUNCTION rules.is_correct_type_flow(type_beg integer, type_end integer, tfid text) OWNER TO postgres;

--
-- Name: prevent_duplicate_insert_of_the_same_tool(); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION prevent_duplicate_insert_of_the_same_tool() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
		itia 	rules.type_item_as_tool_in_activity%ROWTYPE;
BEGIN
	-- Is there such record already?
	SELECT * INTO itia FROM rules.type_item_as_tool_in_activity WHERE type_activityid=NEW.type_activityid and type_itemid=NEW.type_itemid;

	-- If there is item for activity, do not insert new, just update existing
	IF (itia IS NOT NULL) THEN
		UPDATE rules.type_item_as_tool_in_activity SET is_mandatory=NEW.is_mandatory WHERE type_activityid=NEW.type_activityid and type_itemid=NEW.type_itemid;
		RETURN NULL;
	END IF;

	RETURN NEW;

END;
$$;


ALTER FUNCTION rules.prevent_duplicate_insert_of_the_same_tool() OWNER TO postgres;

--
-- Name: remove_zero_items_in_activity(); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION remove_zero_items_in_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
	-- If the number of items for given activity is zero, then the line is useless
	IF (NEW.item_count<1) THEN
		DELETE FROM rules.type_item_in_activity WHERE type_itemid=NEW.type_itemid AND type_activityid=NEW.type_activityid;
		RETURN NULL;
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION rules.remove_zero_items_in_activity() OWNER TO postgres;

--
-- Name: settle_bh(name, integer, integer); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION settle_bh(sch name, bhid integer, sid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE

	ts rules.type_structure%ROWTYPE;
	s u_simple1.structure%ROWTYPE; -- BAD SCHEMA!! here should be user template schema
	-- construction_site_type_structure_id int;
BEGIN

-- check existence of the schema
	if NOT (SELECT * FROM general.schemaexists(sch)) THEN return FALSE; END if;
	EXECUTE 'SET search_path TO ' ||  sch;

	-- having structure, type_structure and type_activity info can be handy
	--SELECT * INTO s FROM structure where structureID=sid;
	--SELECT * INTO ts FROM rules.type_structure WHERE type_structureID=s.type_structureID;


	-- check whether the structure is house (in later versions)

	-- settle bh down (and make sure that he is not a settler anymore)
	update bh set structureID=sid, tileID=NULL where bh_id=bhid;


	return true;
END;
$$;


ALTER FUNCTION rules.settle_bh(sch name, bhid integer, sid integer) OWNER TO postgres;

--
-- Name: update_if_exists_items_in_activity(); Type: FUNCTION; Schema: rules; Owner: postgres
--

CREATE FUNCTION update_if_exists_items_in_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	iia 	rules.type_item_in_activity%ROWTYPE;
BEGIN
	-- Is there such record already?
	SELECT * INTO iia FROM rules.type_item_in_activity WHERE type_activityid=NEW.type_activityid AND type_itemid=NEW.type_itemid AND is_item_input=NEW.is_item_input;

	-- If there is item for activity, do not insert new, just update existing
	IF (iia IS NOT NULL) THEN
		UPDATE rules.type_item_in_activity SET item_count=item_count+NEW.item_count WHERE type_activityid=NEW.type_activityid AND type_itemid=NEW.type_itemid;
		RETURN NULL;
	END IF;

	RETURN NEW;

END;
$$;


ALTER FUNCTION rules.update_if_exists_items_in_activity() OWNER TO postgres;

--
-- Name: type_activityid_seq; Type: SEQUENCE; Schema: rules; Owner: postgres
--

CREATE SEQUENCE type_activityid_seq
    START WITH 10001
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483648
    CACHE 1;


ALTER TABLE type_activityid_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: type_activity; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_activity (
    type_activityid integer DEFAULT nextval('type_activityid_seq'::regclass) NOT NULL,
    type_structureid integer NOT NULL,
    stamina integer DEFAULT 0 NOT NULL,
    type_activity_name text,
    min_struct_level smallint DEFAULT 1 NOT NULL,
    aux_production_level smallint
);


ALTER TABLE type_activity OWNER TO postgres;

--
-- Name: type_item_as_tool_in_activity; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_item_as_tool_in_activity (
    type_activityid integer NOT NULL,
    type_itemid text NOT NULL,
    is_mandatory boolean,
    multiplicator_presence real DEFAULT 1 NOT NULL,
    multiplicator_level real DEFAULT 1 NOT NULL,
    durability integer DEFAULT 0 NOT NULL
);


ALTER TABLE type_item_as_tool_in_activity OWNER TO postgres;

--
-- Name: COLUMN type_item_as_tool_in_activity.durability; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_item_as_tool_in_activity.durability IS 'This coefficient is multiplied by stamina used during the activity and then substracted from the remaining life for each particular item.';


--
-- Name: type_item_in_activity; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_item_in_activity (
    type_activityid integer NOT NULL,
    type_itemid text NOT NULL,
    is_item_input boolean NOT NULL,
    item_count integer DEFAULT 1 NOT NULL
);


ALTER TABLE type_item_in_activity OWNER TO postgres;

--
-- Name: TABLE type_item_in_activity; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON TABLE type_item_in_activity IS 'This table contains both inputs and outputs of an activity.';


--
-- Name: COLUMN type_item_in_activity.is_item_input; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_item_in_activity.is_item_input IS 'If false, it is output';


--
-- Name: type_structure; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_structure (
    type_structureid integer NOT NULL,
    area_min integer,
    area_max integer,
    xplusy_min integer,
    xplusy_max integer,
    type_structure_name text NOT NULL,
    type_structure_classid text,
    item_space integer DEFAULT 0,
    type_flow_subclassid text
);


ALTER TABLE type_structure OWNER TO postgres;

--
-- Name: COLUMN type_structure.area_min; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_structure.area_min IS 'minimal area this structure type is covering';


--
-- Name: COLUMN type_structure.area_max; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_structure.area_max IS 'maximal area this structure type is covering';


--
-- Name: COLUMN type_structure.xplusy_min; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_structure.xplusy_min IS 'minimal radii/2 (x+y) of this structure type';


--
-- Name: COLUMN type_structure.xplusy_max; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_structure.xplusy_max IS 'maximal radii/2 (x+y) of this structure type';


--
-- Name: COLUMN type_structure.type_structure_classid; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_structure.type_structure_classid IS 'This is a poor man solution in this simple data model, how to distuinguish among variety of structure classes. Real solution will probably contain separate tables and inheritance of some kind....';


--
-- Name: COLUMN type_structure.item_space; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_structure.item_space IS 'How much space can items take in this type of structure';


--
-- Name: all_productions; Type: VIEW; Schema: rules; Owner: postgres
--

CREATE VIEW all_productions AS
 SELECT fullselect.type_activityid AS aid,
    fullselect.type_activity_name AS activity,
    fullselect.type_structure_name AS structure,
    fullselect.stamina,
    fullselect.inputs,
    fullselect.outputs,
    fullselect.tools,
    fullselect.min_struct_level,
    fullselect.aux_production_level
   FROM ( SELECT type_activity.type_activityid,
            type_activity.type_structureid,
            type_activity.stamina,
            type_activity.min_struct_level,
            type_activity.type_activity_name,
            type_activity.aux_production_level,
            type_structure.area_min,
            type_structure.area_max,
            type_structure.xplusy_min,
            type_structure.xplusy_max,
            type_structure.type_structure_name,
            type_structure.type_structure_classid,
            type_structure.item_space,
            type_structure.type_flow_subclassid,
            inputs.inputs,
            outputs.outputs,
            tools.tools
           FROM ((((type_activity
             JOIN type_structure USING (type_structureid))
             LEFT JOIN ( SELECT json_object_agg(type_item_in_activity.type_itemid, type_item_in_activity.item_count) AS inputs,
                    type_item_in_activity.type_activityid
                   FROM type_item_in_activity
                  WHERE type_item_in_activity.is_item_input
                  GROUP BY type_item_in_activity.type_activityid) inputs USING (type_activityid))
             LEFT JOIN ( SELECT json_object_agg(type_item_in_activity.type_itemid, type_item_in_activity.item_count) AS outputs,
                    type_item_in_activity.type_activityid
                   FROM type_item_in_activity
                  WHERE (NOT type_item_in_activity.is_item_input)
                  GROUP BY type_item_in_activity.type_activityid) outputs USING (type_activityid))
             LEFT JOIN ( SELECT json_object_agg(type_item_as_tool_in_activity.type_itemid, type_item_as_tool_in_activity.is_mandatory) AS tools,
                    type_item_as_tool_in_activity.type_activityid
                   FROM type_item_as_tool_in_activity
                  GROUP BY type_item_as_tool_in_activity.type_activityid) tools USING (type_activityid))) fullselect;


ALTER TABLE all_productions OWNER TO postgres;

--
-- Name: VIEW all_productions; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON VIEW all_productions IS 'From postgresql 9.5 - recommended to use jsonB instead of json';


--
-- Name: type_construction; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_construction (
    type_constructionid integer NOT NULL,
    type_structureid integer,
    level integer DEFAULT 1 NOT NULL,
    stamina real,
    steps integer DEFAULT 1 NOT NULL
);


ALTER TABLE type_construction OWNER TO postgres;

--
-- Name: type_flow; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_flow (
    type_flowid text NOT NULL,
    type_flow_name text
);


ALTER TABLE type_flow OWNER TO postgres;

--
-- Name: type_flows_allowed_on_type_structures; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_flows_allowed_on_type_structures (
    is_starting_here boolean NOT NULL,
    type_structure_classid text NOT NULL,
    type_flowid text NOT NULL
);


ALTER TABLE type_flows_allowed_on_type_structures OWNER TO postgres;

--
-- Name: COLUMN type_flows_allowed_on_type_structures.is_starting_here; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON COLUMN type_flows_allowed_on_type_structures.is_starting_here IS 'If true, then the flow can start here, if false, the flow can end here';


--
-- Name: type_flows_allowed_on_type_structures_list; Type: VIEW; Schema: rules; Owner: postgres
--

CREATE VIEW type_flows_allowed_on_type_structures_list AS
 SELECT b.type_flowid,
    b.sb,
    e.se
   FROM (( SELECT type_flows_allowed_on_type_structures.type_structure_classid AS sb,
            type_flows_allowed_on_type_structures.type_flowid
           FROM type_flows_allowed_on_type_structures
          WHERE type_flows_allowed_on_type_structures.is_starting_here) b
     LEFT JOIN ( SELECT type_flows_allowed_on_type_structures.type_structure_classid AS se,
            type_flows_allowed_on_type_structures.type_flowid
           FROM type_flows_allowed_on_type_structures
          WHERE (NOT type_flows_allowed_on_type_structures.is_starting_here)) e USING (type_flowid));


ALTER TABLE type_flows_allowed_on_type_structures_list OWNER TO postgres;

--
-- Name: type_flow_ambigious; Type: VIEW; Schema: rules; Owner: postgres
--

CREATE VIEW type_flow_ambigious AS
 SELECT (NOT (count(type_flows_allowed_on_type_structures_list.sb) = 0)) AS duplicate
   FROM type_flows_allowed_on_type_structures_list
  GROUP BY type_flows_allowed_on_type_structures_list.sb, type_flows_allowed_on_type_structures_list.se
 HAVING (count(type_flows_allowed_on_type_structures_list.sb) > 1)
 LIMIT 1;


ALTER TABLE type_flow_ambigious OWNER TO postgres;

--
-- Name: VIEW type_flow_ambigious; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON VIEW type_flow_ambigious IS 'This view, should ALWAYS return NULL.
If not, the allowed flows on structures table has been altered and some function (such as identify_type_flow) will not work correctly anymore, as they rely on the principle that every flow type is identifiable simply by start and end. (This is btw not requirement, it is just a coincidence, given into the game by hand.)';


--
-- Name: type_flow_subclass; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_flow_subclass (
    type_flow_subclassid text NOT NULL,
    type_flowid text NOT NULL,
    description text
);


ALTER TABLE type_flow_subclass OWNER TO postgres;

--
-- Name: type_item; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_item (
    name text,
    type_itemid text NOT NULL,
    aux_production_level smallint DEFAULT '-1'::integer
);


ALTER TABLE type_item OWNER TO postgres;

--
-- Name: type_item_in_construction; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_item_in_construction (
    type_constructionid integer NOT NULL,
    type_itemid text NOT NULL,
    item_count integer DEFAULT 1 NOT NULL
);


ALTER TABLE type_item_in_construction OWNER TO postgres;

--
-- Name: type_structure_class; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_structure_class (
    type_structure_classid text NOT NULL,
    full_name text
);


ALTER TABLE type_structure_class OWNER TO postgres;

--
-- Name: TABLE type_structure_class; Type: COMMENT; Schema: rules; Owner: postgres
--

COMMENT ON TABLE type_structure_class IS 'Enum table for structure classes existing in the ecomodel. Then each real structure type must be of one of these classes';


--
-- Name: type_structures_allowed_on_type_tiles; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_structures_allowed_on_type_tiles (
    type_structureid integer NOT NULL,
    type_tileid integer NOT NULL
);


ALTER TABLE type_structures_allowed_on_type_tiles OWNER TO postgres;

--
-- Name: type_tile; Type: TABLE; Schema: rules; Owner: postgres
--

CREATE TABLE type_tile (
    type_tileid integer NOT NULL,
    name text
);


ALTER TABLE type_tile OWNER TO postgres;

--
-- Data for Name: type_activity; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_activity (type_activityid, type_structureid, stamina, type_activity_name, min_struct_level, aux_production_level) FROM stdin;
10004	20000072	0	new production name	1	0
6202	20000062	250	sugar production	1	0
6201	20000062	155	wheat production	1	0
4201	20000042	122	flour from wheet	1	1
4301	20000043	201	bread from flour	1	2
\.


--
-- Name: type_activityid_seq; Type: SEQUENCE SET; Schema: rules; Owner: postgres
--

SELECT pg_catalog.setval('type_activityid_seq', 10004, true);


--
-- Data for Name: type_construction; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_construction (type_constructionid, type_structureid, level, stamina, steps) FROM stdin;
\.


--
-- Data for Name: type_flow; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_flow (type_flowid, type_flow_name) FROM stdin;
IF	Item Flow
MS	Market Supply
FA	Field Assignment
HS	House Supply
WFA	Workforce Assignment
\.


--
-- Data for Name: type_flow_subclass; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_flow_subclass (type_flow_subclassid, type_flowid, description) FROM stdin;
AGR	FA	Agriculture
CONSTR	FA	Structure construction
MINING	FA	Mining operations
\.


--
-- Data for Name: type_flows_allowed_on_type_structures; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_flows_allowed_on_type_structures (is_starting_here, type_structure_classid, type_flowid) FROM stdin;
t	PS-CAMP	IF
t	PS-WS	IF
f	PS-CAMP	IF
f	PS-WS	IF
t	WH	IF
f	WH	IF
t	PS-CAMP	MS
t	PS-WS	MS
t	WH	MS
f	MARKET	MS
t	PS-CAMP	FA
f	WF	FA
t	MARKET	HS
t	WH	HS
f	HOUSE	HS
t	HOUSE	WFA
f	PS-CAMP	WFA
f	PS-WS	WFA
f	WH	WFA
f	MARKET	WFA
\.


--
-- Data for Name: type_item; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_item (name, type_itemid, aux_production_level) FROM stdin;
scythe	SCYTHE	-1
kosak	KOSAK	-1
sugar	SUGAR	1
wheat	WHEAT	1
flour	FLOUR	2
bread	BREAD	3
butter	BUTTER	-1
\.


--
-- Data for Name: type_item_as_tool_in_activity; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_item_as_tool_in_activity (type_activityid, type_itemid, is_mandatory, multiplicator_presence, multiplicator_level, durability) FROM stdin;
6201	KOSAK	f	1	1	0
6202	KOSAK	f	1	1	0
6202	SCYTHE	f	1	1	0
\.


--
-- Data for Name: type_item_in_activity; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_item_in_activity (type_activityid, type_itemid, is_item_input, item_count) FROM stdin;
4301	BREAD	f	1
6202	SUGAR	f	1
4301	SUGAR	t	1
4301	FLOUR	t	1
4201	FLOUR	f	1
6201	WHEAT	f	1
4201	WHEAT	t	2
\.


--
-- Data for Name: type_item_in_construction; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_item_in_construction (type_constructionid, type_itemid, item_count) FROM stdin;
\.


--
-- Data for Name: type_structure; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_structure (type_structureid, area_min, area_max, xplusy_min, xplusy_max, type_structure_name, type_structure_classid, item_space, type_flow_subclassid) FROM stdin;
20000041	\N	\N	\N	\N	lumberjack	PS-WS	0	\N
20000042	\N	\N	\N	\N	mill	PS-WS	0	\N
20000030	\N	\N	\N	\N	warehouse	WH	0	\N
20000020	\N	\N	\N	\N	market	MARKET	0	\N
20000010	\N	\N	\N	\N	house	HOUSE	0	\N
20000071	\N	\N	\N	\N	construction camp	PS-CAMP	0	CONSTR
20000072	\N	\N	\N	\N	farm	PS-CAMP	0	AGR
20000061	\N	\N	\N	\N	construction site	WF	0	CONSTR
20000043	\N	\N	\N	\N	bakery	PS-WS	3	\N
20000062	\N	\N	\N	\N	field	WF	0	AGR
\.


--
-- Data for Name: type_structure_class; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_structure_class (type_structure_classid, full_name) FROM stdin;
HOUSE	House
MARKET	Market
PS-CAMP	Production Structure - Camp
PS-WS	Production Structure - Workshop
WF	Working Field
WH	Warehouse/Storage
\.


--
-- Data for Name: type_structures_allowed_on_type_tiles; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_structures_allowed_on_type_tiles (type_structureid, type_tileid) FROM stdin;
\.


--
-- Data for Name: type_tile; Type: TABLE DATA; Schema: rules; Owner: postgres
--

COPY type_tile (type_tileid, name) FROM stdin;
\.


--
-- Name: type_activity type_activity2_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_activity
    ADD CONSTRAINT type_activity2_pkey PRIMARY KEY (type_activityid);


--
-- Name: type_construction type_construction_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_construction
    ADD CONSTRAINT type_construction_pkey PRIMARY KEY (type_constructionid);


--
-- Name: type_construction type_construction_type_structureid_level_key; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_construction
    ADD CONSTRAINT type_construction_type_structureid_level_key UNIQUE (type_structureid, level);


--
-- Name: type_flow type_flow_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_flow
    ADD CONSTRAINT type_flow_pkey PRIMARY KEY (type_flowid);


--
-- Name: type_flow_subclass type_flow_subclass_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_flow_subclass
    ADD CONSTRAINT type_flow_subclass_pkey PRIMARY KEY (type_flow_subclassid);


--
-- Name: type_flows_allowed_on_type_structures type_flows_allowed_on_type_structures_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_flows_allowed_on_type_structures
    ADD CONSTRAINT type_flows_allowed_on_type_structures_pkey PRIMARY KEY (is_starting_here, type_structure_classid, type_flowid);


--
-- Name: type_item_as_tool_in_activity type_item_as_tool_in_activity_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_as_tool_in_activity
    ADD CONSTRAINT type_item_as_tool_in_activity_pkey PRIMARY KEY (type_activityid, type_itemid);


--
-- Name: type_item_in_activity type_item_in_activity_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_in_activity
    ADD CONSTRAINT type_item_in_activity_pkey PRIMARY KEY (type_activityid, type_itemid);


--
-- Name: type_item_in_construction type_item_in_construction_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_in_construction
    ADD CONSTRAINT type_item_in_construction_pkey PRIMARY KEY (type_constructionid, type_itemid);


--
-- Name: type_item type_item_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item
    ADD CONSTRAINT type_item_pkey PRIMARY KEY (type_itemid);


--
-- Name: type_structure_class type_structure_class_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_structure_class
    ADD CONSTRAINT type_structure_class_pkey PRIMARY KEY (type_structure_classid);


--
-- Name: type_structure type_structure_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_structure
    ADD CONSTRAINT type_structure_pkey PRIMARY KEY (type_structureid);


--
-- Name: type_structures_allowed_on_type_tiles type_structures_allowed_on_type_tiles_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_structures_allowed_on_type_tiles
    ADD CONSTRAINT type_structures_allowed_on_type_tiles_pkey PRIMARY KEY (type_structureid, type_tileid);


--
-- Name: type_tile type_tile_pkey; Type: CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_tile
    ADD CONSTRAINT type_tile_pkey PRIMARY KEY (type_tileid);


--
-- Name: type_item_as_tool_in_activity prevent_duplicate_insert_of_the_same_tool; Type: TRIGGER; Schema: rules; Owner: postgres
--

CREATE TRIGGER prevent_duplicate_insert_of_the_same_tool BEFORE INSERT ON type_item_as_tool_in_activity FOR EACH ROW EXECUTE PROCEDURE prevent_duplicate_insert_of_the_same_tool();


--
-- Name: type_item_in_activity remove_zero_items_in_activity; Type: TRIGGER; Schema: rules; Owner: postgres
--

CREATE TRIGGER remove_zero_items_in_activity BEFORE UPDATE ON type_item_in_activity FOR EACH ROW EXECUTE PROCEDURE remove_zero_items_in_activity();


--
-- Name: type_item_in_activity update_if_exists_items_in_activity; Type: TRIGGER; Schema: rules; Owner: postgres
--

CREATE TRIGGER update_if_exists_items_in_activity BEFORE INSERT ON type_item_in_activity FOR EACH ROW EXECUTE PROCEDURE update_if_exists_items_in_activity();


--
-- Name: type_activity type_activity2_type_structureid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_activity
    ADD CONSTRAINT type_activity2_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES type_structure(type_structureid);


--
-- Name: type_construction type_construction_type_structureid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_construction
    ADD CONSTRAINT type_construction_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES type_structure(type_structureid);


--
-- Name: type_flow_subclass type_flow_subclass_type_flowid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_flow_subclass
    ADD CONSTRAINT type_flow_subclass_type_flowid_fkey FOREIGN KEY (type_flowid) REFERENCES type_flow(type_flowid);


--
-- Name: type_flows_allowed_on_type_structures type_flows_allowed_on_type_structures_classid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_flows_allowed_on_type_structures
    ADD CONSTRAINT type_flows_allowed_on_type_structures_classid_fkey FOREIGN KEY (type_structure_classid) REFERENCES type_structure_class(type_structure_classid);


--
-- Name: type_flows_allowed_on_type_structures type_flows_allowed_on_type_structures_type_flowid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_flows_allowed_on_type_structures
    ADD CONSTRAINT type_flows_allowed_on_type_structures_type_flowid_fkey FOREIGN KEY (type_flowid) REFERENCES type_flow(type_flowid);


--
-- Name: type_item_as_tool_in_activity type_item_as_tool_in_activity_type_activityid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_as_tool_in_activity
    ADD CONSTRAINT type_item_as_tool_in_activity_type_activityid_fkey FOREIGN KEY (type_activityid) REFERENCES type_activity(type_activityid);


--
-- Name: type_item_as_tool_in_activity type_item_as_tool_in_activity_type_item_id_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_as_tool_in_activity
    ADD CONSTRAINT type_item_as_tool_in_activity_type_item_id_fkey FOREIGN KEY (type_itemid) REFERENCES type_item(type_itemid);


--
-- Name: type_item_in_activity type_item_in_activity_type_activityid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_in_activity
    ADD CONSTRAINT type_item_in_activity_type_activityid_fkey FOREIGN KEY (type_activityid) REFERENCES type_activity(type_activityid);


--
-- Name: type_item_in_activity type_item_in_activity_type_itemid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_in_activity
    ADD CONSTRAINT type_item_in_activity_type_itemid_fkey FOREIGN KEY (type_itemid) REFERENCES type_item(type_itemid);


--
-- Name: type_item_in_construction type_item_in_construction_type_constructionid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_in_construction
    ADD CONSTRAINT type_item_in_construction_type_constructionid_fkey FOREIGN KEY (type_constructionid) REFERENCES type_construction(type_constructionid);


--
-- Name: type_item_in_construction type_item_in_construction_type_itemid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_item_in_construction
    ADD CONSTRAINT type_item_in_construction_type_itemid_fkey FOREIGN KEY (type_itemid) REFERENCES type_item(type_itemid);


--
-- Name: type_structure type_structure_type_flow_subclassid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_structure
    ADD CONSTRAINT type_structure_type_flow_subclassid_fkey FOREIGN KEY (type_flow_subclassid) REFERENCES type_flow_subclass(type_flow_subclassid);


--
-- Name: type_structure type_structure_type_structure_classid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_structure
    ADD CONSTRAINT type_structure_type_structure_classid_fkey FOREIGN KEY (type_structure_classid) REFERENCES type_structure_class(type_structure_classid);


--
-- Name: type_structures_allowed_on_type_tiles type_structures_allowed_on_type_tiles_type_structureid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_structures_allowed_on_type_tiles
    ADD CONSTRAINT type_structures_allowed_on_type_tiles_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES type_structure(type_structureid);


--
-- Name: type_structures_allowed_on_type_tiles type_structures_allowed_on_type_tiles_type_tile_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: postgres
--

ALTER TABLE ONLY type_structures_allowed_on_type_tiles
    ADD CONSTRAINT type_structures_allowed_on_type_tiles_type_tile_fkey FOREIGN KEY (type_tileid) REFERENCES type_tile(type_tileid);


--
-- PostgreSQL database dump complete
--

