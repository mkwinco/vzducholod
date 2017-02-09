#!/usr/bin/env perl


use Data::Dumper;
$Data::Dumper::Terse = 'true';
$Data::Dumper::Sortkeys = 'true';
$Data::Dumper::Sortkeys = sub { [reverse sort keys %{$_[0]}] };


use Mojolicious::Lite;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Pg;
# protocol://user:pass@host/database
my $pg = Mojo::Pg->new('postgresql://postgres:postgres@localhost/econmod_v03');


##############################################################

############
# see all productions (nice big overview)
get '/production_tree' => sub {
	my $c = shift;

	$c->render(template => 'overview');
};
############

############
# this one returns info about one or more production - JSON style
get '/production.api' => sub {
	my $c = shift;

	# if aid in parameters, then search just the given production, otherwise return all productions
	my $select = ();
	if ( (defined $c->param('aid') ) && ($c->param('aid') =~ /^\d+$/ ) ) {
		$select = $pg->db->query('SELECT * FROM rules.all_productions WHERE aid=?;',$c->param('aid'));
	} else {
		$pg->db->query('SELECT rules.aux_devel_productions_hierarchy();'); # well, before returning whole set - reorganizing
		$select = $pg->db->query('SELECT * FROM rules.all_productions ORDER BY aux_production_level ASC;');
	}
	$select = $select->expand;

	# creating final output as array of production(s)
	my @out = ();
	while (my $next = $select->hash) {push(@out,$next);}
	#say Dumper(\@out);

	$c->render(json => {activities => \@out});
};
############

############
# editing one production
get '/production' => sub {
	my $c = shift;

	# read data about this production
	my $prod = $pg->db->query('SELECT * FROM rules.all_productions WHERE aid=?;',$c->param('aid'))->hash;
	# actually, data about all item categories come as JSON encoded
	foreach ('inputs','tools','outputs') { $prod->{$_} = decode_json $prod->{$_} if defined $prod->{$_}};
	# if there is no such produciton render error
	if (! %{$prod}) {
		$c->render(inline => 'No such production');
		return;
	};
	# if the activity produces only end-products, we show "delete" button
	$prod->{'removable'} = $pg->db->query(qq(SELECT count(*) FROM rules.endproduct_or_empty_activities WHERE type_activityid=?;),$c->param('aid'))->arrays->to_array->[0]->[0];
	#say Dumper($prod);

	# create arrays for html selection elements
	my $items = ();
	foreach my $ctg ('inputs','outputs') {
		foreach (keys %{$prod->{$ctg}}) {
			# in the array, each item is listed as many times as is their number in production
			for (my $i=0; $i<$prod->{$ctg}->{$_}; $i++ ) {push(@{$items->{$ctg}},$_)};
		};
	};
	foreach (keys %{$prod->{'tools'}}) {
		# separate manadatory and enhancing tools
		if ($prod->{'tools'}->{$_}) {push(@{$items->{'mandatory_tools'}},$_)} else {push(@{$items->{'enhancing_tools'}},$_)};
	}
	#say Dumper($items);

	# prepare array of production structures for selection element
	my $structures = $pg->db->query(qq(SELECT type_structure_name, type_structureid FROM rules.type_structure WHERE type_structure_classid ~* ? ;),'PS-WS|WF')->arrays->to_array;
	#say Dumper($structures);

	# list items with their information about their production status (aux_production_level<0 - not produced yet)
	# in the embedded perl, appropriate lists for item selections will be prepared from this hash
	my $allitems = ();
	foreach (@{$pg->db->query('SELECT type_itemid,aux_production_level FROM rules.type_item;')->hashes->to_array}) {
		$allitems->{$_->{'type_itemid'}} = $_->{'aux_production_level'};
	};
	#say Dumper($allitems);

# just roman letters for structure levels
	my $sl = [['I',1],['II',2],['III',3],['IV',4],['V',5],['VI',6],['VII',7],['VIII',8],['IX',9],['X',10],['XI',11],['XII',12]];

	$c->render(template => 'production_edit', prod => $prod, items=>$items, structures => $structures, structurelevels => $sl, allitems => $allitems, arrows => {'add' => '<--', 'del' => '-->'} );
};
############

