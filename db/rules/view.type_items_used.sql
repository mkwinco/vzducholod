-- Name: type_items_used; Type: VIEW; Schema: rules; Owner: -
--

CREATE VIEW rules.type_items_used AS
 SELECT DISTINCT type_item_in_construction.type_itemid
   FROM rules.type_item_in_construction
UNION
 SELECT DISTINCT type_item_in_activity.type_itemid
   FROM rules.type_item_in_activity
UNION
 SELECT DISTINCT type_item_as_tool_in_activity.type_itemid
   FROM rules.type_item_as_tool_in_activity;


--
