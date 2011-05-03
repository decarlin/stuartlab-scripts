#! /usr/bin/perl

require "$ENV{MYPERLDIR}/lib/bio_system.pl";

#--------------------------------------------------------------------------------
# load_file_to_memory
#--------------------------------------------------------------------------------
sub load_file_to_memory
{
  my $file_name = $_[0];
  my $verbose = $_[1];

  my @result;

  if (file_exists($file_name))
  {
	 open(FILE_DSC, "<$file_name") or die "could not open $file_name\n";
	 #$line = <FILE_DSC>;

	 my $counter = 0;
	 while(<FILE_DSC>)
	 {
		chop;
	
		my @data = split(/\t/, $_);

		for (my $i = 0; $i < @data; $i++) { $result[$counter][$i] = $data[$i];	}
		$counter++;
	 }
  }

  return @result;
}

#--------------------------------------------------------------------------------
# load_vec_to_memory
#--------------------------------------------------------------------------------
sub load_vec_to_memory
{
  my ($file_name, $column, $start_row) = @_;

  if (length($column) == 0) { $column = 0; }
  if (length($start_row) == 0) { $start_row = 0; }

  my @result;

  if (file_exists($file_name))
  {
	 open(FILE_DSC, "<$file_name") or die "could not open $file_name\n";

	 for (my $i = 0; $i < $start_row; $i++) { my $skip_row = <FILE_DSC>; }

	 my $counter = 0;
	 while(<FILE_DSC>)
	 {
		chop;
	
		my @data = split(/\t/, $_);

		$result[$counter] = $data[$column];
		$counter++;
	 }
  }

  return @result;
}

1