############
get '/structure' => sub {
	my $c = shift;

# well, list all classes (although they are fixed by game principles)
	my $class = ();
	foreach (@{$pg->db->query(qq(SELECT full_name, type_structure_classid  FROM rules.type_structure_class;))->hashes->to_array}) {
		# actually the structure mentioned here http://mojolicious.org/perldoc/Mojolicious/Plugin/TagHelpers#select_field is NOT valid perl structure, but one can use just a list ("=>" --> ",")
		my $sel = ($_->{'type_structure_classid'} eq 'PS-WS') ? 'selected' : '';
		push(@$class,[$_->{full_name} => $_->{type_structure_classid}, $sel => $sel]);
	}
	#say Dumper($class);

# and as well, list all Field Assignment (FA) flow's subclasses (these are dynamic and can be altered - as part of production tree editing)
		my $subclass->[0] = ['none' => 'NULL','selected' => 'selected'];
		foreach (@{$pg->db->query(qq(SELECT type_flow_subclassid, description FROM rules.type_flow_subclass WHERE type_flowid='FA';))->hashes->to_array}) {
			push(@$subclass,[$_->{'description'} => $_->{'type_flow_subclassid'}]);
		}
	#say Dumper($subclass);

	$c->render(template => 'structure_edit', class => $class, subclass => $subclass);
};
############


############
# delete site
get '/delete' => sub {
	my $c = shift;

	# list all production structures not included in any activity
	my $structures = $pg->db->query(qq(SELECT type_structure_name, type_structureid FROM rules.type_structure WHERE type_structure_classid ~* ? AND type_structureid NOT IN (SELECT DISTINCT type_structureid FROM rules.type_activity);),'PS-WS|WF')->arrays->to_array;
	#say Dumper($structures);

 	my $subclass = $pg->db->query(qq(SELECT description, type_flow_subclassid  FROM rules.type_flow_subclass WHERE type_flow_subclassid NOT IN (SELECT DISTINCT type_flow_subclassid FROM rules.type_structure WHERE type_flow_subclassid IS NOT NULL);))->arrays->to_array;
	#say Dumper($subclass);

	my $items = $pg->db->query(qq(SELECT name, type_itemid  FROM rules.type_item WHERE type_itemid NOT IN (SELECT type_itemid FROM rules.type_items_used);))->arrays->to_array;
	#say Dumper($items);

	$c->render(template => 'delete', structures => $structures, subclass => $subclass, items => $items);
};
############

################################################# GET POST ######################################

############
# insert a new production
post '/production/new' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	# create empty new structure (only mandatory fields are filled in - name, stamina (set to 0) and structure (with highest ID))
	$pg->db->query(qq(INSERT INTO rules.type_activity(type_structureid, stamina, type_activity_name) VALUES ((SELECT max(type_structureid) FROM rules.type_structure),?,?);),0, $c->param('type_activity_name') );

	$c->redirect_to('/production_tree');
};
############

############
# this covers just basic updates to production - name, stamina a structure's type and minlevel
post '/production/basic_updates' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	my $prod = $pg->db->query(qq(UPDATE rules.type_activity SET type_structureid=?, min_struct_level=?, type_activity_name=?, stamina=? WHERE type_activityid=?;),$c->param('type_structureid'),$c->param('min_struct_level'),$c->param('type_activity_name'),$c->param('stamina'),$c->param('aid'));

	$c->redirect_to($c->req->headers->referrer);
};
############

