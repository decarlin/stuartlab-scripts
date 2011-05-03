#! /usr/bin/perl

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

sub get_sql_table_dsc
{
  my $mql = $_[0];
  my $table = $_[1];
  my $database = $_[2];
  my $verbose = $_[3];

  my $r = int(rand 1000000000);

  my @result;
  my $counter = 0;

  execute("$mql -Ne 'desc $table' $database > tmp.$r", $verbose);

  open(SQL_DSC, "<tmp.$r");
  while(<SQL_DSC>)
  {
	chop;

	my $name;
	my $dummy;

	($name, $dummy) = split(/\t/, $_, 2);

	$result[$counter++] = $name;
  }

  execute("rm tmp.$r", 1);

  return @result;
}

1
