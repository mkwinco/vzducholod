-- Name: type_structure; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_structure (
    type_structureid integer DEFAULT nextval('rules.type_structureid_seq'::regclass) NOT NULL,
    area_min integer,
    area_max integer,
    xplusy_min integer,
    xplusy_max integer,
    type_structure_name text NOT NULL,
    type_structure_classid text,
    item_space integer DEFAULT 0,
    type_flow_subclassid text
);


--
-- Name: COLUMN type_structure.area_min; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_structure.area_min IS 'minimal area this structure type is covering';


--
-- Name: COLUMN type_structure.area_max; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_structure.area_max IS 'maximal area this structure type is covering';


--
-- Name: COLUMN type_structure.xplusy_min; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_structure.xplusy_min IS 'minimal radii/2 (x+y) of this structure type';


--
-- Name: COLUMN type_structure.xplusy_max; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_structure.xplusy_max IS 'maximal radii/2 (x+y) of this structure type';


--
-- Name: COLUMN type_structure.type_structure_classid; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_structure.type_structure_classid IS 'This is a poor man solution in this simple data model, how to distuinguish among variety of structure classes. Real solution will probably contain separate tables and inheritance of some kind....';


--
-- Name: COLUMN type_structure.item_space; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_structure.item_space IS 'How much space can items take in this type of structure';


--
-- Name: type_structure type_structure_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_structure
    ADD CONSTRAINT type_structure_pkey PRIMARY KEY (type_structureid);


--
-- Name: type_structure type_structure_type_flow_subclassid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_structure
    ADD CONSTRAINT type_structure_type_flow_subclassid_fkey FOREIGN KEY (type_flow_subclassid) REFERENCES rules.type_flow_subclass(type_flow_subclassid);


--
-- Name: type_structure type_structure_type_structure_classid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_structure
    ADD CONSTRAINT type_structure_type_structure_classid_fkey FOREIGN KEY (type_structure_classid) REFERENCES rules.type_structure_class(type_structure_classid);


--