############
# this covers addition and removal of items (inputs, outputs and tools from production)
post '/production/item_updates' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	my $update = ();

	# updating outputs and inputs (tools are left for later)
	if ($c->param('what') =~ /^(in|out)puts$/) {

		# translate answer to the question "is the input" in the pg.db language
		my $is_item_input = ($c->param('what') eq 'inputs') ? '1' : '0';

		my $query = qq();
		# when adding one more item, just insert - if it's update what is really needed, DB trigger will take care of this
		$query = qq(INSERT INTO rules.type_item_in_activity(type_activityid, type_itemid, is_item_input, item_count) VALUES (?,?,?,?);) if ($c->param('update_type') eq "add");
		# when removing one item, just update - if it's delete what is really needed, DB trigger will take care of this
		$query = qq(UPDATE rules.type_item_in_activity SET item_count=item_count-1 WHERE type_activityid=? AND type_itemid=? AND is_item_input=? AND 1=?;) if ($c->param('update_type') eq "del");

		# execute prepared query for items
		$update = $pg->db->query($query,$c->param('aid'),$c->param('item'),$is_item_input,1);

	# updating tools (inputs/outputs are above)
	} elsif ($c->param('what') =~ /^(mandatory|enhancing)_tools$/) {

		# translate answer to the question "is the tool mandatary" in the pg.db language
		my $is_mandatory = ($c->param('what') =~ /^mandatory/) ? '1' : '0';

		# when adding one more item, just insert - if it's update what is really needed, DB trigger will take care of this
		$update = $pg->db->query(qq(INSERT INTO rules.type_item_as_tool_in_activity (type_activityid, type_itemid, is_mandatory) VALUES (?, ?, ?); ),$c->param('aid'),$c->param('item'), $is_mandatory) if ($c->param('update_type') eq "add");
		# delete is just delete - there is always just one tool type mentioned for given activity
		$update = $pg->db->query(qq(DELETE FROM rules.type_item_as_tool_in_activity WHERE type_activityid=? AND type_itemid=?;),$c->param('aid'),$c->param('item')) if ($c->param('update_type') eq "del");

	}; # endif for tools

	$c->render(json => {return_value => 0});
};
############

############
# creating new item - we need just its name
post '/item/new' => sub {
	my $c = shift;
	say Dumper($c->req->params->to_hash);

	# lower case for name, upper case for ID
	$pg->db->query(qq(INSERT INTO rules.type_item(name, type_itemid) VALUES (?, ?);),lc $c->param('type_itemid'),uc $c->param('type_itemid') );

	$c->redirect_to($c->req->headers->referrer);
};
############

############
# creating new FA subclass - we need just name and description
post '/structure/new' => sub {
	my $c = shift;
	say Dumper($c->req->params->to_hash);

	# type_flow_subclassid can be null
	my $tpsc = ($c->param('type_flow_subclassid') ne 'NULL') ? $c->param('type_flow_subclassid') : undef;
	#say $tpsc;

	# lower case for description, upper case for ID
	$pg->db->query(qq(INSERT INTO rules.type_structure(type_structure_name, type_structure_classid, type_flow_subclassid) VALUES (?, ?, ?);),lc $c->param('type_structure_name'),uc $c->param('type_structure_classid'),$tpsc);

	$c->redirect_to($c->req->headers->referrer);
};
############

############
# creating new FA subclass - we need just name and description
post '/structure/subclass/new' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	# lower case for description, upper case for ID
	$pg->db->query(qq(INSERT INTO rules.type_flow_subclass(type_flow_subclassid, type_flowid, description) VALUES (?, ?, ?);),uc $c->param('type_flow_subclassid'),'FA',lc $c->param('description') );

	$c->redirect_to($c->req->headers->referrer);
};
############

############
# this one just deletes the given activity type
post '/production/delete' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	$pg->db->query(qq(DELETE FROM rules.type_activity WHERE type_activityid=?),$c->param('aid'));

	$c->redirect_to('/production_tree');
};
############

############
# this one just deletes the given structure type
post '/structure/delete' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	$pg->db->query(qq(DELETE FROM rules.type_structure WHERE type_structureid=?),$c->param('type_structureid'));

	$c->redirect_to($c->req->headers->referrer);
};
############

############
# this one just deletes the given structure type
post '/structure/subclass/delete' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	$pg->db->query(qq(DELETE FROM rules.type_flow_subclass WHERE type_flow_subclassid=?),$c->param('type_flow_subclassid'));

	$c->redirect_to($c->req->headers->referrer);
};
############

############
# this one just deletes the given structure type
post '/item/delete' => sub {
	my $c = shift;
	#say Dumper($c->req->params->to_hash);

	$pg->db->query(qq(DELETE FROM rules.type_item WHERE type_itemid=?),$c->param('type_itemid'));

	$c->redirect_to($c->req->headers->referrer);
};
############

####################################################################################
app->start;
__DATA__

@@ overview.html.ep
% layout 'default';
% title 'Production tree';

% content
%= javascript "//code.jquery.com/jquery-2.1.1.js"
%= javascript "http://d3js.org/d3.v3.min.js"

%= javascript "production_tree.js"

