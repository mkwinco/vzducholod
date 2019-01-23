-- Name: identify_type_flow(integer, integer); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.identify_type_flow(type_beg integer, type_end integer) RETURNS text
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


--
