#! /usr/bin/perl

#------------------------------------------------------------------------------------------------
# input: 
#    swissprot_infile - the name of the swissprot or EMBL format file
#    swissprot_outfile - the name of the output file
#    swissprot_min_length - the minimum length of the sequence to extract
#    swissprot_max_length - the maximum length of the sequence to extract
# output:
#    extracts the actual sequences from the file along with the id and the length of the sequence
#------------------------------------------------------------------------------------------------

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }

open(SETTINGS, "<$settings_file") or die "could not open SETTINGS";
while (<SETTINGS>)
{
	chop;
   ($id, $value) = split(/=/, $_, 2);

	$settings{$id} = $value;
}

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
$infile = $settings{"swissprot_infile"};
$outfile = $settings{"swissprot_outfile"};
$swissprot_min_length = $settings{"swissprot_min_length"};
$swissprot_max_length = $settings{"swissprot_max_length"};

open(INFILE, "<$infile") or die "Can't open ". $infile. "\n";
open(OUTFILE, ">$outfile");

$counter = 0;
$record_counter = 0;

while ($record = <INFILE>)
{
   if ($record !~ /^[\s+]$/)
   {
      $record_counter++;
      
      $line = $record;

	  $found_id = 0;
      while ($line !~ /SQ[\s][\s][\s]SEQUENCE/)
	  {
		@all_items = split(/\s+/, $line);

		if ($all_items[0] eq "ID")
		{
		  $gene = $all_items[1];
		  $found_id = 1;
		}
		
		$line = <INFILE>;
	  }

	  $record = "";
      while (TRUE)
      {
         $line = <INFILE>;
        
         if ($line =~ /[\/][\/][\n]/)
         {
            last;
         }
		 else
		 {
		   $seq_len = length($line);
		   for ($i = 0; $i < $seq_len; $i++)
		   {
			 $char = substr($line, $i, 1);
			 if ($char ne "\s" && $char ne " " && $char ne "\n")
			 {
			   $record .= $char;
			 }
		   }
		 }
      }

	  $seq_len = length($record);
	  if ($seq_len >= $swissprot_min_length && $seq_len <= $swissprot_max_length)
	  {
		print OUTFILE $gene . "\t" . $record . "\t" . length($record) . "\n";
	  }
   }
}
