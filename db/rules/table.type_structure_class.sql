-- Name: type_structure_class; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_structure_class (
    type_structure_classid text NOT NULL,
    full_name text
);


--
-- Name: TABLE type_structure_class; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON TABLE rules.type_structure_class IS 'Enum table for structure classes existing in the ecomodel. Then each real structure type must be of one of these classes';


--
-- Name: type_structure_class type_structure_class_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_structure_class
    ADD CONSTRAINT type_structure_class_pkey PRIMARY KEY (type_structure_classid);


--
