#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/file.pl";
require "$ENV{MYPERLDIR}/lib/smd.pl";

# Files containing information about SMD publications.  This includes which
# experiment sets (and thus which experiments) are logically grouped with
# the publication.
my @files;
my $tmp_dir = undef;
my $overwrite = 0;
my $full = 0;
my $only_organism = '';
my $overwrite_averages = 0;

while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-f')
  {
    $overwrite = 1;
  }
  elsif($arg eq '-a')
  {
    $overwrite_averages = 1;
  }
  elsif($arg eq '-full')
  {
    $full = 1;
  }
  elsif($arg eq '-org')
  {
    $only_organism = &getMapOrganismName(shift @ARGV);
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  elsif(not(defined($tmp_dir)))
  {
    $tmp_dir = $arg;
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

defined($tmp_dir) or die("Please supply a temporary directory name.");
system("mkdir -p $tmp_dir");
(-d $tmp_dir) or die("Unable to create directory $tmp_dir.");

# Loop through all the publication*.meta files.
for(my $i=0; $i<=$#files; $i++)
{
  my $file = $files[$i];
  my $dir  = &getPathPrefix($file);
  # print STDERR "[$file]\n";
  my $publication = (&getMapPublicationNameFromSmdPublicationMeta($file))[0];
  # print STDERR "{$publication}\n";
  my @expt_sets        = &getSmdExptSetsFromPublicationMeta($file);
  # my @expt_ids         = &getSmdExptIdsFromPublicationMeta($file);

  my ($organism)   = &getMapOrganismNamesFromSmdPublicationMeta(($file));
  my $map_organism = &getMapOrganismName($organism);
  my $data_source  = &getSmdDataSource($map_organism);
  my $pub_dir      = "$tmp_dir/$organism/$publication";

  if(length($map_organism)>0 and (length($only_organism)==0 or ($only_organism eq $map_organism)))
  {
    # $organism =~ s/(\s)\s*/_/g;
    print "$publication [$map_organism] --> ";
    system("mkdir -p $pub_dir");
    my $changed = $full ? 1 : 0;
    foreach my $expt_set (@expt_sets)
    {
      my $file_exptset_meta = "$dir/exptset_$expt_set.meta";
      my @exptids = &getSmdExptIdsFromExptSetMeta($file_exptset_meta);

      my $n = $#exptids+1;
      foreach my $exptid (@exptids)
      {
        my $file_expt  = "$dir/$exptid.xls.gz";
        my $tmp_file   = "$pub_dir/$exptid" . '.tab';
        my $tmp_ratios = "$pub_dir/$exptid" . '.ratios';
        my $expt_name  = &getExptNameFromSmdXlsGzip($file_expt);
        $expt_name     = $publication . '_' . $expt_name;

        my @file_stats = not(-f $tmp_file) ? undef : stat($tmp_file);
        my $file_size  = not(-f $tmp_file) ? 0 : $file_stats[12];
        if($file_size == 0)
        {
          $changed = 1;
          my $database = ($map_organism =~ /human/i) ? 'LocusLink' : 'Sgd'; 
          print STDERR "Extracting from '$file_expt' (experiment = '$expt_name') and writing to '$tmp_file'...";
          my $cmd = "zcat $file_expt | " .
                    "strings | " .
                    "grep -v '^!' | " .
                    "projection.pl -f LOG_RAT2N_MEAN > $tmp_ratios; " .

                    "zcat $file_expt | " .
                    "strings | " .
                    "grep -v '^!' | " .
                    "cut -f 1-7 | " .
                    "tr a-z A-Z | " .
                    "paste - $tmp_ratios | " .
                    'perl -ne \'s/(\\b)NA(\\b)/\\1\\2/g; print;\' | ' .
                    "$tmp_file; " .
                    "rm -f $tmp_ratios;";

          system("$cmd");

          print STDERR " done.\n";
        }
        else
        {
          print STDERR "Skipping '$file_expt' (experiment = '$expt_name') since non-empty '$tmp_file' exists.\n";
        }

        my $ave_file = $tmp_file . '.ave';
        @file_stats = not(-f $ave_file) ? undef : stat($ave_file);
        $file_size  = not(-f $ave_file) ? 0 : $file_stats[12];
        if($file_size == 0 or $changed or $overwrite_averages)
        {
          $changed = 1;
          my $func = 'average';
          my $pipes  = 'cat';
          my $errors  = "$pub_dir/error.log";
          if($map_organism eq 'Human')
                { $pipes = "cut -f 3,8"; }
          else
              { $pipes = 'cut -f 2,8'; }

            my $cmd = "rm -f $errors; " .
                    "cat $tmp_file | " .
                    "body.pl 2 -1 | " .
                    "$pipes | " .
                    "map_keys.pl $map_organism $data_source -log $errors | " .
                    "sort -n -k 1,1 | " .
                    "combine.pl -func $func | " .
                    "cap.pl ORF,'$expt_name' > " .
                    "$ave_file";

          print STDERR "Combining duplicate values into $func(s) in '$tmp_file'...";
          system("$cmd");
          print STDERR " done.\n";
        }
        else
        {
          print STDERR "*NOT* combining duplicates since combined file '$ave_file' exists.\n";
        }
      }
      # system("rm -f $tmp_dir/*");
      # print "]";
    }

    # Join all the experiments together.
    my $joined_file  = "$pub_dir/data.tab";
    my @file_stats = not(-f $joined_file) ? undef : stat($joined_file);
    my $file_size  = not(-f $joined_file) ? 0 : $file_stats[12];
    if($file_size == 0 or $changed)
    {
      # my $cmd = "join_multi_sorted.pl -u $pub_dir/*.tab.ave > $joined_file";
      my $cmd = "join_multi.pl $pub_dir/*.tab.ave > $joined_file";
      print STDERR "Joining all the data files under $organism/$publication...";
      system("$cmd");
      print STDERR " done.\n";
    }
    else
    {
      print STDERR "*NOT* joining data for $organism/$publication since non-zero '$joined_file' exists.\n";
    }

    # Move the data set to its appropriate MAP data directory.  If the
    # destination file already exists, just print a warning instead of moving it.
    if(length($map_organism)>0 and length($data_source)>0)
    {
      my $dest_dir  = &getMapDir('Data') . "/Expression/$map_organism/$publication";
      my $dest_file = $dest_dir . '/data.tab';

      my @file_stats = not(-f $dest_file) ? undef : stat($dest_file);
      my $file_size  = not(-f $dest_file) ? 0 : $file_stats[12];
      if($file_size == 0 or $overwrite)
      {
        print STDERR "Standardizing $publication data and moving to MAP directory $dest_dir...";
        my $cmd = "mkdir -p $dest_dir; " .
                  "cp $joined_file $dest_file; ";
        # my $cmd = "mkdir -p $dest_dir; " .
        #           "cat $joined_file | " .
        #           "sed 's/Gene/0000000ORF/' | " .
        #           "map_keys.pl -h 1 $map_organism $data_source -log $dest_dir/error.log | " .
        #          "sort -n -k 1,1 | " .
        #          "sed 's/0000000ORF/ORF/' > $dest_file; ";
        system($cmd);
        print STDERR "\n";
      }
      else
      {
        print STDERR "Expression data for $publication already exists, *NOT* overwriting.\n";
      }
    }
  }
  print "\n";
}
# system("rm -rf $tmp_dir");

exit(0);

__DATA__
syntax: parse_smd_xls.pl DIR PUB_META1 [PUB_META2 ...]

DIR is the directory where result files are written.

OPTIONS are:

-f: force overwriting of pre-existing expression data (of course this is dangerous!)

-full: force recomputation of all derived data from SMD even if pre-computed files exist.

