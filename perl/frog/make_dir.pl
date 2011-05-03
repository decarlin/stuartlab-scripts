#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";

my $verbose = 1;

if ($ARGV[0] eq "--help")
{
  print <DATA>;
  exit(0);
}

my $dir = $ARGV[0];

if (!(-d "/fiery/u3/frog/current/RCS/$dir"))
{
  create_dir("/fiery/u3/frog/current/RCS/$dir");
  execute("chmod g+w /fiery/u3/frog/current/RCS/$dir", $verbose);
}
if (!(-d "/fiery/u3/frog/current/$dir"))
{
  create_dir("/fiery/u3/frog/current/$dir", $verbose);
  execute("chmod g+w /fiery/u3/frog/current/$dir", $verbose);
  link_file("/fiery/u3/frog/current/RCS/$dir", "/fiery/u3/frog/current/$dir/RCS");
}

if (-d "$ENV{HOME}/develop/frog")
{
  create_dir("$ENV{HOME}/develop/frog/$dir");
  link_file("/fiery/u3/frog/current/RCS/$dir", "$ENV{HOME}/develop/frog/$dir/RCS");
  link_file("/fiery/u3/frog/current/$dir", "$ENV{HOME}/develop/frog/$dir/src");
}

if (-d "$ENV{HOME}/develop/frog_linux")
{
  create_dir("$ENV{HOME}/develop/frog_linux/$dir");
  link_file("/fiery/u3/frog/current/RCS/$dir", "$ENV{HOME}/develop/frog_linux/$dir/RCS");
  link_file("/fiery/u3/frog/current/$dir", "$ENV{HOME}/develop/frog_linux/$dir/src");
}

if (-d "$ENV{HOME}/develop/frog_linux_release")
{
  create_dir("$ENV{HOME}/develop/frog_linux_release/$dir");
  link_file("/fiery/u3/frog/current/RCS/$dir", "$ENV{HOME}/develop/frog_linux_release/$dir/RCS");
  link_file("/fiery/u3/frog/current/$dir", "$ENV{HOME}/develop/frog_linux_release/$dir/src");
}

__DATA__

make_dir.pl <directory name to create relative to the frog directory>

