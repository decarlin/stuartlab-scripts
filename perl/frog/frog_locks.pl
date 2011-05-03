#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";

my $name = $ENV{USER};
my $cmd = 'grep -s strict /fiery/u3/frog/current/RCS/* /fiery/u3/frog/current/RCS/*/* /fiery/u3/frog/current/RCS/*/*/* | grep -s ';
my $locks = `$cmd $name`;
my $frog_dir = "$ENV{MYPERLDIR}/lib/frog_linux";
my $rcs_dir = '/fiery/u3/frog/current/RCS';

my $report_locks    = 1;
my $report_new      = 1;
my $report_missing  = 1;
my $report_stale    = 1;
my $print_meta_info = 1;

my $clean = 0;

my @skip_dirs = ('SamplePrograms');

while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-rcs')
  {
    $rcs_dir = shift @ARGV;
  }
  elsif($arg eq '-locks')
  {
    $report_locks   = 1;
    $report_new     = 0;
    $report_missing = 0;
    $report_stale   = 0;
    $print_meta_info = 0;
  }
  elsif($arg eq '-new')
  {
    $report_locks   = 0;
    $report_new     = 1;
    $report_missing = 0;
    $report_stale   = 0;
    $print_meta_info = 0;
  }
  elsif($arg eq '-missing')
  {
    $report_locks   = 0;
    $report_new     = 0;
    $report_missing = 1;
    $report_stale   = 0;
    $print_meta_info = 0;
  }
  elsif($arg eq '-stale')
  {
    $report_locks   = 0;
    $report_new     = 0;
    $report_missing = 0;
    $report_stale   = 1;
    $print_meta_info = 0;
  }
  elsif($arg eq '-clean')
  {
    $clean = 1;
    $report_locks   = 0;
    $report_new     = 0;
    $report_missing = 0;
    $report_stale   = 0;
    $print_meta_info = 0;
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

# $locks =~ s/\/fiery\/u3\/frog\/current\/RCS\///g;
$locks =~ s/$rcs_dir[\/]*//ge;
$locks =~ s/,v:.+$//g;
$locks =~ s/,v:.+\n/\n/g;

my @locks = split(/\s+/,$locks);
my %locks;
foreach my $lock (@locks)
{
  # my $locked_file = &getPathSuffix($lock);
  $locks{$lock} = 1;
}

my @code_paths = &getAllCodeRecursively(0,($frog_dir));
my @new_code;
my @stale_code;
foreach my $path (@code_paths)
{
  if(not(&skip($path,@skip_dirs)))
  {
    my $code_file  = $path;
    $code_file =~ s/$frog_dir[\/]*//ge;
    # my $code_file = &getPathSuffix($code_path);
    # my $code_dir  = &getPathPrefix($code_path);
    if(not(exists($locks{$code_file})))
    {
      if(-w $path)
      {
        push(@new_code, $code_file);
      }
      else
      {
        push(@stale_code, $code_file);
      }
    }
    else
    {
      delete($locks{$code_file});
    }
  }
}

# Report locked files
if($report_locks)
{
  @locks = sort(@locks);
  &report(' Locked: ', 'locked', $print_meta_info, @locks);
}

# Report new files
if($report_new)
{
  @new_code = sort(@new_code);
  &report('    New: ', 'new', $print_meta_info, @new_code);
}

# Report stale files
if($report_stale)
{
  @stale_code = sort(@stale_code);
  &report('  Stale: ', 'stale', $print_meta_info, @stale_code);
}

# Report missing files
if($report_missing)
{
  my @missing = sort(keys(%locks));
  &report('Missing: ', 'missing', $print_meta_info, @missing);
}

if($clean)
{
  my $stale_code = join(" ",sort(@stale_code));
  my $cmd = "cd $frog_dir; rm -f $stale_code";
  print STDERR "Removing stale files.\n$cmd";
  system("$cmd");
  print STDERR " done.\n";
}

exit(0);

sub report
{
  my $header          = shift;
  my $type            = shift;
  my $print_meta_info = shift;
  my @files   = @_;
  if($#files>=0)
  {
    foreach my $file (@files)
    {
      my $print = $print_meta_info ? ($header . "$file\n") : "$file\n";
      print STDOUT $print;
    }
  }
  else
    { $print_meta_info and print STDOUT "No $type files.\n"; } 
}

sub skip # ($path,@dirs)
{
  my $path = shift;
  my @dirs = @_;
  foreach my $dir (@dirs)
  {
    if($path =~ /$dir/)
    {
      return 1;
    }
  }
  return 0;
}

__DATA__
syntax: frog_locks.pl [OPTIONS]

Reports which files are locked under frog.

OPTIONS are:

-locks:   Only report locks
-missing: Only report missing files
-new:     Only report new files.
-stale:   Only report stale files.
