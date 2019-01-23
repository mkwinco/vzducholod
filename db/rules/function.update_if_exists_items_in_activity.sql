-- Name: update_if_exists_items_in_activity(); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.update_if_exists_items_in_activity() RETURNS trigger
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


--
