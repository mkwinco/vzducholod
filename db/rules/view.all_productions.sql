-- Name: all_productions; Type: VIEW; Schema: rules; Owner: -
--

CREATE VIEW rules.all_productions AS
 SELECT fullselect.type_activityid AS aid,
    fullselect.type_activity_name AS activity,
    fullselect.type_structure_name AS structure,
    fullselect.stamina,
    fullselect.inputs,
    fullselect.outputs,
    fullselect.tools,
    fullselect.min_struct_level,
    fullselect.aux_production_level
   FROM ( SELECT type_activity.type_activityid,
            type_activity.type_structureid,
            type_activity.stamina,
            type_activity.min_struct_level,
            type_activity.type_activity_name,
            type_activity.aux_production_level,
            type_structure.area_min,
            type_structure.area_max,
            type_structure.xplusy_min,
            type_structure.xplusy_max,
            type_structure.type_structure_name,
            type_structure.type_structure_classid,
            type_structure.item_space,
            type_structure.type_flow_subclassid,
            inputs.inputs,
            outputs.outputs,
            tools.tools
           FROM ((((rules.type_activity
             JOIN rules.type_structure USING (type_structureid))
             LEFT JOIN ( SELECT json_object_agg(type_item_in_activity.type_itemid, type_item_in_activity.item_count) AS inputs,
                    type_item_in_activity.type_activityid
                   FROM rules.type_item_in_activity
                  WHERE type_item_in_activity.is_item_input
                  GROUP BY type_item_in_activity.type_activityid) inputs USING (type_activityid))
             LEFT JOIN ( SELECT json_object_agg(type_item_in_activity.type_itemid, type_item_in_activity.item_count) AS outputs,
                    type_item_in_activity.type_activityid
                   FROM rules.type_item_in_activity
                  WHERE (NOT type_item_in_activity.is_item_input)
                  GROUP BY type_item_in_activity.type_activityid) outputs USING (type_activityid))
             LEFT JOIN ( SELECT json_object_agg(type_item_as_tool_in_activity.type_itemid, type_item_as_tool_in_activity.is_mandatory) AS tools,
                    type_item_as_tool_in_activity.type_activityid
                   FROM rules.type_item_as_tool_in_activity
                  GROUP BY type_item_as_tool_in_activity.type_activityid) tools USING (type_activityid))) fullselect;


--
-- Name: VIEW all_productions; Type: COMMENT; Schema: rules; Owner: -
--

COMMENT ON VIEW rules.all_productions IS 'From postgresql 9.5 - recommended to use jsonB instead of json';


--
