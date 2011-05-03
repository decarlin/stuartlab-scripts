#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/libattrib.pl";

my @files;
my $verbose           = 1;
my $map_make_common   = "$ENV{MYPERLDIR}/lib/Makefile.common";
my %defines           = %ENV;
my $map_defines_file  = &getMapDir('Root') . '/Makefile.common';
my $map_defines_lines = undef;
my $targets           = '';
my $before_exe        = '';
my $after_exe         = '';
if(-f $map_defines_file)
{
  $map_defines_lines = &getFileText($map_defines_file);
  &replaceAttribs(\%defines,&readAttribLines($map_defines_lines));
}
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
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  elsif($arg eq '-')
  {
    push(@files,'');
  }
  else
  {
    die("Invalid argument '$arg' given.");
  }
}

$#files>=0 or die("Please supply a MAP run data file.");

my @maps;
foreach my $file (@files)
{
  my $fin;
  open($fin,"cat $file | fasta2tab.pl |") or die("Could not open file '$file' for reading.");
  while(<$fin>)
  {
    s/^([^#]*)#.+$/\1/;
    if(/\S/)
    {
      my ($name,@assignments) = split("\t");
      my $parameters;
      my $template = undef;
      foreach my $assignment (@assignments)
      {
        if($assignment =~ /TEMPLATE\s*=\s*(\S.+)$/i)
          { $template = $1; }
        elsif($assignment =~ /TARGETS\s*=\s*(\S.+)$/i)
          { $targets = $1; }
        elsif($assignment =~ /BEFORE_EXE\s*=\s*(\S.+)$/i)
          { $before_exe = $1; }
        elsif($assignment =~ /AFTER_EXE\s*=\s*(\S.+)$/i)
          { $after_exe = $1; }
        else
          { $parameters .= $assignment . "\n"; }
      }
      defined($template) or die("No template found for run '$name'.");

      $template = &setAttribsRecursively($template,\%defines,1,10,1);

      if(not(-f $template))
      {
        die("Template file '$template' does not exist.");
      }

      &createRun($name,$template,$targets,$before_exe,$after_exe,$parameters,$map_defines_lines);
    }
  }
  close($fin);
}

exit(0);

sub createRun # ($name,$template,$targets,$before_exe,$after_exe,$assignments,$map_defines_lines)
{
  my ($name,$template,$targets,$before_exe,$after_exe,$assignments,$map_defines_lines) = @_;
  my $pwd         = `pwd`; chomp($pwd);
  my $run_dir     = $pwd . '/' . $name;
  my $xml_file    = $run_dir . '/data.map';

  if((-d $name) or (-f $name) or (-l $name))
  {
    print STDERR "WARNING: could not create run '$name' since a directory/file/link with that name already exists.\n";
  }
  else
  {
    mkdir($name);

    # Convert any variables in the template's name
    $template = `echo -n '$template' | bind.pl - $map_make_common`;
    chomp($template);

    # my $a = `cat $template`;
    # print STDERR "[$a]\n";

    # Write the MAP XML file that will drive the MAP run call.
    my $pipe;
    $verbose and print STDERR "Creating XML file '$xml_file'...\n";
    open($pipe,"| bind.pl $template - -xml > $xml_file");

    if(defined($map_defines_lines))
    {
      print $pipe $map_defines_lines;
    }
    print $pipe $assignments;
    close($pipe);
    $verbose and print "Done.\n";

    # Write the Makefile that will execute the MAP run call.
    &createRunMakefile($run_dir,$xml_file,$targets);

    # Link to the script they want to execute before and after a run.
    if(defined($before_exe) and $before_exe =~ /\S/)
      { system("cd $run_dir; ln -s $before_exe before.exe"); }

    if(defined($after_exe) and $after_exe =~ /\S/)
      { system("cd $run_dir; ln -s $after_exe after.exe"); }
  }
}

exit(0);

sub createRunMakefile # ($dir,$xml,$targets)
{
  my ($dir,$xml,$targets) = @_;
  my $dir_depth      = &getDepthFromMapRoot($dir);
  my $make_file_name = $dir . '/Makefile';
  my $run_mak = &getMapDir('Templates') . '/Make/run.mak';
  system("ln -s $run_mak $make_file_name");
}

sub getDepthFromMapRoot # ($dir)
{
  my $dir = shift;
  my $depth = 0;
  while(length($dir)>0)
  {
    if($dir =~ /Map[\/]*$/)
    {
      return $depth;
    }
    $depth++;
    $dir = &getPathPrefix($dir);
  }
}

__DATA__
syntax: create_maps.pl [OPTIONS] MAP_RUN_DATA1 [MAP_RUN_DATA2 ...]

MAP_RUN_DATAi - FASTA-format-like file containing specifications for MAP runs.  If equals '-'
                the script reads from standard input.

OPTIONS are:

-q: Quiet mode (default is verbose)

