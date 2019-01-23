-- Name: tileid_calculation(); Type: FUNCTION; Schema: u_simple1; Owner: -
--

CREATE FUNCTION u_simple1.tileid_calculation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
BEGIN
NEW.tileID := 1000000 * new.x + new.y;
RETURN NEW;
END;$$;


