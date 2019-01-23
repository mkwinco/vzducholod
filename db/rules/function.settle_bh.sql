-- Name: settle_bh(name, integer, integer); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.settle_bh(sch name, bhid integer, sid integer) RETURNS boolean
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


--
