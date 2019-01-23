-- Name: authenticate(text, text, text); Type: FUNCTION; Schema: general; Owner: -
--

CREATE FUNCTION general.authenticate(us text, pw text, ak text DEFAULT ''::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE

BEGIN

	RAISE NOTICE 'username: %,   password: %',us,md5(pw);
	if (md5(pw) = '10e10f9a7823877ac5637d98db0daf0a') THEN RETURN us; END IF;
	RETURN null;

END;
$$;


--
