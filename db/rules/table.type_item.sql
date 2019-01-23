-- Name: type_item; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_item (
    name text,
    type_itemid text NOT NULL,
    aux_production_level smallint DEFAULT '-1'::integer
);


--
-- Name: type_item type_item_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item
    ADD CONSTRAINT type_item_pkey PRIMARY KEY (type_itemid);


--
