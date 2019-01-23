-- Name: type_flow_subclass; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_flow_subclass (
    type_flow_subclassid text NOT NULL,
    type_flowid text NOT NULL,
    description text
);


--
-- Name: type_flow_subclass type_flow_subclass_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_flow_subclass
    ADD CONSTRAINT type_flow_subclass_pkey PRIMARY KEY (type_flow_subclassid);


--
-- Name: type_flow_subclass type_flow_subclass_type_flowid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_flow_subclass
    ADD CONSTRAINT type_flow_subclass_type_flowid_fkey FOREIGN KEY (type_flowid) REFERENCES rules.type_flow(type_flowid);


--
