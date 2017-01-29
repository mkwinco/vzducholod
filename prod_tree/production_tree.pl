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

	my $items = $pg->db->query('SELECT type_itemid FROM rules.type_item;');
	$items = $items->arrays->to_array;
	say Dumper($items);


# roman letters for structure levels
	my $sl = [['I',1],['II',2]];

	$c->render(template => 'production_edit', structures => $structures, structurelevels => $sl, items => $items);
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

			for (var ctg in ['inputs']) {
				console.log(ctg);
				for (var key in p[ctg]){
					jQuery('#items_inputs').append('<option value='+key+'>'+key+'</option>');
				};
			};


		}
	)
% end

<h1>Production ID:  <%= param 'aid' =%></h1>
Name:
%= text_field  'Production name' => (id=>"name")
%= input_tag 'rename', id=>'renamebutton', type => 'button', value => 'rename', onclick => ''
<br>
Stamina:
%= text_field  'Stamina needed' => (id=>"stamina")
%= input_tag 'updatestamina', id=>'updatestaminabutton', type => 'button', value => 'update stamina', onclick => ''
<br>
Structure:
%= select_field structure => $structures,  (id => 'structures')
%= select_field structurelevel => $structurelevels,  (id => 'structurelevel')
%= input_tag 'updatestructure', id=>'updatestructurebutton', type => 'button', value => 'update structure', onclick => 'console.dir({sid:jQuery("#structures>option:selected").val(),level:jQuery("#structurelevel>option:selected").val()})'

<table>
<% foreach my $ctg ('inputs', 'tools', 'outputs') { %>
		<tr>
			<td rowspan="2"> <%= $ctg =%>: </td>
			<td rowspan="2"> <%= select_field items => [],  (id => 'items_'.$ctg, multiple => 'multiple') =%> </td>
			<td> <%= input_tag 'additem_'+$ctg, id=> 'additem_'+$ctg+'button', type => 'button', value => '<--', onclick => '' =%> </td>
			<% if ($ctg =~ /^inputs$/) { %>
				<td rowspan="6"> <%= select_field available_items => $items,  (id => 'available_items', multiple => 'multiple') =%> </td>
			<% } %>
		</tr>
		<tr>
			<td> <%= input_tag 'delitem_'+$ctg, id=> 'delitem_'+$ctg+'_button', type => 'button', value => '-->', onclick => ''=%> </td>
		</tr>
<% } %>

</table>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
