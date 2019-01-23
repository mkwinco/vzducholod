-- Name: type_item_in_construction; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_item_in_construction (
    type_constructionid integer NOT NULL,
    type_itemid text NOT NULL,
    item_count integer DEFAULT 1 NOT NULL
);


--
-- Name: type_item_in_construction type_item_in_construction_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_in_construction
    ADD CONSTRAINT type_item_in_construction_pkey PRIMARY KEY (type_constructionid, type_itemid);


--
-- Name: type_item_in_construction type_item_in_construction_type_constructionid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_in_construction
    ADD CONSTRAINT type_item_in_construction_type_constructionid_fkey FOREIGN KEY (type_constructionid) REFERENCES rules.type_construction(type_constructionid);


--
-- Name: type_item_in_construction type_item_in_construction_type_itemid_fkey; Type: FK CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_item_in_construction
    ADD CONSTRAINT type_item_in_construction_type_itemid_fkey FOREIGN KEY (type_itemid) REFERENCES rules.type_item(type_itemid);


--
