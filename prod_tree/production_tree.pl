#!/usr/bin/env perl


use Data::Dumper;
$Data::Dumper::Terse = 'true';
$Data::Dumper::Sortkeys = 'true';
$Data::Dumper::Sortkeys = sub { [reverse sort keys %{$_[0]}] };


use Mojolicious::Lite;
use Mojo::Pg;
# protocol://user:pass@host/database
my $pg = Mojo::Pg->new('postgresql://postgres:postgres@localhost/econmod_v03');


get '/production.api' => sub {
	my $c = shift;

	# if aid in parameters, then search just the given production, otherwise return all productions
	my $select = ();
	if ($c->param('aid') =~ /^\d+$/ ) {
		$select = $pg->db->query('SELECT * FROM rules.all_productions WHERE aid=?;',$c->param('aid'));
	} else {
		$select = $pg->db->query('SELECT * FROM rules.all_productions ORDER BY aux_production_level ASC;');
	}
	$select = $select->expand;

	my @out = ();
	while (my $next = $select->hash) {push(@out,$next);}

	say Dumper(\@out);

	$c->render(json => {activities => \@out});

};

# see all producitons
get '/production_tree' => sub {
	my $c = shift;

	$c->render(template => 'overview');

};

# edit one single production
get '/production' => sub {
	my $c = shift;

	my $prod = $pg->db->query('SELECT * FROM rules.all_productions WHERE aid=?;',$c->param('aid'))->hash;
	#say Dumper($prod);

	my $structures = $pg->db->query('SELECT type_structure_name, type_structureid FROM rules.type_structure;')->arrays->to_array;
	#say Dumper($structures);

	my $available_items = $pg->db->query('SELECT type_itemid FROM rules.type_item WHERE aux_production_level>0;')->arrays->to_array;
	foreach (@{$available_items}) {$_=$_->[0]};
	#say Dumper($available_items);

	my $not_produced_items = $pg->db->query('SELECT type_itemid FROM rules.type_item WHERE aux_production_level<0;')->arrays->to_array;
	foreach (@{$not_produced_items}) {$_=$_->[0]};
	#say Dumper($not_produced_items);


# roman letters for structure levels
	my $sl = [['I',1],['II',2],['III',3],['IV',4]];

	$c->render(template => 'production_edit', structures => $structures, structurelevels => $sl, available_items => $available_items, not_produced_items => $not_produced_items);
};


post '/production/basic_updates' => sub {
	my $c = shift;

	my $prod = $pg->db->query(qq(UPDATE rules.type_activity SET type_structureid=?, min_struct_level=?, type_activity_name=?, stamina=? WHERE type_activityid=?;),$c->param('values[type_structureid]'),$c->param('values[min_struct_level]'),$c->param('values[type_activity_name]'),$c->param('values[stamina]'),$c->param('aid'));

	$c->render(json => {return_value => 0});
};


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

<h1>Production tree overview</h1>


@@ production_edit.html.ep
% layout 'default';
% title ' Edit Production';

% content
%= stylesheet begin
	.select_items {width:125px; height:100px;}
	.available_items {width:125px; height:200px;}
%= end

%= javascript "//code.jquery.com/jquery-2.1.1.js"


%= javascript begin
	jQuery.getJSON(
		'/production.api',
		{aid:<%= param 'aid' =%>})
		.done(function( data ) {
			var p=data.activities[0];
			console.dir(p);

			jQuery('#name').val(p.activity);
			jQuery('#stamina').val(p.stamina);

			jQuery.each(['inputs','outputs'], function(i,ctg) {
				console.log(p[ctg]);

				// each item listed in this category
				for (var item in p[ctg]){
					console.log(p[ctg][item]);

					// add item as many times as listed in DB
					for(var i=1; i <= p[ctg][item]; i++) {
						jQuery('#items_'+ctg).append('<option value='+item+'>'+item+'</option>');
					};
				};
			});

			// tools have a bit different data schema
			for (var item in p.tools){
				var css={};
				if (p.tools[item]) {
					css={'background-color':'red', 'color':'white'};
				} else {
					css={'background-color':'blue', 'color':'white'};
				};
				jQuery('#items_tools').append(jQuery('<option value='+item+'>'+item+'</option>').css(css));
			};


		}
	)
