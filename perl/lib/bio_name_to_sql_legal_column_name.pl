#! /usr/bin/perl

sub name_to_sql_legal_column_name
{
  my $name = $_[0];

  $name =~ s/-/_/g;
  $name =~ s/[\,]/_/g;
  $name =~ s/[\.]/_/g;
  $name =~ s/[\(]/_/g;
  $name =~ s/[\)]/_/g;
  $name =~ s/[\s]/_/g;
  $name =~ s/[\']/_/g;
  $name =~ s/[\"]/_/g;
  $name =~ s/[\[]/_/g;
  $name =~ s/[\]]/_/g;
  $name =~ s/[\:]/_/g;
  $name =~ s/[\/]/_/g;
  $name =~ s/[\<]/_/g;
  $name =~ s/[\>]/_/g;
  $name =~ s/[\+]//g;
  $name =~ s/[\`]/_/g;

  while ($name =~ /__/)
  {
	$name =~ s/__/_/g;
  }

  if (substr($name, length($name) - 1, length($name) - 1) eq "_")
  { 
	$name = substr($name, 0, length($name) - 1); 
  }

  if (length($name) > 55)
  {
	$name = substr($name, 0, 54);
  }

  return $name;
}

1
