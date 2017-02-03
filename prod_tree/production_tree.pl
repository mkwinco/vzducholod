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
use Mojo::JSON qw(decode_json encode_json);

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

	#say Dumper(\@out);

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
	foreach ('inputs','tools','outputs') { $prod->{$_} = decode_json $prod->{$_} if defined $prod->{$_}};
	say Dumper($prod);

	my $structures = $pg->db->query('SELECT type_structure_name, type_structureid FROM rules.type_structure;')->arrays->to_array;
	#say Dumper($structures);

	my $available_items = ();
	foreach my $aitem (@{$pg->db->query('SELECT type_itemid FROM rules.type_item WHERE aux_production_level>0;')->arrays->to_array}) {
		# use only such item, that is not output of this activity (and as such it cannot be its input)
		push(@{$available_items}, $aitem->[0]) if (grep {$aitem->[0] ne $_} (keys %{$prod->{'outputs'}} ) ) ;
	};
	#say Dumper($available_items);

	my $not_produced_items = $pg->db->query('SELECT type_itemid FROM rules.type_item WHERE aux_production_level<0;')->arrays->to_array;
	foreach (@{$not_produced_items}) {$_=$_->[0]};
	# moreover add current outputs as they are also available for this prodution as outputs
	push(@{$not_produced_items},(keys %{$prod->{'outputs'}} ));
	#say Dumper($not_produced_items);


# roman letters for structure levels
	my $sl = [['I',1],['II',2],['III',3],['IV',4],['V',5],['VI',6]];

	# all items combined
	my @all_items = (@{$available_items},@{$not_produced_items});
	#say Dumper(\@all_items);

	$c->render(template => 'production_edit', structures => $structures, structurelevels => $sl, available_items => $available_items, not_produced_items => $not_produced_items, all_items =>  \@all_items );
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
	.stamina_input {width:40px;}

	.select_inputs 											{width:125px; height:100px;}
	.all_items, .select_enhancing_tools {width:125px; height:50px;}
	.select_mandatory_tools 						{width:125px; height:50px;}
	.select_outputs, .items_for_output 	{width:125px; height:100px;}
	.available_items 										{width:125px; height:150px;}
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

function item_updates(ut,ctg,aid) {
	console.log(ut);
	console.log(ctg);
	console.log(aid);

	//default je ut = "del"
	var selector_from = '#items_'.$ctg;
	var selector_to = '#available_for_'+ctg;
	if (ut = "add") {
		selector_from = '#available_for_'+ctg;
		selector_to = '#items_'.$ctg;
	};

	// there can be multiple selections
	jQuery(selector_from+'>option:selected').each( function(i,v){
		console.log(v.value);
	});

	return;

	jQuery.post('/production/item_updates',{update_type:ut, what:ctg, aid:aid})
		.always(function(){
				location.reload();
		});
};
%= end

<h1>Production ID:  <%= param 'aid' =%></h1>


<table frame="box" width='540px'>
	<tr>
		<td>Name:</td>
		<td colspan="3" align="center"> <%= text_field  'Production name' => (id=>"name") =%> </td>
		<td rowspan="3"> <%= input_tag 'update', id=>'updatebutton', type => 'button', value => 'update', onclick => "basic_updates(".(param 'aid')." )" =%> </td>
	</tr>
	<tr>
		<td>Stamina:</td>
		<td colspan="3" align="left"> <%= text_field  'stamina ' => (id=>"stamina", class => 'stamina_input') =%> </td>

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
		<tr><td colspan="4" align="center"> <%= input_tag 'createnewitem', id=>'create_new_item_button', type => 'button', value => 'Create a new item ...', onclick => '' =%> </td></tr>
		<tr><td colspan="4" align="center"> ... or manage existing: </td></tr>

<% foreach my $ctg ('inputs', 'mandatory_tools', 'enhancing_tools', 'outputs') { %>
		<tr>
			<td rowspan="1"> <%= $ctg =%>: </td>
			<td rowspan="1"> <%= select_field 'items' => [],  (id => 'items_'.$ctg, multiple => 'multiple', class => 'select_'.$ctg) =%> </td>
			<td align="left" valign="middle">
				<%= input_tag 'additem_'.$ctg, id=> 'additem_'.$ctg.'_button', type => 'button', value => '<--', onclick => "item_updates(\"add\",\"$ctg\",".(param 'aid')." )" =%>
				<br>
 				<%= input_tag 'delitem_'.$ctg, id=> 'delitem_'.$ctg.'_button', type => 'button', value => '-->', onclick => ''=%>
			</td>
			<% if ($ctg =~ /^inputs$/) { %>
				<td rowspan="2"> <%= select_field 'available_items' => $available_items,  (id => 'available_for_'.$ctg, multiple => 'multiple', class => 'available_items') =%> </td>
			<% } elsif ($ctg =~ /^enhancing_tools$/) { %>
				<td rowspan="1"> <%= select_field 'all_items' => $all_items,  (id => 'available_for_'.$ctg, multiple => 'multiple', class => 'all_items') =%> </td>
			<% } elsif ($ctg =~ /^outputs$/) { %>
				<td rowspan="1"> <%= select_field 'not_produced_items' => $not_produced_items,  (id => 'available_for_'.$ctg, multiple => 'multiple', class => 'select_outputs') =%> </td>
			<% } %>
		</tr>

<% } %>


</table>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
