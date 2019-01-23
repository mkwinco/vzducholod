-- Name: type_tile; Type: TABLE; Schema: rules; Owner: -
--

CREATE TABLE rules.type_tile (
    type_tileid integer NOT NULL,
    name text
);


--
-- Data for Name: type_activity; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_activity (type_activityid, type_structureid, stamina, type_activity_name, min_struct_level, aux_production_level) FROM stdin;
6201	20000062	155	wheat production	1	0
6202	20000062	250	sugar production	1	0
10005	108	100	Simple tool production	1	0
4201	20000042	122	flour from wheet	1	1
4301	20000043	201	bread from flour	1	2
\.


--
-- Name: type_activityid_seq; Type: SEQUENCE SET; Schema: rules; Owner: -
--

SELECT pg_catalog.setval('rules.type_activityid_seq', 10006, true);


--
-- Data for Name: type_construction; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_construction (type_constructionid, type_structureid, level, stamina, steps) FROM stdin;
\.


--
-- Data for Name: type_flow; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_flow (type_flowid, type_flow_name) FROM stdin;
IF	Item Flow
MS	Market Supply
FA	Field Assignment
HS	House Supply
WFA	Workforce Assignment
\.


--
-- Data for Name: type_flow_subclass; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_flow_subclass (type_flow_subclassid, type_flowid, description) FROM stdin;
AGR	FA	Agriculture
CONSTR	FA	Structure construction
COLLECT	FA	collecting something
\.


--
-- Data for Name: type_flows_allowed_on_type_structures; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_flows_allowed_on_type_structures (is_starting_here, type_structure_classid, type_flowid) FROM stdin;
t	PS-CAMP	IF
t	PS-WS	IF
f	PS-CAMP	IF
f	PS-WS	IF
t	WH	IF
f	WH	IF
t	PS-CAMP	MS
t	PS-WS	MS
t	WH	MS
f	MARKET	MS
t	PS-CAMP	FA
f	WF	FA
t	MARKET	HS
t	WH	HS
f	HOUSE	HS
t	HOUSE	WFA
f	PS-CAMP	WFA
f	PS-WS	WFA
f	WH	WFA
f	MARKET	WFA
\.


--
-- Data for Name: type_item; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_item (name, type_itemid, aux_production_level) FROM stdin;
butter	BUTTER	-1
scythe	SCYTHE	-1
kosak	KOSAK	-1
wheat	WHEAT	1
sugar	SUGAR	1
simpletool	SIMPLETOOL	1
flour	FLOUR	2
bread	BREAD	3
\.


--
-- Data for Name: type_item_as_tool_in_activity; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_item_as_tool_in_activity (type_activityid, type_itemid, is_mandatory, multiplicator_presence, multiplicator_level, durability) FROM stdin;
6201	KOSAK	f	1	1	0
6202	KOSAK	f	1	1	0
6202	SCYTHE	f	1	1	0
\.


--
-- Data for Name: type_item_in_activity; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_item_in_activity (type_activityid, type_itemid, is_item_input, item_count) FROM stdin;
4301	BREAD	f	1
6202	SUGAR	f	1
4301	SUGAR	t	1
4301	FLOUR	t	1
4201	FLOUR	f	1
6201	WHEAT	f	1
4201	WHEAT	t	2
10005	SIMPLETOOL	f	1
\.


--
-- Data for Name: type_item_in_construction; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_item_in_construction (type_constructionid, type_itemid, item_count) FROM stdin;
\.


--
-- Data for Name: type_structure; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_structure (type_structureid, area_min, area_max, xplusy_min, xplusy_max, type_structure_name, type_structure_classid, item_space, type_flow_subclassid) FROM stdin;
20000042	\N	\N	\N	\N	mill	PS-WS	0	\N
20000030	\N	\N	\N	\N	warehouse	WH	0	\N
20000020	\N	\N	\N	\N	market	MARKET	0	\N
20000010	\N	\N	\N	\N	house	HOUSE	0	\N
20000071	\N	\N	\N	\N	construction camp	PS-CAMP	0	CONSTR
20000072	\N	\N	\N	\N	farm	PS-CAMP	0	AGR
20000061	\N	\N	\N	\N	construction site	WF	0	CONSTR
20000043	\N	\N	\N	\N	bakery	PS-WS	3	\N
20000062	\N	\N	\N	\N	field	WF	0	AGR
103	\N	\N	\N	\N	pasture	WF	0	AGR
108	\N	\N	\N	\N	simpleworkshop	PS-WS	0	\N
\.


--
-- Data for Name: type_structure_class; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_structure_class (type_structure_classid, full_name) FROM stdin;
HOUSE	House
MARKET	Market
PS-CAMP	Production Structure - Camp
PS-WS	Production Structure - Workshop
WF	Working Field
WH	Warehouse/Storage
\.


--
-- Name: type_structureid_seq; Type: SEQUENCE SET; Schema: rules; Owner: -
--

SELECT pg_catalog.setval('rules.type_structureid_seq', 108, true);


--
-- Data for Name: type_structures_allowed_on_type_tiles; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_structures_allowed_on_type_tiles (type_structureid, type_tileid) FROM stdin;
\.


--
-- Data for Name: type_tile; Type: TABLE DATA; Schema: rules; Owner: -
--

COPY rules.type_tile (type_tileid, name) FROM stdin;
\.


--
-- Name: type_tile type_tile_pkey; Type: CONSTRAINT; Schema: rules; Owner: -
--

ALTER TABLE ONLY rules.type_tile
    ADD CONSTRAINT type_tile_pkey PRIMARY KEY (type_tileid);


--
