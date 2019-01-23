-- Name: type_activity; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_activity (
    type_activityid integer DEFAULT nextval('rules.type_activityid_seq'::regclass) NOT NULL,
    type_structureid integer NOT NULL,
    stamina integer DEFAULT 0 NOT NULL,
    type_activity_name text,
    min_struct_level smallint DEFAULT 1 NOT NULL,
    aux_production_level smallint
);


--
-- Name: type_activity type_activity2_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_activity
    ADD CONSTRAINT type_activity2_pkey PRIMARY KEY (type_activityid);


--
-- Name: type_activity type_activity2_type_structureid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_activity
    ADD CONSTRAINT type_activity2_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES rules.type_structure(type_structureid);


--
