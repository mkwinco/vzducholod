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

	# create arrays for selections
	my $items = ();
	foreach my $ctg ('inputs','outputs') {
		foreach (keys %{$prod->{$ctg}}) {
			for (my $i=0; $i<$prod->{$ctg}->{$_}; $i++ ) {push(@{$items->{$ctg}},$_)};
		};
	};
	foreach (keys %{$prod->{'tools'}}) {
		if ($prod->{'tools'}->{$_}) {push(@{$items->{'mandatory_tools'}},$_)} else {push(@{$items->{'enhancing_tools'}},$_)};
	}
	say Dumper($items);

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

	$c->render(template => 'production_edit', prod => $prod, items=>$items, structures => $structures, structurelevels => $sl, available_items => $available_items, not_produced_items => $not_produced_items, all_items =>  \@all_items, arrows => {'add' => '<--', 'del' => '-->'} );
};


post '/production/basic_updates' => sub {
	my $c = shift;

	say Dumper($c->req->params->to_hash);

	my $prod = $pg->db->query(qq(UPDATE rules.type_activity SET type_structureid=?, min_struct_level=?, type_activity_name=?, stamina=? WHERE type_activityid=?;),$c->param('values[type_structureid]'),$c->param('values[min_struct_level]'),$c->param('values[type_activity_name]'),$c->param('values[stamina]'),$c->param('aid'));

	$c->render(json => {return_value => 0});
};


post '/production/item_updates' => sub {
	my $c = shift;

	say Dumper($c->req->params->to_hash);

	# tools does not work yet

	my $is_item_input = qq();
	$is_item_input =  qq(TRUE) if ($c->param('what') eq 'inputs');
	$is_item_input =  qq(FALSE) if ($c->param('what') eq 'outputs');

	my $query = qq();
	$query = qq(INSERT INTO rules.type_item_in_activity(type_activityid, type_itemid, is_item_input, item_count) VALUES (?,?,?,?);) if ($c->param('update_type') eq "add");
	$query = qq(UPDATE rules.type_item_in_activity SET item_count=item_count-1 WHERE type_activityid=? AND type_itemid=? AND is_item_input=? AND 1=?;) if ($c->param('update_type') eq "del");


	my $update = $pg->db->query($query,$c->param('aid'),$c->param('item'),$is_item_input,1);

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
function basic_updates(aid) {
  //send post data and reload ALWAYS (not only when done)
  console.log(aid);
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
	console.log(ctg)

	var source = {add:"#available_for_", del:"#items_"}

	// there can be multiple selections, so let's do them in array
	jQuery(source[ut]+ctg+'>option:selected').each( function(i,v){
		console.log(v.value);

		jQuery.post('/production/item_updates',{update_type:ut, what:ctg, item:v.value, aid:aid})
			.always(function(){
				jQuery(source[ut]+ctg).find(jQuery('option')).attr('selected',false); //deselecting
				location.reload();
			});

	});

};
%= end

% content
<h1>Production ID:  <%= param 'aid' =%></h1>


<table frame="box" width='540px'>
	<tr>
		<td>Name:</td>
		<td colspan="3" align="center"> <%= text_field  'Production name' => $prod->{'activity'}, id=>"name"   =%> </td>
		<td rowspan="3"> <%= input_tag 'update', id=>'updatebutton', type => 'button', value => 'update', onclick => "basic_updates(".(param 'aid').")" =%> </td>
	</tr>
	<tr>
		<td>Stamina:</td>
		<td colspan="3" align="left"> <%= text_field  'stamina ' => $prod->{'stamina'}, id=>"stamina", class => 'stamina_input' =%> </td>

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
			<td rowspan="1"> <%= select_field 'items' => $items->{$ctg},  (id => 'items_'.$ctg, multiple => 'multiple', class => 'select_'.$ctg) =%> </td>
			<td align="left" valign="middle">
				<% foreach my $a ('add', 'del') { %>
						<%= input_tag $a.'_item_'.$ctg, id=> $a.'_item_'.$ctg.'_button', type => 'button', value => $arrows->{$a}, onclick => qq(item_updates\('$a','$ctg',).(param 'aid').qq(\)) =%>
				<br>
				<% } %>
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
