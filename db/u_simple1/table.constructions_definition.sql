-- Name: constructions_definition; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.constructions_definition (
    constructionid integer NOT NULL,
    construction_phase integer NOT NULL,
    steps_remaining integer DEFAULT 1 NOT NULL,
    type_constructionid integer NOT NULL
);


--
-- Name: TABLE constructions_definition; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON TABLE u_simple1.constructions_definition IS 'This table defines remaining steps to construct a structure';


--
-- Name: COLUMN constructions_definition.construction_phase; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.constructions_definition.construction_phase IS 'The lowest construction_phase is the next one to build (lower ones are already built, i.e. removed from the table). The construction_phase is always only relative number, it can be different among similar constructions and it is not necessarily referring to the level of the structure in construction.';


--
-- Name: COLUMN constructions_definition.steps_remaining; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.constructions_definition.steps_remaining IS 'Remaining steps for this given construction_level. The number should be lowered after each succesfull completition of the step. If the step number is 0, the line should be removed whatsoever - a trigger function can be considered.';


--
-- Name: COLUMN constructions_definition.type_constructionid; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.constructions_definition.type_constructionid IS 'The definition of endtype construction and its level. It also defines items and stamina required to finish step.';


--
-- Name: constructions_definition constructions_definition_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.constructions_definition
    ADD CONSTRAINT constructions_definition_pkey PRIMARY KEY (constructionid, construction_phase);


--
-- Name: constructions_definition constructions_definition_type_constructionid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.constructions_definition
    ADD CONSTRAINT constructions_definition_type_constructionid_fkey FOREIGN KEY (type_constructionid) REFERENCES rules.type_construction(type_constructionid);


--
