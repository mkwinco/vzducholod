-- Name: endproduct_or_empty_activities; Type: VIEW; Schema: rules; Owner: -
--

CREATE VIEW rules.endproduct_or_empty_activities AS
 SELECT type_activity.type_activityid
   FROM rules.type_activity
  WHERE (NOT (type_activity.type_activityid IN ( SELECT type_item_in_activity.type_activityid
           FROM rules.type_item_in_activity
          WHERE (NOT type_item_in_activity.is_item_input))))
UNION
 SELECT DISTINCT type_item_in_activity.type_activityid
   FROM rules.type_item_in_activity
  WHERE ((NOT type_item_in_activity.is_item_input) AND (NOT (type_item_in_activity.type_itemid IN ( SELECT DISTINCT type_item_in_activity_1.type_itemid
           FROM rules.type_item_in_activity type_item_in_activity_1
          WHERE type_item_in_activity_1.is_item_input
        UNION
         SELECT DISTINCT type_item_as_tool_in_activity.type_itemid
           FROM rules.type_item_as_tool_in_activity
          WHERE type_item_as_tool_in_activity.is_mandatory))));


--
