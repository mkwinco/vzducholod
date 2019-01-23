-- Name: type_item_as_tool_in_activity; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_item_as_tool_in_activity (
    type_activityid integer NOT NULL,
    type_itemid text NOT NULL,
    is_mandatory boolean,
    multiplicator_presence real DEFAULT 1 NOT NULL,
    multiplicator_level real DEFAULT 1 NOT NULL,
    durability integer DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN type_item_as_tool_in_activity.durability; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_item_as_tool_in_activity.durability IS 'This coefficient is multiplied by stamina used during the activity and then substracted from the remaining life for each particular item.';


--
-- Name: type_item_as_tool_in_activity type_item_as_tool_in_activity_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_as_tool_in_activity
    ADD CONSTRAINT type_item_as_tool_in_activity_pkey PRIMARY KEY (type_activityid, type_itemid);


--
-- Name: type_item_as_tool_in_activity prevent_duplicate_insert_of_the_same_tool; Type: TRIGGER; Schema: rules; Owner: -
--

CREATE TRIGGER prevent_duplicate_insert_of_the_same_tool BEFORE INSERT ON rules.type_item_as_tool_in_activity FOR EACH ROW EXECUTE PROCEDURE rules.prevent_duplicate_insert_of_the_same_tool();


--
-- Name: type_item_as_tool_in_activity type_item_as_tool_in_activity_type_activityid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_as_tool_in_activity
    ADD CONSTRAINT type_item_as_tool_in_activity_type_activityid_fkey FOREIGN KEY (type_activityid) REFERENCES rules.type_activity(type_activityid);


--
-- Name: type_item_as_tool_in_activity type_item_as_tool_in_activity_type_item_id_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_as_tool_in_activity
    ADD CONSTRAINT type_item_as_tool_in_activity_type_item_id_fkey FOREIGN KEY (type_itemid) REFERENCES rules.type_item(type_itemid);


--
