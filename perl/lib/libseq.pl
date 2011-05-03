sub compliment
{
  my($seq) = $_[0];
  $seq =~ tr/ACGTacgt/TGCAtgca/;
  return $seq;
}

sub revCompliment
{
  my($seq) = $_[0];
  $seq =~ tr/ACGTacgt[]{}()/TGCAtgca][}{)(/;
  return (reverse($seq));
}

sub dnaNbr
{
  my($seq) = $_[0];
  my($window) = (defined $_[1]) ? $_[1] : 0;

  $seq =~ s/\s//g;

  my(@s) = split('',$seq);

  # Get the compliment:
  $seq =~ tr/ACGTacgt/TGCAtgca/;
  my(@c) = split('',$seq);

  $most_recent{"A"} = 0;
  $most_recent{"C"} = 0;
  $most_recent{"G"} = 0;
  $most_recent{"T"} = 0;

  for($i=$#s; $i>=0; $i--)
  {
    $nbr[$i] = $most_recent{$c[$i]};
    $nbr[$i] = ($nbr[$i]>0) ? $nbr[$i] - $i : 0;
    $nbr[$i] = ($nbr[$i]>$window && $window>0) ? 0 : $nbr[$i];
    $most_recent{$s[$i]} = $i;
  }
  return join(',',@nbr);
}

%ambig2set =
        (
                "B" => "CGT",
                "D" => "AGT",
                "H" => "ACT",
                "K" => "GT",
                "M" => "AC",
                "N" => "ACGT",
                "R" => "AG",
                "S" => "CG",
                "U" => "T",
                "V" => "CAG",
                "W" => "AT",
                "Y" => "CT"
        );
  
# Converts IUPAC ambiguous characters to their regular expression
# equivalents.  For example, every occurence of "B" in the input sequence
# will be changed to "[CGT]".
#
sub ambig2regexp
{
  my($seq) = shift @_;
  my($ambig);

  $seq =~ tr/a-z/A-Z/;

  foreach $ambig (keys(%ambig2set))
  {
    $seq =~ s/$ambig/[$ambig2set{$ambig}]/g;
  }
  return $seq;
}

1
