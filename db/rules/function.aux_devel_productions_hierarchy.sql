-- Name: aux_devel_productions_hierarchy(); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.aux_devel_productions_hierarchy() RETURNS integer
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


--