%= javascript begin
	refresh();
% end

%= form_for '/production/new' => (method => 'post') => begin
	<%= text_field 'type_activity_name', value => 'new production name' %>
	%= submit_button 'New Production'
%= end

<br>

<h1>Production tree overview</h1>




@@ production_edit.html.ep
% layout 'default';
% title 'Edit Production';
%= javascript "//code.jquery.com/jquery-2.1.1.js"


%= stylesheet begin
	.stamina_input {width:40px;}

	.select_inputs 											{width:125px; height:100px;}
	.all_items, .select_enhancing_tools {width:125px; height:50px;}
	.select_mandatory_tools 						{width:125px; height:50px;}
	.select_outputs, .items_for_output 	{width:125px; height:100px;}
	.available_items 										{width:125px; height:150px;}
%= end


%= javascript begin
///////////////
function item_updates(ut,ctg,aid) {
	//console.log(ctg)

	var source = {add:"#available_for_", del:"#items_"}

	// when selecting mandatory_tools, source element is the same as inputs'
	var ctgs = ((ctg == 'mandatory_tools') && (ut == 'add')) ? 'inputs' : ctg;

	// there can be multiple selections, so let's do them in array
	jQuery(source[ut]+ctgs+'>option:selected').each( function(i,v){
		//console.log(v.value);

		jQuery.post('/production/item_updates',{update_type:ut, what:ctg, item:v.value, aid:aid})
			.always(function(){
				jQuery(source[ut]+ctg).find(jQuery('option')).attr('selected',false); //deselecting
				location.reload();
			});
	});
};
///////////////
%= end


% content
<h1>Production ID:  <%= param 'aid' =%></h1>

% # These are just basic updates packet into table (it's nicer to do it via form_for)
%= form_for '/production/basic_updates' => (method => 'post') => begin
%= hidden_field aid => (param 'aid')
<table frame="box" width='540px'>
	<tr>
		<td>Name:</td>
		<td colspan="3" align="center"> <%= text_field  'type_activity_name' => $prod->{'activity'}, id=>"name"   =%> </td>
		<td rowspan="3"> <%= submit_button 'update', id=>'updatebutton'=%> </td>
	</tr>
	<tr>
		<td>Stamina:</td>
		<td colspan="3" align="left"> <%= text_field  'stamina' => $prod->{'stamina'}, id=>"stamina", class => 'stamina_input' =%> </td>
	</tr>
	<tr>
	<td>Structure:</td>
		<td><%= select_field 'type_structureid' => $structures,  (id => 'structures') =%> </td>
		<td> <%= input_tag 'createnewstructure', id=>'create_new_structure_button', type => 'button', value => 'Create New', onclick => "location.href='/structure'" =%> </td>
		<td><%= select_field 'min_struct_level' => $structurelevels,  (id => 'structurelevel') =%> </td>
	</tr>
</table>
%= end

<br>

% # Item table starts here
% # First comes form for creating new item
<table frame="box" width='540px'>
	<tr><td colspan="4" align="center">
		%= form_for '/item/new' => (method => 'post') => begin
			<%= text_field 'type_itemid', value => 'NEWITEM' , id=>'create_new_item_button' %>
			<%= submit_button 'Create a new item ...' %>
		%= end
	</td></tr>
	<tr><td colspan="4" align="center"> ... or manage existing: </td></tr>

