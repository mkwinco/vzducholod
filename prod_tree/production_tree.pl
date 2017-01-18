#!/usr/bin/env perl


use Data::Dumper;
$Data::Dumper::Terse = 'true';
$Data::Dumper::Sortkeys = 'true';
$Data::Dumper::Sortkeys = sub { [reverse sort keys %{$_[0]}] };


use Mojolicious::Lite;
use Mojo::Pg;
# protocol://user:pass@host/database
my $pg = Mojo::Pg->new('postgresql://postgres:postgres@localhost/econmod_v03');


get '/production_tree.api' => sub {
	my $c = shift;
	
	my $select = $pg->db->query('SELECT * FROM rules.all_productions ORDER BY aux_production_level ASC;');
	$select = $select->expand;
	
	my @out = ();
	while (my $next = $select->hash) {push(@out,$next);}
	
	say Dumper(\@out);
	
	$c->render(json => {activities => \@out});
	
};


get '/production_tree' => sub {
	my $c = shift;

	$c->render(template => 'overview');
	
};



app->start;
__DATA__

@@ overview.html.ep
% layout 'default';
% title 'Production tree';

% content 
%= javascript "//code.jquery.com/jquery-2.1.1.js"
%= javascript "d3.v3.js"

%= javascript "production_tree.js"

%= javascript begin
	refresh();
% end

<h1>Production tree overview</h1>




@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
