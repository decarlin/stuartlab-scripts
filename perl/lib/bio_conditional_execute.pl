#! /usr/bin/perl

sub conditional_execute 
{
  my $exec_str = $_[0];
  my $condition = $_[1];
  my $verbose = $_[2];

  if ($condition == 1 || $condition eq "1")
  {
	if ($verbose == "1" || $verbose == 1)
	{  
	  print $exec_str . "\n";
	}
	system($exec_str);
  }
}

1
