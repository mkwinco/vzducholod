-- Name: prevent_duplicate_insert_of_the_same_tool(); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.prevent_duplicate_insert_of_the_same_tool() RETURNS trigger
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


--
