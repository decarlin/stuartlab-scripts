#! /usr/bin/perl

sub get_file_names_for_dir
{
  my $pattern = $_[0];
  my $verbose = $_[1];

  my @result;

  open(FILES, "find $pattern|");

  my $counter = 0;

  while(<FILES>)
  {
    chop;

    $result[$counter] = $_;
    #print "result[$counter]=$result[$counter]\n";
    $counter++;
  }

  return @result;
}

1
