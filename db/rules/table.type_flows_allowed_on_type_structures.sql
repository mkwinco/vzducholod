-- Name: type_flows_allowed_on_type_structures; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_flows_allowed_on_type_structures (
    is_starting_here boolean NOT NULL,
    type_structure_classid text NOT NULL,
    type_flowid text NOT NULL
);


--
-- Name: COLUMN type_flows_allowed_on_type_structures.is_starting_here; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON COLUMN rules.type_flows_allowed_on_type_structures.is_starting_here IS 'If true, then the flow can start here, if false, the flow can end here';


--
-- Name: type_flows_allowed_on_type_structures type_flows_allowed_on_type_structures_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_flows_allowed_on_type_structures
    ADD CONSTRAINT type_flows_allowed_on_type_structures_pkey PRIMARY KEY (is_starting_here, type_structure_classid, type_flowid);


--
-- Name: type_flows_allowed_on_type_structures type_flows_allowed_on_type_structures_classid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_flows_allowed_on_type_structures
    ADD CONSTRAINT type_flows_allowed_on_type_structures_classid_fkey FOREIGN KEY (type_structure_classid) REFERENCES rules.type_structure_class(type_structure_classid);


--
-- Name: type_flows_allowed_on_type_structures type_flows_allowed_on_type_structures_type_flowid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_flows_allowed_on_type_structures
    ADD CONSTRAINT type_flows_allowed_on_type_structures_type_flowid_fkey FOREIGN KEY (type_flowid) REFERENCES rules.type_flow(type_flowid);


--
