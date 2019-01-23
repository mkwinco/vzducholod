-- Name: flow; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.flow (
    flowid integer NOT NULL,
    start_structureid integer,
    end_structureid integer,
    length real,
    type_flowid text NOT NULL
);


--
-- Name: flow flow_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flow
    ADD CONSTRAINT flow_pkey PRIMARY KEY (flowid);


--
-- Name: flow flow_end_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flow
    ADD CONSTRAINT flow_end_structureid_fkey FOREIGN KEY (end_structureid) REFERENCES u_simple1.structure(structureid);


--
-- Name: flow flow_start_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flow
    ADD CONSTRAINT flow_start_structureid_fkey FOREIGN KEY (start_structureid) REFERENCES u_simple1.structure(structureid);


--
-- Name: flow flow_type_flowid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flow
    ADD CONSTRAINT flow_type_flowid_fkey FOREIGN KEY (type_flowid) REFERENCES rules.type_flow(type_flowid);


--
