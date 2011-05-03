#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";

my $extra_options = '';
my @dirs;
my $verbose = 1;
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

  elsif(-d $arg)
  {
    push(@dirs,$arg);
  }

  else
  {
    $extra_options .= " $arg";
  }
}

my %eval_dirs;
foreach my $dir (@dirs)
{
  my @files = &getAllFiles($dir);
  my @eval_files;

  # Just keep files that end in .eval
  foreach my $file (@files)
  {
    $file = &getPathSuffix($file);
    if($file =~ /\.eval$/)
    {
      if(not(exists($eval_dirs{$file})))
      {
        $eval_dirs{$file} = $dir;
      }
      else
      {
        $eval_dirs{$file} .= "\t" . $dir;
      }
    }
  }
}

foreach my $file (sort(keys(%eval_dirs)))
{
  @dirs = split("\t",$eval_dirs{$file});

  if($#dirs>=1)
  {
    my $paths = '';
    foreach my $dir (@dirs)
    {
      $paths .= ' ' . $dir . '/' . $file;
    }
    
    my $base = '_' . &remPathExt($file);
    $verbose and print STDERR "Combining $paths ...";
    `combine_annot_eval.pl -suffix $base -autofile $extra_options $paths`;
    $verbose and print STDERR " done.\n";
  }
}


exit(0);

__DATA__
syntax: combine_annot_eval_dirs.pl [OPTIONS] FILE1 [FILE2...]

-q: Quiet mode.
