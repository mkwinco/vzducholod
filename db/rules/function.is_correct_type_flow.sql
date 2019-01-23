-- Name: is_correct_type_flow(integer, integer, text); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.is_correct_type_flow(type_beg integer, type_end integer, tfid text) RETURNS boolean
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


--
