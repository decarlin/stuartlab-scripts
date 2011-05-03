#! /usr/bin/perl

#---------------------------------------------------------------------------
# trim leading spaces
#---------------------------------------------------------------------------
sub trim_leading_spaces
{
  my $word = $_[0];

  if ($word =~ /^[\s]+(.*)/) { return $1; }
  else { return $word; }
}

#---------------------------------------------------------------------------
# count leading spaces
#---------------------------------------------------------------------------
sub count_leading_spaces
{
  my $word = $_[0];

  my $str_length = length($word) - 1;
  my $count = 0;
  for (my $i = 0; $i < $str_length; $i++)
  {
    if (substr($word, $i, 1) ne " ") { last; }
    else { $count++; }
  }

  return $count;
}

#---------------------------------------------------------------------------
# trim leading spaces
#---------------------------------------------------------------------------
sub trim_trailing_spaces
{
  my $word = $_[0];

  my $str_length = length($word);
  my $last = $str_length;
  for (my $i = $str_length - 1; $i >= 0; $i--)
  {
    if (substr($word, $i, 1) ne " ") { last; }
    else { $last--; }
  }

  return substr($word, 0, $last);
}

#---------------------------------------------------------------------------
# trim leading spaces
#---------------------------------------------------------------------------
sub trim_end_spaces
{
  my $word = $_[0];

  return trim_trailing_spaces(trim_leading_spaces($word));
}

#---------------------------------------------------------------------------
# trim all spaces
#---------------------------------------------------------------------------
sub trim_all_spaces
{
  my $word = $_[0];

  $word =~ /([^\s]+)/;

  return $1;
}

1
