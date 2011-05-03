use strict;

##----------------------------------------------------------------------------
## getLongestBlastHit (\@list segments)
##----------------------------------------------------------------------------
sub getLongestBlastHit
{
   my ($segments) = @_;

   my %hits;

   foreach my $segment (@{$segments})
   {
      my ($id, $beg, $end, $perc) = @{$segment};

      if(not(exists($hits{$id})))
      {
         $hits{$id} = [];
      }

      push(@{$hits{$id}}, [$beg, $end, $perc]);
   }

   my @longest;
   foreach my $id (keys(%hits))
   {
      my $segs = &assembleSegments($hits{$id});

      my @s;
      foreach my $seg (@{$segs})
      {
         my ($beg, $end, $perc) = @{$seg};

         my $len = abs($end - $beg);

         push(@s, [$len, $beg, $end, $perc]);
      }
      @s = sort { $$b[0] <=> $$a[0]; } @s;

      my $len  = $s[0][0];
      my $beg  = $s[0][1];
      my $end  = $s[0][2];
      my $perc = $s[0][3];

      push(@longest, [$len, $id, $beg, $end, $perc]);
   }

   @longest = sort { $$b[0] <=> $$a[0]; } @longest;

   my $len  = $longest[0][0];
   my $id   = $longest[0][1];
   my $beg  = $longest[0][2];
   my $end  = $longest[0][3];
   my $perc = $longest[0][4];

   return [$id, $beg, $end, $perc];
}

##----------------------------------------------------------------------------
##
##----------------------------------------------------------------------------
sub assembleSegments
{
   my ($segments) = @_;

   my $max = undef;

   my $min = undef;

   foreach my $segment (@{$segments})
   {
      my ($beg, $end, $perc) = @{$segment};

      my $bigger  = $beg < $end ? $end : $beg;

      my $smaller = $beg < $end ? $beg : $end;

      $max = (defined($max) and ($max > $bigger))  ? $max : $bigger;

      $min = (defined($min) and ($min < $smaller)) ? $min : $smaller;
   }

   my @num;

   my @cover;

   for(my $i = 0; $i <= $max; $i++)
   {
      push(@num, 0);

      push(@cover, 0);
   }

   foreach my $segment (@{$segments})
   {
      my ($beg, $end, $perc) = @{$segment};

      my $bigger  = $beg < $end ? $end : $beg;

      my $smaller = $beg < $end ? $beg : $end;

      for(my $i = $smaller; $i <= $bigger; $i++)
      {
         $cover[$i] += $perc;
         $num[$i]   += 1.0;
      }
   }

   # Get contiguous pieces.

   my @segs;
   my ($inseg, $beg, $end, $perc, $num) = (0,0,0,0,0);
   for(my $i = $min; $i <= $max; $i++)
   {
      if($num[$i] > 0)
      {
         if(not($inseg))
         {
            $beg   = $i;
            $perc  = 0;
            $num   = 0;
            $inseg = 1;
         }

         $perc += $cover[$i] / $num[$i];

         $num  += 1;

         $end   = $i;
      }
      else
      {
         if($inseg)
         {
            push(@segs, [$beg, $end, $perc / $num]);
            $inseg = 0;
         }
      }
   }

   push(@segs, [$beg, $end, $perc / $num]);

   return \@segs;
}


##----------------------------------------------------------------------------
##
##----------------------------------------------------------------------------
sub isProteinFasta
{
   my ($filename) = @_;

   my $pipe;

   open($pipe, "cat $filename | fasta2stab.pl | cut -f 2 |") or
      die("Could not open fasta file '$filename'");

   my @seqs = <$pipe>;

   my $seqs = join('', @seqs);

   $seqs =~ s/\s+//g;

   my $num_nucs  = ($seqs =~ s/[AaCcGgTt]//g);

   my $num_amino = length($seqs);

   my $perc_nucs = $num_nucs / ($num_nucs + $num_amino) * 100.0;

   return ($perc_nucs < 90);
}

##----------------------------------------------------------------------------
##
## getBlastProgram
##----------------------------------------------------------------------------
sub getBlastProgram
{
   my ($file, $qpro, $dpro, $translate) = @_;

   $translate = defined($translate) ? $translate : 0;

   # If not specified, figure out what the query is based on its content.
   $qpro = defined($qpro) ? $qpro : &isProteinFasta($file);

   # If not specified, make the query and database types match up.
   $dpro = defined($dpro) ? $dpro : $qpro;

   my $program = undef;

   if($dpro and $qpro)
   {
      $program = 'blastp';
   }
   elsif($dpro and not($qpro))
   {
      $program = 'blastx';
   }
   elsif(not($dpro) and $qpro)
   {
      $program = 'tblastn';
   }
   elsif(not($dpro) and not($qpro))
   {
      if($translate)
      {
         $program = 'tblastx';
      }
      else
      {
         $program = 'blastn';
      }
   }
   return $program;
}

my %BlastTableColumns =
(
  'QUERY_ID'  => 1,
  'HIT_ID'    => 2,
  'IDENTITY'  => 3,
  'ALIGN_LEN' => 4,
  'MISMATCH'  => 5,
  'GAP_OPEN'  => 6,
  'QUERY_BEG' => 7,
  'QUERY_END' => 8,
  'HIT_BEG'   => 9,
  'HIT_END'   => 10,
  'EVALUE'    => 11,
  'BIT_SCORE' => 12
);

##----------------------------------------------------------------------------
##
##----------------------------------------------------------------------------
sub getBlastTableColumn # ($field)
{
  my $field = shift;
  if($field =~ /QUERY_ID/i)
    { return $BlastTableColumns{'QUERY_ID'}; }
  elsif($field =~ /HIT_ID/i)
    { return $BlastTableColumns{'HIT_ID'}; }
  elsif($field =~ /IDENTITY/i)
    { return $BlastTableColumns{'IDENTITY'}; }
  elsif($field =~ /ALIGN_LEN/i)
    { return $BlastTableColumns{'ALIGN_LEN'}; }
  elsif($field =~ /MISMATCH/i)
    { return $BlastTableColumns{'MISMATCH'}; }
  elsif($field =~ /GAP_OPEN/i)
    { return $BlastTableColumns{'GAP_OPEN'}; }
  elsif($field =~ /QUERY_BEG/i)
    { return $BlastTableColumns{'QUERY_BEG'}; }
  elsif($field =~ /QUERY_END/i)
    { return $BlastTableColumns{'QUERY_END'}; }
  elsif($field =~ /HIT_BEG/i)
    { return $BlastTableColumns{'HIT_BEG'}; }
  elsif($field =~ /HIT_END/i)
    { return $BlastTableColumns{'HIT_END'}; }
  elsif($field =~ /EVALUE/i)
    { return $BlastTableColumns{'EVALUE'}; }
  elsif($field =~ /BIT_SCORE/i)
    { return $BlastTableColumns{'BIT_SCORE'}; }
  return '';
}

1
