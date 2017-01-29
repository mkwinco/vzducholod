--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: econmod_v03; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE econmod_v03 WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C';


ALTER DATABASE econmod_v03 OWNER TO postgres;

\connect econmod_v03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: u_simple1; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA u_simple1;


ALTER SCHEMA u_simple1 OWNER TO postgres;

--
-- Name: plperl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plperl;


ALTER PROCEDURAL LANGUAGE plperl OWNER TO postgres;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


SET search_path = u_simple1, pg_catalog;

--
-- Name: tileid_calculation(); Type: FUNCTION; Schema: u_simple1; Owner: postgres
--

CREATE FUNCTION tileid_calculation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
BEGIN
NEW.tileID := 1000000 * new.x + new.y;
RETURN NEW;
END;$$;


ALTER FUNCTION u_simple1.tileid_calculation() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activity; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE activity (
    structureid integer NOT NULL,
    progress real,
    progress_max real,
    type_activityid integer NOT NULL
);


ALTER TABLE activity OWNER TO postgres;

--
-- Name: bh; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE bh (
    bh_id integer NOT NULL,
    name text,
    structureid integer,
    tileid integer,
    flowid integer,
    CONSTRAINT bh_check CHECK ((((structureid IS NULL) AND (tileid IS NOT NULL)) OR ((structureid IS NOT NULL) AND (tileid IS NULL)))),
    CONSTRAINT bh_check1 CHECK ((((structureid IS NULL) AND (flowid IS NULL)) OR (structureid IS NOT NULL)))
);


ALTER TABLE bh OWNER TO postgres;

--
-- Name: TABLE bh; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON TABLE bh IS 'bonhomme - inhabitants and settlers table';


--
-- Name: COLUMN bh.structureid; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN bh.structureid IS 'this is id of the house (or NULL for settler)';


--
-- Name: COLUMN bh.tileid; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN bh.tileid IS 'this is a NON-NULL value for settlers only. Otherwise it is the current settler''s location';


--
-- Name: construction; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE construction (
    constructionid integer NOT NULL,
    structureid integer NOT NULL,
    end_type_structureid integer NOT NULL,
    stamina_total real,
    stamina_done real DEFAULT 0
);


ALTER TABLE construction OWNER TO postgres;

--
-- Name: COLUMN construction.structureid; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN construction.structureid IS 'This should be only and only a construction site (RF of CONST subclass)';


--
-- Name: COLUMN construction.stamina_total; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN construction.stamina_total IS 'Auxiliary column for progress tracking purposes: Total stamina for the whole construction. This column is filled at the initialization of construction, it should not be updated afterwards.';


--
-- Name: COLUMN construction.stamina_done; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN construction.stamina_done IS 'Auxiliary column for tracking purposes. Stamina already added into the construction - 0 at the start, updated after every turn.';


--
-- Name: constructions_definition; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE constructions_definition (
    constructionid integer NOT NULL,
    construction_phase integer NOT NULL,
    steps_remaining integer DEFAULT 1 NOT NULL,
    type_constructionid integer NOT NULL
);


ALTER TABLE constructions_definition OWNER TO postgres;

--
-- Name: TABLE constructions_definition; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON TABLE constructions_definition IS 'This table defines remaining steps to construct a structure';


--
-- Name: COLUMN constructions_definition.construction_phase; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN constructions_definition.construction_phase IS 'The lowest construction_phase is the next one to build (lower ones are already built, i.e. removed from the table). The construction_phase is always only relative number, it can be different among similar constructions and it is not necessarily referring to the level of the structure in construction.';


--
-- Name: COLUMN constructions_definition.steps_remaining; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN constructions_definition.steps_remaining IS 'Remaining steps for this given construction_level. The number should be lowered after each succesfull completition of the step. If the step number is 0, the line should be removed whatsoever - a trigger function can be considered.';


--
-- Name: COLUMN constructions_definition.type_constructionid; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN constructions_definition.type_constructionid IS 'The definition of endtype construction and its level. It also defines items and stamina required to finish step.';


--
-- Name: flow; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE flow (
    flowid integer NOT NULL,
    start_structureid integer,
    end_structureid integer,
    length real,
    type_flowid text NOT NULL
);


ALTER TABLE flow OWNER TO postgres;

--
-- Name: flows_on_tiles; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE flows_on_tiles (
    tileid integer NOT NULL,
    flowid integer NOT NULL,
    "order" smallint,
    CONSTRAINT flows_on_tiles_order_check CHECK (("order" >= 0))
);


ALTER TABLE flows_on_tiles OWNER TO postgres;

--
-- Name: structure; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE structure (
    structureid integer NOT NULL,
    type_structureid integer
);


ALTER TABLE structure OWNER TO postgres;

--
-- Name: tile; Type: TABLE; Schema: u_simple1; Owner: postgres
--

CREATE TABLE tile (
    x integer NOT NULL,
    y integer NOT NULL,
    type_tileid integer NOT NULL,
    structureid integer,
    tileid integer NOT NULL,
    movement_multiplicator real DEFAULT 0
);


ALTER TABLE tile OWNER TO postgres;

