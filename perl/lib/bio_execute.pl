#! /usr/bin/perl

sub execute 
{
  my $exec_str = $_[0];
  my $verbose = $_[1];

  if ($verbose == "1" || $verbose == 1)
  {
    print STDERR $exec_str . "\n";
  }

  system($exec_str);
}

1
