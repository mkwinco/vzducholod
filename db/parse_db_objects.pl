# ***************
# This should take pg_dump and separate Table and Function definitions
# and save them into separate files
# Each file will be placed into a directory that corresponds the schema of the object
# What was not matched will be prited into STDOUT
# ***************
#!/usr/bin/perl -w

use strict;
use warnings;
use v5.22;

use Data::Dumper;
$Data::Dumper::Terse = 'true';
$Data::Dumper::Sortkeys = 'true';
$Data::Dumper::Sortkeys = sub { [reverse sort keys %{$_[0]}] };

my $in=$ARGV[0];
my $fh;
# open($fh, '<:encoding(UTF-8)', $in) or die "Could not open file '$in' $!";

# this variables will remember the schema/object that was last defined in the dump file
my $active_schema='.';
my $active_object='init.definition';

# structure listing all active schemas the script detected
my $schemas = ();
# structure of objects with their definitions
my $objects = ();

LINE: while (my $row = <STDIN>) {

  # write the output to STDOUT as well;
  print $row;

  # parsing for schema definition
  if ($row =~ /^-- Name: (\w+); Type: SCHEMA;/ || $row =~ /^CREATE SCHEMA (\w+);/) {
    $active_schema=$1;
    $schemas->{$active_schema} = $row;
    next LINE;
  }

  # parsing for function definition
  elsif ($row =~ /^-- Name: (\w+)\(.*\); Type: FUNCTION; Schema: (\w+);/) {
    $active_object=qq(function.$1);
    $active_schema=$2;
  }
  #elsif ($row =~ /^CREATE FUNCTION (\w+)\(/) {$active_object=qq(function.$1);}

  # parsing for table definitions
  elsif ($row =~ /^-- Name: (\w+); Type: TABLE; Schema: (\w+); Owner:/) {
    $active_object=qq(table.$1);
    $active_schema=$2;
  }
  #elsif ($row =~ /^CREATE TABLE (\w+) \(/) {$active_object=qq(table.$1);}
  elsif ($row =~ /^-- Name: (\w+) \w+; Type: ((FK |)CONSTRAINT|TRIGGER); Schema: (\w+); Owner:/) {
    $active_object=qq(table.$1);
    $active_schema=$4;
  }
  #elsif ($row =~ /ALTER TABLE (ONLY |)(\w+)/) {$active_object=qq(table.$2);}
  #elsif ($row =~ /CREATE TRIGGER \w+ (BEFORE|AFTER) (INSERT|DELETE|UPDATE) ON (\w+)/) {$active_object=qq(table.$3);}


  # parsing for views
  elsif ($row =~ /^-- Name: (\w+); Type: VIEW; Schema: (\w+); Owner:/) {
    $active_object=qq(view.$1);
    $active_schema=$2;
  }
  #elsif ($row =~ /^CREATE VIEW (\w+) AS/) {$active_object=qq(view.$1);}

  # parsing for other objects
  elsif ($row =~ /^-- Name: (\w+); Type: SEQUENCE; Schema: (\w+);/) {
    # $active_object=qq(schema.$1);
    $active_object="default";
    $active_schema=$2;
  }
  elsif ($row =~ /^SET /) {
    $active_schema='.';
    $active_object='init.definition';
  } else {};

  my $key = $active_schema.'::'.$active_object;
  $objects->{$key} .= $row ;# unless ($active_object eq "default");

};
# close the input filehandle
#close $fh;

# print Dumper($schemas);
# create all directories for schemas - unless they exists already
foreach (keys %{$schemas}) {
  unless (-d $_) { mkdir $_;}
};


#print Dumper(keys %{$objects}); #exit;
#print Dumper($objects); exit;

# and now create and print definitions for objects
foreach (keys %{$objects}) {
  my $file=''; my $dir='';

  if (/^(\w+|\.)::(\w+\.\w+)$/) {$dir=$1;$file=$2;}
  else {next;};

  #print "DEBUG: dir=[$dir] :: filename=[$file]\n";

  # and finally write the file down
  open $fh ,">$dir/$file.sql" or die "Error opening $dir/$file.sql";
  print $fh $objects->{$_};
  close $fh;
};
