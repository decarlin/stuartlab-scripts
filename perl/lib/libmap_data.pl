use strict;

############################################################################################# 
# beautify_orf_name
############################################################################################# 
sub beautify_orf_name # ($orf,$organism)
{
  my $orf = shift;
  my $organism = shift;

  if($organism =~ /fly/i or
     $organism =~ /worm/i or
     $organism =~ /yeast/i)
  {
    $orf =~ s/^\s+//; # remove leading spaces
    $orf =~ s/\s+$//; # remove trailing spaces
    $orf =~ tr/a-z/A-Z/;
  }

  return $orf;
}

############################################################################################# 
# normalize_orf_name
############################################################################################# 
sub normalize_orf_name # ($orf,$organism)
{
  my $orf = shift;
  my $organism = shift;

  if($organism =~ /fly/i or
     $organism =~ /worm/i or
     $organism =~ /yeast/i)
  {
    $orf =~ tr/a-z/A-Z/;
    $orf =~ s/_\d+$//;
  }

  return $orf;
}

############################################################################################# 
# cogs_organism_id
############################################################################################# 
sub cogs_organism_id
{
  my $organism = shift @_;
  my $id = '';

  if($organism =~ /yeast/i)
  {
    $id = 'Sce';
  }

  elsif($organism =~ /worm/i)
  {
    # Currently not in COGs main list...
  }

  elsif($organism =~ /fly/i)
  {
    # Currently not in COGs main list...
  }

  elsif($organism =~ /human/i)
  {
    # Currently not in COGs main list...
  }
}

sub get_chromosome_name # ($chr,$total)
{
  my $chr = shift;
  my $total = shift;
  my $num = &get_chromosome_number($chr,$total);
  my $chrom = '';

  if($num == -1)
  {
    $chrom = 'chr_X';
  }

  elsif($num == -2)
  {
    $chrom = 'chr_Y';
  }

  elsif($num == -3)
  {
    $chrom = 'mito';
  }

  elsif($num == -4)
  {
    $chrom = 'chloro';
  }

  elsif($num>0 and $num<10)
  {
    $chrom = "chr_0$num";
  }

  elsif($num>=10)
  {
    $chrom = "chr_$num";
  }

  return $chrom;
}


sub get_chromosome_number # ($chr,$total)
{
  my $chr     = shift;
  my $total   = shift;
  my $chr_num = &roman2number($chr,$total);

  if($total>0 and $chr_num > $total)
  {
    # X chromosome mistaken for Roman Numeral 10
    if($chr_num == 10)
    {
      return -1;
    }
    return 0;
  }

  if($chr_num > 0)
  {
    return $chr_num;
  }

  if($chr =~ /(\d+)/)
  {
    return $1;
  }

  if($chr =~ /x/i)
  {
    return -1;
  }

  if($chr =~ /y/i)
  {
    return -2;
  }

  if($chr =~ /mito/i)
  {
    return -3;
  }

  if($chr =~ /chloro/i)
  {
    return -4;
  }

  return 0;
}

sub roman2number # ($chr)
{
  my $text = shift;

  if($text =~ /[^a-zA-Z]I[^a-zA-Z]/)
  {
    return 1;
  }
  if($text =~ /[^a-zA-Z]II[^a-zA-Z]/)
  {
    return 2;
  }
  if($text =~ /([^a-zA-Z])III([^a-zA-Z])/)
  {
    return 3;
  }
  if($text =~ /([^a-zA-Z])IV([^a-zA-Z])/)
  {
    return 4;
  }
  if($text =~ /([^a-zA-Z])V([^a-zA-Z])/)
  {
    return 5;
  }
  if($text =~ /([^a-zA-Z])VI([^a-zA-Z])/)
  {
    return 6;
  }
  if($text =~ /([^a-zA-Z])VII([^a-zA-Z])/)
  {
    return 7;
  }
  if($text =~ /([^a-zA-Z])VIII([^a-zA-Z])/)
  {
    return 8;
  }
  if($text =~ /([^a-zA-Z])IX([^a-zA-Z])/)
  {
    return 9;
  }
  if($text =~ /([^a-zA-Z])X([^a-zA-Z])/)
  {
    return 10;
  }
  if($text =~ /([^a-zA-Z])XI([^a-zA-Z])/)
  {
    return 11;
  }
  if($text =~ /([^a-zA-Z])XII([^a-zA-Z])/)
  {
    return 12;
  }
  if($text =~ /([^a-zA-Z])XIII([^a-zA-Z])/)
  {
    return 13;
  }
  if($text =~ /([^a-zA-Z])XIV([^a-zA-Z])/)
  {
    return 14;
  }
  if($text =~ /([^a-zA-Z])XV([^a-zA-Z])/)
  {
    return 15;
  }
  if($text =~ /([^a-zA-Z])XVI([^a-zA-Z])/)
  {
    return 16;
  }
  if($text =~ /([^a-zA-Z])XVII([^a-zA-Z])/)
  {
    return 17;
  }
  if($text =~ /([^a-zA-Z])XVIII([^a-zA-Z])/)
  {
    return 18;
  }
  if($text =~ /([^a-zA-Z])XIX([^a-zA-Z])/)
  {
    return 19;
  }
  if($text =~ /([^a-zA-Z])XX([^a-zA-Z])/)
  {
    return 20;
  }
  if($text =~ /([^a-zA-Z])XXI([^a-zA-Z])/)
  {
    return 21;
  }
  if($text =~ /([^a-zA-Z])XXII([^a-zA-Z])/)
  {
    return 22;
  }
  if($text =~ /([^a-zA-Z])XXIII([^a-zA-Z])/)
  {
    return 23;
  }
  if($text =~ /([^a-zA-Z])XXIV([^a-zA-Z])/)
  {
    return 24;
  }
  if($text =~ /([^a-zA-Z])XXV([^a-zA-Z])/)
  {
    return 25;
  }
  if($text =~ /([^a-zA-Z])XXVI([^a-zA-Z])/)
  {
    return 26;
  }
  if($text =~ /([^a-zA-Z])XXVII([^a-zA-Z])/)
  {
    return 27;
  }
  if($text =~ /([^a-zA-Z])XXVIII([^a-zA-Z])/)
  {
    return 28;
  }
  if($text =~ /([^a-zA-Z])XXIX([^a-zA-Z])/)
  {
    return 29;
  }
  if($text =~ /([^a-zA-Z])XXX([^a-zA-Z])/)
  {
    return 30;
  }

  return 0;
}

##---------------------------------------------------------------------------
##
##---------------------------------------------------------------------------
sub get_bio_format # ($file_name)
{
  my $file_name = shift;

  if($file_name =~ /.fasta$/i or
     $file_name =~ /.fa$/i or
     $file_name =~ /.dna$/i)
  {
    return 'fasta';
  }

  if($file_name =~ /.gff$/i)
  {
    return 'gff';
  }

}




1
