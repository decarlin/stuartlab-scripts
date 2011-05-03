#! /usr/bin/perl

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

sub get_sql_database_dsc
{
  my $mql = $_[0];
  my $database = $_[1];
  my $verbose = $_[2];

  my $r = int(rand 1000000000);

  my @result;
  my $counter = 0;

  execute("$mql -Ne 'show tables' $database > tmp.$r", $verbose);

  open(SQL_DSC, "<tmp.$r");
  while(<SQL_DSC>)
  {
	chop;

	$result[$counter++] = $_;
  }

  execute("rm tmp.$r", 1);

  return @result;
}

1
