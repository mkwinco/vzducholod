-- Name: remove_zero_items_in_activity(); Type: FUNCTION; Schema: rules; Owner: -
--

CREATE FUNCTION rules.remove_zero_items_in_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
	-- If the number of items for given activity is zero, then the line is useless
	IF (NEW.item_count<1) THEN
		DELETE FROM rules.type_item_in_activity WHERE type_itemid=NEW.type_itemid AND type_activityid=NEW.type_activityid;
		RETURN NULL;
	END IF;
	
	RETURN NEW;
END;
$$;


--
