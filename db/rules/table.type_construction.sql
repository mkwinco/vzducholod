-- Name: type_construction; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_construction (
    type_constructionid integer NOT NULL,
    type_structureid integer,
    level integer DEFAULT 1 NOT NULL,
    stamina real,
    steps integer DEFAULT 1 NOT NULL
);


--
-- Name: type_construction type_construction_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_construction
    ADD CONSTRAINT type_construction_pkey PRIMARY KEY (type_constructionid);


--
-- Name: type_construction type_construction_type_structureid_level_key; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_construction
    ADD CONSTRAINT type_construction_type_structureid_level_key UNIQUE (type_structureid, level);


--
-- Name: type_construction type_construction_type_structureid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_construction
    ADD CONSTRAINT type_construction_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES rules.type_structure(type_structureid);


--
