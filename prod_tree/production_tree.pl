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

	my $prod = $pg->db->query('SELECT * FROM rules.all_productions WHERE aid=?;',$c->param('aid'));
	$prod = $prod->hash;
	say Dumper($prod);

	my $structures = $pg->db->query('SELECT type_structure_name, type_structureid FROM rules.type_structure;');
	$structures = $structures->arrays->to_array;
	say Dumper($structures);

	my $available_items = $pg->db->query('SELECT type_itemid FROM rules.type_item WHERE aux_production_level>0;')->arrays->to_array;
	say Dumper($available_items);

	my $available_items = $pg->db->query('SELECT type_itemid FROM rules.type_item WHERE aux_production_level>0;')->arrays->to_array;
	say Dumper($available_items);

	my $not_produced_items = $pg->db->query('SELECT type_itemid FROM rules.type_item WHERE aux_production_level<0;')->arrays->to_array;
	say Dumper($not_produced_items);


# roman letters for structure levels
	my $sl = [['I',1],['II',2]];

	$c->render(template => 'production_edit', structures => $structures, structurelevels => $sl, available_items => $available_items, not_produced_items => $not_produced_items);
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

<h1>Production ID:  <%= param 'aid' =%></h1>


<table frame="box" width='500px'>
	<tr>
		<td>Name:</td>
		<td colspan="2"> <%= text_field  'Production name' => (id=>"name") =%> </td>
		<td> <%= input_tag 'rename', id=>'renamebutton', type => 'button', value => 'rename', onclick => '' =%> </td>
	</tr>
	<tr>
		<td>Stamina:</td>
		<td colspan="2"> <%= text_field  'Stamina needed' => (id=>"stamina") =%> </td>
		<td> <%= input_tag 'updatestamina', id=>'updatestaminabutton', type => 'button', value => 'update stamina', onclick => '' =%> </td>
	</tr>
	<tr>
	<td rowspan="2">Structure:</td>
		<td><%= select_field 'structure' => $structures,  (id => 'structures') =%> </td>
		<td><%= select_field 'structurelevel' => $structurelevels,  (id => 'structurelevel') =%> </td>
		<td rowspan="2"><%= input_tag 'updatestructure', id=>'updatestructurebutton', type => 'button', value => 'use this structure', onclick =>  'console.dir({sid:jQuery("#structures>option:selected").val(),level:jQuery("#structurelevel>option:selected").val()})' =%> </td>
	</tr>
	<tr>
		<td colspan="2"> <%= input_tag 'createnewstructure', id=>'create_new_structure_button', type => 'button', value => 'Create a brand new structure', onclick => '' =%> </td>
	</tr>
</table>



<table frame="box" width='500px'>
<% foreach my $ctg ('inputs', 'tools', 'outputs') { %>
		<tr>
			<td rowspan="2"> <%= $ctg =%>: </td>
			<% if ($ctg !~ /^tools$/) { %> <td rowspan="2"> </td> <% } else { %>
				<td> <%= input_tag 'mark_as_mandatory', id=> 'mark_as_mandatory_button', type => 'button', value => '!', onclick => '' =%> </td>
			<% } %>
			<td rowspan="2"> <%= select_field 'items' => [],  (id => 'items_'.$ctg, multiple => 'multiple', class => 'select_items') =%> </td>
			<td> <%= input_tag 'additem_'.$ctg, id=> 'additem_'.$ctg.'button', type => 'button', value => '<--', onclick => '' =%> </td>
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
			<td> <%= input_tag 'delitem_'.$ctg, id=> 'delitem_'.$ctg.'_button', type => 'button', value => '-->', onclick => ''=%> </td>
		</tr>
<% } %>
	<tr>
		<td colspan="2"></td>
		<td colspan="3"> <%= input_tag 'createnewitem', id=>'create_new_item_button', type => 'button', value => 'Create a brand new item', onclick => '' =%> </td>
	</tr>
</table>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
