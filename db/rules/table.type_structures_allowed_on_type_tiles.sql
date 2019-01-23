-- Name: type_structures_allowed_on_type_tiles; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_structures_allowed_on_type_tiles (
    type_structureid integer NOT NULL,
    type_tileid integer NOT NULL
);


--
-- Name: type_structures_allowed_on_type_tiles type_structures_allowed_on_type_tiles_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_structures_allowed_on_type_tiles
    ADD CONSTRAINT type_structures_allowed_on_type_tiles_pkey PRIMARY KEY (type_structureid, type_tileid);


--
-- Name: type_structures_allowed_on_type_tiles type_structures_allowed_on_type_tiles_type_structureid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_structures_allowed_on_type_tiles
    ADD CONSTRAINT type_structures_allowed_on_type_tiles_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES rules.type_structure(type_structureid);


--
-- Name: type_structures_allowed_on_type_tiles type_structures_allowed_on_type_tiles_type_tile_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_structures_allowed_on_type_tiles
    ADD CONSTRAINT type_structures_allowed_on_type_tiles_type_tile_fkey FOREIGN KEY (type_tileid) REFERENCES rules.type_tile(type_tileid);


--
-- PostgreSQL database dump complete
--

