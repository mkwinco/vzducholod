-- Name: schemaexists(name); Type: FUNCTION; Schema: general; Owner: -
--

CREATE FUNCTION general.schemaexists(sch name) RETURNS boolean
    LANGUAGE sql
    AS $$

-- faster way 
SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = sch);

-- purist way 
-- SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = sch);

$$;


--
