-- Name: tile; Type: TABLE; Schema: u_simple1; Owner: -
--

CREATE TABLE u_simple1.tile (
    x integer NOT NULL,
    y integer NOT NULL,
    type_tileid integer NOT NULL,
    structureid integer,
    tileid integer NOT NULL,
    movement_multiplicator real DEFAULT 0
);


--
-- Name: COLUMN tile.movement_multiplicator; Type: COMMENT; Schema: u_simple1; Owner: -
--

COMMENT ON COLUMN u_simple1.tile.movement_multiplicator IS 'This Field is superficial, it can be extracted from type_tile and type_structure!
If mm is NULL or 0, then it is not passable.
below 1 it is slower than normal, above 1 it is faster (though exponential would be more beautiful)';


--
-- Name: tile tile_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.tile
    ADD CONSTRAINT tile_pkey PRIMARY KEY (tileid);


--
-- Name: tile tile_x_y_key; Type: CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.tile
    ADD CONSTRAINT tile_x_y_key UNIQUE (x, y);


--
-- Name: tile tileid_calculation_trigger; Type: TRIGGER; Schema: u_simple1; Owner: -
--

CREATE TRIGGER tileid_calculation_trigger BEFORE INSERT ON u_simple1.tile FOR EACH ROW EXECUTE PROCEDURE u_simple1.tileid_calculation();


--
-- Name: tile tile_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.tile
    ADD CONSTRAINT tile_structureid_fkey FOREIGN KEY (structureid) REFERENCES u_simple1.structure(structureid);


--
-- Name: tile tile_type_tileid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: -
--

ALTER TABLE ONLY u_simple1.tile
    ADD CONSTRAINT tile_type_tileid_fkey FOREIGN KEY (type_tileid) REFERENCES rules.type_tile(type_tileid);


--
-- PostgreSQL database dump complete
--

