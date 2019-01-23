-- Name: activity; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.activity (
    structureid integer NOT NULL,
    progress real,
    progress_max real,
    type_activityid integer NOT NULL
);


--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (structureid);


--
-- Name: activity activity_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.activity
    ADD CONSTRAINT activity_structureid_fkey FOREIGN KEY (structureid) REFERENCES u_simple1.structure(structureid);


--
-- Name: activity activity_type_activityid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.activity
    ADD CONSTRAINT activity_type_activityid_fkey FOREIGN KEY (type_activityid) REFERENCES rules.type_activity(type_activityid);


--
