-- Name: type_flows_allowed_on_type_structures_list; Type: VIEW; Schema: rules; Owner: -
--

CREATE VIEW rules.type_flows_allowed_on_type_structures_list AS
 SELECT b.type_flowid,
    b.sb,
    e.se
   FROM (( SELECT type_flows_allowed_on_type_structures.type_structure_classid AS sb,
            type_flows_allowed_on_type_structures.type_flowid
           FROM rules.type_flows_allowed_on_type_structures
          WHERE type_flows_allowed_on_type_structures.is_starting_here) b
     LEFT JOIN ( SELECT type_flows_allowed_on_type_structures.type_structure_classid AS se,
            type_flows_allowed_on_type_structures.type_flowid
           FROM rules.type_flows_allowed_on_type_structures
          WHERE (NOT type_flows_allowed_on_type_structures.is_starting_here)) e USING (type_flowid));


--
