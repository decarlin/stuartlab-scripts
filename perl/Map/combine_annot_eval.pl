#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap_eval.pl";

use strict;

if($#ARGV==-1)
{
  print STDOUT <DATA>;
  exit(0);
}

my @bgcolors =
(
  'red', 'blue', 'green', 'yellow', 'purple', 'orange', 'pink', 'gray'
);
my @fgcolors =
(
  'white', 'white', 'white', 'black', 'white', 'black', 'black', 'black'
);
my $next_html_color = 0;

my $verbose=1;
my @files;
my $html = 0;
my $autofile = 0;
my $suffix = '';
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-html')
  {
    $html = 1;
  }
  elsif($arg eq '-autofile')
  {
    $autofile = 1;
  }
  elsif($arg eq '-suffix')
  {
    $suffix = shift @ARGV;
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  else
  {
    die("Base argument '$arg' given.");
  }
}

my $line=0;
my $global_counts = 0;
my $dataset_counts = 0;
my $cluster_num = 0;
my $cluster_size = 0;
my %hits;
my %annot_info;
my %run_colors;

my $fout = \*STDOUT;

my $fout_name = 'combined';
foreach my $file (@files)
{
  open(FILE,$file) or die("Could not open file '$file' for reading.");
  my ($run,$organism,$annot_group) = &parseMapEvalAnnotPath($file);
  # print STDERR "[$run] [$organism] [$annot_group]\n";

  if($autofile)
  {
    $fout_name .= '_' . $run;
  }

  if($html)
  {
    # Remembner a color for this run.
    if(not(exists($run_colors{$run})))
    {
      $run_colors{$run} = $next_html_color;
      $next_html_color = ($next_html_color+1) % ($#bgcolors+1);
    }
  }

  length($run)>0 or 
    die("Could not extract a MAP formatted run name from file '$file'.");

  length($organism)>0 or 
    die("Could not extract a MAP organism name from file '$file'.");

  length($annot_group)>0 or 
    die("Could not extract a MAP annotation group name from file '$file'.");

  while(<FILE>)
  {
    $line++;
    if(/\S/ and not(/^\s*#/))
    {
      chop;

      if(/^\[Dataset Counts=(\d+)\] \[Global Counts=(\d+)\]/)
      {
        $dataset_counts = $1;
        $global_counts  = $2;
      }

      elsif(/^Cluster (\d+) \[Counts=(\d+)\]/)
      {
        $cluster_num  = $1;
        $cluster_size = $2;
      }
      else
      {
        my ($annot,$pv,$overlaps,$num_data,$num_global) = 
	  &getMapEvalAnnotStats($_);
        length($annot)>0 or die("Unrecognized text on line $line in file '$file'.");

	my $annot_name = $organism . '@' . $annot_group . '@' . $annot;
	# print STDERR "[$annot_name]\n";

	my $cluster = $run . '@' . 'cluster_' . $cluster_num;

	if(not(exists($hits{$annot_name})))
	{
	  my @hitting_runs;
	  push(@hitting_runs, "$cluster\t$pv\t$overlaps\t$cluster_size");
	  $hits{$annot_name} = \@hitting_runs;
	  $annot_info{$annot_name} = "$num_data\t$num_global";
	}
	else
	{
	  push(@{$hits{$annot_name}},
	       "$cluster\t$pv\t$overlaps\t$cluster_size");
	}
      }
    }
  }
  close(FILE);
}

if($autofile)
{
  $fout_name .= $suffix;
  $fout_name .= $html ? '.html' : '.tab';
  open($fout,">$fout_name") or die("Could not open output file '$fout_name'.");
}

# For each annotation the runs by increasing p-value so the run with the
# most significant hit is first
my $i=0;
my @hit_list;
my $max_hitting_runs = 0;
foreach my $annot_name (keys(%hits))
{
  my @hitting_runs = @{$hits{$annot_name}};
  @hitting_runs = sort by_run_pvalue @hitting_runs;
  if($max_hitting_runs < $#hitting_runs+1)
    { $max_hitting_runs = $#hitting_runs+1; }
  # $hits{$annot_name} = \@hitting_runs;
  @hitting_runs = ($annot_name, @hitting_runs);
  $hit_list[$i] = \@hitting_runs;
  $i++;
}

# Now sort each annotation by their best p-values
@hit_list = sort by_annot_pvalue @hit_list;

# Print out the results
if($html)
{
  print $fout
        "<html>\n<body>\n",
        "<table border=true>\n",
	"  <tr>\n",
	"    <td>Annotation Group</td>\n",
	"    <td>Annotation Data Size</td>\n",
	"    <td>Annotation Global Size</td>\n",
}
else
{
  print $fout "Annotation Group\tAnnotation Data Size\tAnnotation Global Size";
}
for($i=1; $i<=$max_hitting_runs; $i++)
{
  if($html)
  {
    print $fout
          "    <td>Run\@Cluster [$i]</td>\n",
          "    <td>p-value [$i]</td>\n",
	  "    <td>Overlaps [$i]</td>\n", 
          "    <td>Cluster Size [$i]</td>\n";
  }
  else
  {
    print $fout
          "\tRun\@Cluster [$i]\tp-value [$i]\tOverlaps [$i]", 
          "\tCluster Size [$i]";
  }
}
if($html)
{
  print $fout "  </tr>\n";
}
else
{
  print $fout "\n";
}
for($i=0; $i<=$#hit_list; $i++)
{
  my @hitting_runs = @{$hit_list[$i]};
  my $annot_name = shift @hitting_runs;
  my $info = $annot_info{$annot_name};

  if($html)
  {
    print $fout
          "  <tr>\n",
          "    <td>$annot_name</td>\n";

    my @info = split("\t",$info);
    print $fout
          "    <td>$info[0]</td>\n",
	  "    <td>$info[1]</td>\n";

    for(my $j=0; $j<=$#hitting_runs; $j++)
    {
      my @run_entries = split("\t",$hitting_runs[$j]);
      my $cluster = $run_entries[0];
      my ($run,$cluster_num) = split('@',$cluster);
      my $bgcolor = exists($run_colors{$run}) ? $bgcolors[$run_colors{$run}] : 'white';
      my $fgcolor = exists($run_colors{$run}) ? $fgcolors[$run_colors{$run}] : 'black';
      foreach my $run_entry (@run_entries)
      {
        print $fout "    <td bgcolor=\"$bgcolor\">",
	            "<font color=\"$fgcolor\">$run_entry",
		    "</font></td>\n";
      }
    }
    print $fout "  </tr>\n";
  }
  else
  {
    print $fout "$annot_name\t$info\t", join("\t",@hitting_runs), "\n";
  }
}

if($html)
{
  print $fout
        "</table>\n",
        "</body>\n",
	"</html>\n";
}

exit(0);

##-----------------------------------------------------------------------------------------------
##
##-----------------------------------------------------------------------------------------------
sub by_run_pvalue
{
  my ($cluster1,$pvalue1,$overlaps1,$cluster_size1) =  split("\t",$a);
  my ($cluster2,$pvalue2,$overlaps2,$cluster_size2) =  split("\t",$b);
  return ($pvalue1 <=> $pvalue2);
}

##-----------------------------------------------------------------------------------------------
##
##-----------------------------------------------------------------------------------------------
sub by_annot_pvalue
{
  my @hits1 = @{$a};
  my @hits2 = @{$b};
  my ($cluster1,$pvalue1,$overlaps1,$cluster_size1) =  split("\t", $hits1[1]);
  my ($cluster2,$pvalue2,$overlaps2,$cluster_size2) =  split("\t", $hits2[1]);
  return ($pvalue1 <=> $pvalue2);
}

__DATA__

syntax: combine_annot_eval.pl [OPTIONS] FILE1 [FILE2 ...]

FILEi is a MAP Annotation evaluation file.

OPTIONS are:

-q: Quiet mode -- turn verbosity off (default verbose)
-html: produce colored HTML output
-autofile: Do not print to standard output, instead create a file that is the concatentation
       of all the input file names with a .tab extension (.html if -html option supplied).
-suffix SUFFIX: add SUFFIX to the autofile name.


