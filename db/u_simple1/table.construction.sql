-- Name: construction; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.construction (
    constructionid integer NOT NULL,
    structureid integer NOT NULL,
    end_type_structureid integer NOT NULL,
    stamina_total real,
    stamina_done real DEFAULT 0
);


--
-- Name: COLUMN construction.structureid; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.construction.structureid IS 'This should be only and only a construction site (RF of CONST subclass)';


--
-- Name: COLUMN construction.stamina_total; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.construction.stamina_total IS 'Auxiliary column for progress tracking purposes: Total stamina for the whole construction. This column is filled at the initialization of construction, it should not be updated afterwards.';


--
-- Name: COLUMN construction.stamina_done; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.construction.stamina_done IS 'Auxiliary column for tracking purposes. Stamina already added into the construction - 0 at the start, updated after every turn.';


--
-- Name: construction construction_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.construction
    ADD CONSTRAINT construction_pkey PRIMARY KEY (constructionid);


--
-- Name: construction construction_end_type_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.construction
    ADD CONSTRAINT construction_end_type_structureid_fkey FOREIGN KEY (end_type_structureid) REFERENCES rules.type_structure(type_structureid);


--
-- Name: construction construction_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.construction
    ADD CONSTRAINT construction_structureid_fkey FOREIGN KEY (structureid) REFERENCES u_simple1.structure(structureid);


--
