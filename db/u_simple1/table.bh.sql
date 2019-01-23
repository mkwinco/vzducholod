-- Name: bh; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.bh (
    bh_id integer NOT NULL,
    name text,
    structureid integer,
    tileid integer,
    flowid integer,
    CONSTRAINT bh_check CHECK ((((structureid IS NULL) AND (tileid IS NOT NULL)) OR ((structureid IS NOT NULL) AND (tileid IS NULL)))),
    CONSTRAINT bh_check1 CHECK ((((structureid IS NULL) AND (flowid IS NULL)) OR (structureid IS NOT NULL)))
);


--
-- Name: TABLE bh; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON TABLE u_simple1.bh IS 'bonhomme - inhabitants and settlers table';


--
-- Name: COLUMN bh.structureid; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.bh.structureid IS 'this is id of the house (or NULL for settler)';


--
-- Name: COLUMN bh.tileid; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.bh.tileid IS 'this is a NON-NULL value for settlers only. Otherwise it is the current settler''s location';


--
-- Name: bh bh_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.bh
    ADD CONSTRAINT bh_pkey PRIMARY KEY (bh_id);


--
-- Name: bh bh_flowid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.bh
    ADD CONSTRAINT bh_flowid_fkey FOREIGN KEY (flowid) REFERENCES u_simple1.flow(flowid);


--
-- Name: bh bh_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.bh
    ADD CONSTRAINT bh_structureid_fkey FOREIGN KEY (structureid) REFERENCES u_simple1.structure(structureid);


--
-- Name: bh bh_tileid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.bh
    ADD CONSTRAINT bh_tileid_fkey FOREIGN KEY (tileid) REFERENCES u_simple1.tile(tileid);


--
