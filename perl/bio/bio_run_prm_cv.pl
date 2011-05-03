#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";

#--------------------------------------------------------------------------------
# run_cv_iterations
#--------------------------------------------------------------------------------
sub run_cv_iterations
{
  my ($settings_file, $selection_file, $gene_table, $cv_start, $cv_end) = @_;

  for (my $r = $cv_start; $r <= $cv_end; $r++)
  {
    change_attribute_in_file("$settings_file", "$settings_file.cv.$r", "$gene_table", "${gene_table}_train_$r");

    open(CV_SETTINGS, ">>$settings_file.cv.$r");

    print CV_SETTINGS "gene_list=${selection_file}_train_$r\n";
    print CV_SETTINGS "test_gene_list=${selection_file}_test_$r\n";

    execute("bio_run_prm.pl $settings_file.cv.$r", 1);
    #print "bio_run_prm.pl $settings_file.cv.$r\n";
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0 && length($ARGV[1]) > 0)
{
  my %args = load_args(\@ARGV);

  run_cv_iterations($ARGV[0],
		    $ARGV[1],
		    get_arg("g",  $ARGV[0], \%args),
		    get_arg("gs", 1,        \%args),
		    get_arg("ge", 5,        \%args));
}
else
{
  print "Usage: bio_run_prm_cv.pl settings_file selection_file\n\n";
  print "      -g  <gene_table>:      the gene table name to use (default same as settings file)\n";
  print "      -gs <cv start number>: start cv number\n";
  print "      -ge <cv end number>:   end cv number\n\n";
}

1
