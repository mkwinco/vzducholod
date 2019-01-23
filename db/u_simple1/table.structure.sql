-- Name: structure; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.structure (
    structureid integer NOT NULL,
    type_structureid integer
);


--
-- Name: structure structure_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.structure
    ADD CONSTRAINT structure_pkey PRIMARY KEY (structureid);


--
-- Name: structure structure_type_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.structure
    ADD CONSTRAINT structure_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES rules.type_structure(type_structureid);


--
