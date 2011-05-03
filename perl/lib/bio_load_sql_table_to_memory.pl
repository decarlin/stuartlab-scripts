#! /usr/bin/perl

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

sub load_sql_table_to_memory
{
  my $mql = $_[0];
  my $table = $_[1];
  my $database = $_[2];
  my $verbose = $_[3];

  my $r = int(rand 1000000000);

  my @result;
  my $counter = 0;

  execute("$mql -Ne 'select * from $table' $database > tmp.$r", $verbose);

  open(SQL_DATA, "<tmp.$r");
  while(<SQL_DATA>)
  {
	chop;

	my @data;
	my $i;

	@data = split(/\t/, $_);

	for ($i = 0; $i < @data; $i++)
	{
	  $result[$counter][$i] = $data[$i];
	}

	$counter++;
  }

  execute("rm tmp.$r", 1);

  return @result;
}

1
