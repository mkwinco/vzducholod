-- Name: type_item_in_activity; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_item_in_activity (
    type_activityid integer NOT NULL,
    type_itemid text NOT NULL,
    is_item_input boolean NOT NULL,
    item_count integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE type_item_in_activity; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON TABLE rules.type_item_in_activity IS 'This table contains both inputs and outputs of an activity.';


--
-- Name: COLUMN type_item_in_activity.is_item_input; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_item_in_activity.is_item_input IS 'If false, it is output';


--
-- Name: type_item_in_activity type_item_in_activity_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_in_activity
    ADD CONSTRAINT type_item_in_activity_pkey PRIMARY KEY (type_activityid, type_itemid);


--
-- Name: type_item_in_activity remove_zero_items_in_activity; Type: TRIGGER; Schema: rules; Owner: -
--

CREATE TRIGGER remove_zero_items_in_activity BEFORE UPDATE ON rules.type_item_in_activity FOR EACH ROW EXECUTE PROCEDURE rules.remove_zero_items_in_activity();


--
-- Name: type_item_in_activity update_if_exists_items_in_activity; Type: TRIGGER; Schema: rules; Owner: -
--

CREATE TRIGGER update_if_exists_items_in_activity BEFORE INSERT ON rules.type_item_in_activity FOR EACH ROW EXECUTE PROCEDURE rules.update_if_exists_items_in_activity();


--
-- Name: type_item_in_activity type_item_in_activity_type_activityid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_in_activity
    ADD CONSTRAINT type_item_in_activity_type_activityid_fkey FOREIGN KEY (type_activityid) REFERENCES rules.type_activity(type_activityid);


--
-- Name: type_item_in_activity type_item_in_activity_type_itemid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_in_activity
    ADD CONSTRAINT type_item_in_activity_type_itemid_fkey FOREIGN KEY (type_itemid) REFERENCES rules.type_item(type_itemid);


--