--
-- Name: COLUMN tile.movement_multiplicator; Type: COMMENT; Schema: u_simple1; Owner: postgres
--

COMMENT ON COLUMN tile.movement_multiplicator IS 'This Field is superficial, it can be extracted from type_tile and type_structure!
If mm is NULL or 0, then it is not passable.
below 1 it is slower than normal, above 1 it is faster (though exponential would be more beautiful)';


--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (structureid);


--
-- Name: bh bh_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY bh
    ADD CONSTRAINT bh_pkey PRIMARY KEY (bh_id);


--
-- Name: construction construction_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY construction
    ADD CONSTRAINT construction_pkey PRIMARY KEY (constructionid);


--
-- Name: constructions_definition constructions_definition_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY constructions_definition
    ADD CONSTRAINT constructions_definition_pkey PRIMARY KEY (constructionid, construction_phase);


--
-- Name: flow flow_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flow
    ADD CONSTRAINT flow_pkey PRIMARY KEY (flowid);


--
-- Name: flows_on_tiles flows_on_tiles_flowid_order_key; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_flowid_order_key UNIQUE (flowid, "order");


--
-- Name: flows_on_tiles flows_on_tiles_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_pkey PRIMARY KEY (tileid, flowid);


--
-- Name: structure structure_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY structure
    ADD CONSTRAINT structure_pkey PRIMARY KEY (structureid);


--
-- Name: tile tile_pkey; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY tile
    ADD CONSTRAINT tile_pkey PRIMARY KEY (tileid);


--
-- Name: tile tile_x_y_key; Type: CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY tile
    ADD CONSTRAINT tile_x_y_key UNIQUE (x, y);


--
-- Name: tile tileid_calculation_trigger; Type: TRIGGER; Schema: u_simple1; Owner: postgres
--

CREATE TRIGGER tileid_calculation_trigger BEFORE INSERT ON tile FOR EACH ROW EXECUTE PROCEDURE tileid_calculation();


--
-- Name: activity activity_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY activity
    ADD CONSTRAINT activity_structureid_fkey FOREIGN KEY (structureid) REFERENCES structure(structureid);


--
-- Name: activity activity_type_activityid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY activity
    ADD CONSTRAINT activity_type_activityid_fkey FOREIGN KEY (type_activityid) REFERENCES rules.type_activity(type_activityid);


--
-- Name: bh bh_flowid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY bh
    ADD CONSTRAINT bh_flowid_fkey FOREIGN KEY (flowid) REFERENCES flow(flowid);


--
-- Name: bh bh_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY bh
    ADD CONSTRAINT bh_structureid_fkey FOREIGN KEY (structureid) REFERENCES structure(structureid);


--
-- Name: bh bh_tileid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY bh
    ADD CONSTRAINT bh_tileid_fkey FOREIGN KEY (tileid) REFERENCES tile(tileid);


--
-- Name: construction construction_end_type_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY construction
    ADD CONSTRAINT construction_end_type_structureid_fkey FOREIGN KEY (end_type_structureid) REFERENCES rules.type_structure(type_structureid);


--
-- Name: construction construction_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY construction
    ADD CONSTRAINT construction_structureid_fkey FOREIGN KEY (structureid) REFERENCES structure(structureid);


--
-- Name: constructions_definition constructions_definition_type_constructionid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY constructions_definition
    ADD CONSTRAINT constructions_definition_type_constructionid_fkey FOREIGN KEY (type_constructionid) REFERENCES rules.type_construction(type_constructionid);


--
-- Name: flow flow_end_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flow
    ADD CONSTRAINT flow_end_structureid_fkey FOREIGN KEY (end_structureid) REFERENCES structure(structureid);


--
-- Name: flow flow_start_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flow
    ADD CONSTRAINT flow_start_structureid_fkey FOREIGN KEY (start_structureid) REFERENCES structure(structureid);


--
-- Name: flow flow_type_flowid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flow
    ADD CONSTRAINT flow_type_flowid_fkey FOREIGN KEY (type_flowid) REFERENCES rules.type_flow(type_flowid);


--
-- Name: flows_on_tiles flows_on_tiles_flowid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_flowid_fkey FOREIGN KEY (flowid) REFERENCES flow(flowid);


--
-- Name: flows_on_tiles flows_on_tiles_tileid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY flows_on_tiles
    ADD CONSTRAINT flows_on_tiles_tileid_fkey FOREIGN KEY (tileid) REFERENCES tile(tileid);


--
-- Name: structure structure_type_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY structure
    ADD CONSTRAINT structure_type_structureid_fkey FOREIGN KEY (type_structureid) REFERENCES rules.type_structure(type_structureid);


--
-- Name: tile tile_structureid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY tile
    ADD CONSTRAINT tile_structureid_fkey FOREIGN KEY (structureid) REFERENCES structure(structureid);


--
-- Name: tile tile_type_tileid_fkey; Type: FK CONSTRAINT; Schema: u_simple1; Owner: postgres
--

ALTER TABLE ONLY tile
    ADD CONSTRAINT tile_type_tileid_fkey FOREIGN KEY (type_tileid) REFERENCES rules.type_tile(type_tileid);


--
-- PostgreSQL database dump complete
--

