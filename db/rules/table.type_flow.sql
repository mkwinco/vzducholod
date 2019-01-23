-- Name: type_flow; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_flow (
    type_flowid text NOT NULL,
    type_flow_name text
);


--
-- Name: type_flow type_flow_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_flow
    ADD CONSTRAINT type_flow_pkey PRIMARY KEY (type_flowid);


--