% end

%= javascript begin
function basic_updates(aid) {
  //send post data and reload ALWAYS (not only when done)
  //console.log(aid);
	var v = {
		type_structureid:jQuery('#structures').val(),
		min_struct_level:jQuery('#structurelevel').val(),
		type_activity_name:jQuery('#name').val(),
		stamina:jQuery('#stamina').val()
	};
  jQuery.post('/production/basic_updates',{aid:aid, values:v})
    .always(function(){
        location.reload();
    });
};
%= end

<h1>Production ID:  <%= param 'aid' =%></h1>


<table frame="box" width='540px'>
	<tr>
		<td>Name:</td>
		<td colspan="3"> <%= text_field  'Production name' => (id=>"name") =%> </td>
		<td rowspan="3"> <%= input_tag 'update', id=>'updatebutton', type => 'button', value => 'update', onclick => "basic_updates(".(param 'aid')." )" =%> </td>
	</tr>
	<tr>
		<td>Stamina:</td>
		<td colspan="3"> <%= text_field  'stamina ' => (id=>"stamina") =%> </td>

	</tr>
	<tr>
	<td>Structure:</td>
		<td><%= select_field 'structure' => $structures,  (id => 'structures') =%> </td>
		<td> <%= input_tag 'createnewstructure', id=>'create_new_structure_button', type => 'button', value => '...', onclick => "" =%> </td>
		<td><%= select_field 'structurelevel' => $structurelevels,  (id => 'structurelevel') =%> </td>
	</tr>
</table>

<br>

<table frame="box" width='540px'>
		<tr><td align="center" colspan="5">Items: </td></tr>

<% foreach my $ctg ('inputs', 'tools', 'outputs') { %>
		<tr>
			<td rowspan="2"> <%= $ctg =%>: </td>
			<% if ($ctg !~ /^tools$/) { %> <td rowspan="2"> </td> <% } else { %>
				<td> <%= input_tag 'mark_as_mandatory', id=> 'mark_as_mandatory_button', type => 'button', value => '!', onclick => '' =%> </td>
			<% } %>
			<td rowspan="2"> <%= select_field 'items' => [],  (id => 'items_'.$ctg, multiple => 'multiple', class => 'select_items') =%> </td>
			<td align="center"> <%= input_tag 'additem_'.$ctg, id=> 'additem_'.$ctg.'button', type => 'button', value => '<--', onclick => '' =%> </td>
			<% if ($ctg =~ /^inputs$/) { %>
				<td rowspan="4"> <%= select_field 'available_items' => $available_items,  (id => 'available_items', multiple => 'multiple', class => 'available_items') =%> </td>
			<% } elsif ($ctg =~ /^outputs$/) { %>
				<td rowspan="2"> <%= select_field 'not_produced_items' => $not_produced_items,  (id => 'not_produced_items', multiple => 'multiple', class => 'select_items') =%> </td>
			<% } %>
		</tr>
		<tr>
			<% if ($ctg =~ /^tools$/) {  %>
				<td> <%= input_tag 'mark_as_auxiliary', id=> 'mark_as_axiliary_button', type => 'button', value => 'aux', onclick => '' =%> </td>
			<% } %>
			<td align="center"> <%= input_tag 'delitem_'.$ctg, id=> 'delitem_'.$ctg.'_button', type => 'button', value => '-->', onclick => ''=%> </td>
		</tr>
<% } %>
	<tr></tr>
	<tr>
		<td colspan="2"></td>
		<td colspan="3" align="center"> <%= input_tag 'createnewitem', id=>'create_new_item_button', type => 'button', value => 'Create a brand new item', onclick => '' =%> </td>
	</tr>
</table>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
