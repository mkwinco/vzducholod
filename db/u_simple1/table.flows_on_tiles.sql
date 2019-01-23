-- Name: flows_on_tiles; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.flows_on_tiles (
    tileid integer NOT NULL,
    flowid integer NOT NULL,
    "order" smallint,
    CONSTRAINT flows_on_tiles_order_check CHECK (("order" >= 0))
);


--
-- Name: flows_on_tiles flows_on_tiles_flowid_order_key; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_flowid_order_key UNIQUE (flowid, "order");


--
-- Name: flows_on_tiles flows_on_tiles_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_pkey PRIMARY KEY (tileid, flowid);


--
-- Name: flows_on_tiles flows_on_tiles_flowid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_flowid_fkey FOREIGN KEY (flowid) REFERENCES u_simple1.flow(flowid);


--
-- Name: flows_on_tiles flows_on_tiles_tileid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_tileid_fkey FOREIGN KEY (tileid) REFERENCES u_simple1.tile(tileid);


--
