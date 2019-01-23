-- Name: CHECK_THIS_set_activity(name, integer, integer); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules."CHECK_THIS_set_activity"(sch name, taid integer, sid integer) RETURNS boolean
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


--
