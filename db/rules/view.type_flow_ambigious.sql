-- Name: type_flow_ambigious; Type: VIEW; Schema: rules; Owner: -
--

CREATE VIEW rules.type_flow_ambigious AS
 SELECT (NOT (count(type_flows_allowed_on_type_structures_list.sb) = 0)) AS duplicate
   FROM rules.type_flows_allowed_on_type_structures_list
  GROUP BY type_flows_allowed_on_type_structures_list.sb, type_flows_allowed_on_type_structures_list.se
 HAVING (count(type_flows_allowed_on_type_structures_list.sb) > 1)
 LIMIT 1;


--
-- Name: VIEW type_flow_ambigious; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON VIEW rules.type_flow_ambigious IS 'This view, should ALWAYS return NULL.
If not, the allowed flows on structures table has been altered and some function (such as identify_type_flow) will not work correctly anymore, as they rely on the principle that every flow type is identifiable simply by start and end. (This is btw not requirement, it is just a coincidence, given into the game by hand.)';


--