% # Add/remove GUI can is almost the same code for all four categories of items - so let's pack it into loop
<% foreach my $ctg ('inputs', 'mandatory_tools', 'enhancing_tools', 'outputs') { %>
		<tr>
			<td rowspan="1"> <%= $ctg =%>: </td>
% # here we use the stashed hash $items
			<td rowspan="1"> <%= select_field 'items' => $items->{$ctg},  (id => 'items_'.$ctg, multiple => 'multiple', class => 'select_'.$ctg) =%> </td>
			<td align="left" valign="middle">
% # even add and del buttons have very similar code, so we use foreach
				<% foreach my $a ('add', 'del') { %>
						<%= input_tag $a.'_item_'.$ctg, id=> $a.'_item_'.$ctg.'_button', type => 'button', value => $arrows->{$a}, onclick => qq(item_updates\('$a','$ctg',).(param 'aid').qq(\)) =%>
						<br>
				<% } %>
			</td>
% # well the selection of items to add require different condition (on items) for each category, therefore we need a lot of ifs and elsifs
			<% if ($ctg =~ /^inputs$/) { %>
				<td rowspan="2"> <%= select_field 'available_items' => [sort grep {$allitems->{$_}>0} keys %{$allitems}],  (id => 'available_for_'.$ctg, multiple => 'multiple', class => 'available_items') =%> </td>
			<% } elsif ($ctg =~ /^enhancing_tools$/) { %>
				<td rowspan="1"> <%= select_field 'all_items' => [sort keys %{$allitems}],  (id => 'available_for_'.$ctg, multiple => 'multiple', class => 'all_items') =%> </td>
			<% } elsif ($ctg =~ /^outputs$/) { %>
				<td rowspan="1"> <%= select_field 'not_produced_items' => [sort grep {$allitems->{$_}<0} keys %{$allitems}],  (id => 'available_for_'.$ctg, multiple => 'multiple', class => 'select_outputs') =%> </td>
			<% } %>
		</tr>

<% } %>
% # end of foreach

</table>
% # end of foreach table

<br>
% # link to delete site
%= form_for '/delete' => (method => 'get') => begin
	%= submit_button 'Delete structure or item ...'
%= end

<br>
% # show delete "button" only if allowed production
% if ($prod->{'removable'} == 1) {
	%= form_for '/production/delete' => (method => 'post') => begin
		%= submit_button 'Delete this production'
		%= hidden_field aid => (param 'aid')
	%= end
% } else {
	(There is another activity dependending on this production's outputs)
% }


@@ structure_edit.html.ep
% layout 'default';
% title 'New Structure';

% content
<h2>Add structure</h2>
%= form_for '/structure/new' => (method => 'post') => begin
	<table frame="box" width='540px'>
		<tr>
			<td>Structure Name</td>
			<td>Class</td>
			<td>Subclass</td>
			<td rowspan="2"><%= submit_button 'Add Structure' %></td>
		</tr>
		<tr>
			<td><%= text_field 'type_structure_name', value => 'new structure name' %></td>
			<td><%= select_field 'type_structure_classid' => $class %></td>
			<td><%= select_field 'type_flow_subclassid' => $subclass %></td>
		</tr>
	</table>
%= end

<h2>Add FA-flow subclass</h2>
%= form_for '/structure/subclass/new' => (method => 'post') => begin
	<table frame="box" width='540px'>
		<tr>
			<td>Subclass description</td>
			<td>Subclass ID</td>
			<td rowspan="2"><%= submit_button 'Add Subclass' %></td>
		</tr>
		<tr>
			<td><%= text_field 'description', value => 'This bind camp with workfield' %></td>
			<td><%= text_field 'type_flow_subclassid', value => 'SUBCLASSID' %></td>
		</tr>
	</table>
%= end


@@ delete.html.ep
% layout 'default';
% title 'Delete objects';

% content


<h2>Delete structure type</h2>
%= form_for '/structure/delete' => (method => 'post') => begin
	<table frame="box" width='540px'>
		<tr>
			<td><%= select_field 'type_structureid' => $structures,  (id => 'structures') =%> </td>
			<td rowspan="1" align="right"><%= submit_button 'Remove structure type' %></td>
		</tr>
	</table>
%= end

<h2>Delete FA-flow subclass</h2>
%= form_for '/structure/subclass/delete' => (method => 'post') => begin
	<table frame="box" width='540px'>
		<tr>
			<td><%= select_field 'type_flow_subclassid' => $subclass,  (id => 'subclass') =%> </td>
			<td rowspan="1" align="right"><%= submit_button 'Remove subclass type' %></td>
		</tr>
	</table>
%= end

<h2>Delete item type</h2>
%= form_for '/item/delete' => (method => 'post') => begin
	<table frame="box" width='540px'>
		<tr>
			<td><%= select_field 'type_itemid' => $items,  (id => 'items') =%> </td>
			<td rowspan="1" align="right"><%= submit_button 'Remove item type' %></td>
		</tr>
	</table>
%= end


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
		<link href="favicon.ico" rel="icon" type="image/x-icon" />
		<title><%= title %></title>
	</head>

  <body><%= content %></body>
</html>
