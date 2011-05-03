#! /usr/bin/perl

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

#-------------------------------------------------------------------------------------------------------------------------------
# Functions:
# ----------
# void    create_dir (dir_name)
#
# boolean file_exists (file_name)
#
# void    delete_file (file_name)
#
# void    link_file (source_file, dest_file)
#
# void    copy_file (source_file, dest_file)
#
# void    move_file (source_file, dest_file)
#
# void    append_to_file (source_file, append_str)
#
# void    change_attribute_in_file (source_file, dest_file, original_str, new_str) // source can be the same as dest
#
# int     get_num_lines_in_file (file_name)
#
# int     get_num_columns_in_file (file_name)
#
#-------------------------------------------------------------------------------------------------------------------------------

sub create_dir
{
  my $dir = $_[0];
  if (!(-d $dir)) { execute("mkdir $dir"); }
}

sub file_exists
{
  if (-e $_[0]) { return 1; }
  else { return 0; }
}

sub delete_file
{
  if (file_exists($_[0]))
  {
	 execute("rm $_[0]");
  }
}

sub copy_file
{
  if (file_exists($_[0]))
  {
	 execute("cp $_[0] $_[1]");
  }
}

sub link_file
{
  if (!(-l $_[1]))
  {
    execute("ln -s $_[0] $_[1]");
  }
}

sub move_file
{
  if (file_exists($_[0]))
  {
	 execute("mv $_[0] $_[1]");
  }
}

sub append_to_file
{
  execute("echo \"$_[1]\" >> $_[0]");
}

sub change_attribute_in_file
{
  my $from_file = $_[0];
  my $to_file = $_[1];
  my $org_attribute = $_[2];
  my $new_attribute = $_[3];
  my $verbose = $_[4];

  my $r = int(rand 1000000000);

  execute("sed 's/$org_attribute/$new_attribute/g' $from_file > tmp.$r; mv tmp.$r $to_file", $verbose);
}

sub get_num_lines_in_file
{
  my $r = int(rand 1000000000);

  execute("wc $_[0] > tmp.$r");

  open(TMP, "<tmp.$r");
  my $line = <TMP>;
  chop $line;

  $line =~ /([^\s]+)/;

  delete_file("tmp.$r");

  return $1;
}

sub get_num_columns_in_file
{
  my $r = int(rand 1000000000);

  open(TMP, "<$_[0]") or die "Could not find columns in non-existent file $_[0]\n";
  my $line = <TMP>;
  chop $line;
  my @row = split(/\t/, $line);

  return @row;
}

1
