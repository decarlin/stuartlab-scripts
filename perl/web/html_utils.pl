#!/usr/bin/perl

use strict;

my $font_str = "<font face=\"Arial\" size=\"2\">";

sub html_header
{
  my ($handle) = @_;

  print $handle "<html>\n";
  print $handle "<body>\n\n";
  #print $handle "<body rightmargin=\"0\" leftmargin=\"0\" bottonmargin=\"0\" topmargin=\"0\" marginwidth=\"0\" marginheight=\"0\">\n\n";
}

sub html_footer
{
  my ($handle) = @_;

  print $handle "</body>";
  print $handle "</html>\n";
}

sub html_start_table
{
  my ($handle, $table_properties) = @_;

  print $handle "<table $table_properties>\n";
}

sub html_end_table
{
  my ($handle) = @_;

  print $handle "</table>\n\n";
}

sub html_link_str
{
  my ($text, $link) = @_;

  return "<A HREF=\"$link\">$text</A>";
}

sub html_start_table_row
{
  my ($handle, $special) = @_;

  print $handle "<tr $special>\n";
}

sub html_end_table_row
{
  my ($handle) = @_;

  print $handle "<tr>\n";
}

sub html_table_row
{
  my ($handle, $str, $special) = @_;

  print $handle "  <tr><td $special>$font_str$str</td></tr>\n";
}

sub html_table_column
{
  my ($handle, $str, $special) = @_;

  print $handle "  <td $special>$font_str$str</td>\n";
}

sub html_new_line
{
  my ($handle) = @_;

  print $handle "<br>\n";
}

sub html_freestyle
{
  my ($handle, $str) = @_;

  print $handle "$str\n";
}

1
