
##----------------------------------------------------------------------------------------
##
##----------------------------------------------------------------------------------------
sub evalFunction # ($function, \@X, \@args)
{
   my ($function, $X, $args) = @_;
   $function = defined($function) ? $function : 'mean';

   my $Y = undef;

   if($function =~ /^\s*mean\s*$/i or
      $function =~ /^\s*ave\s*$/i)
   {
      $Y = &evalMean($X, $args);
   }

   elsif($function =~ /^\s*median\s*$/i)
   {
      $Y = &evalMedian($X, $args);
   }

   elsif($function =~ /^\s*gte\s*$/i)
   {
      $Y = &evalGreaterThanOrEqual($X, $$args[0]);
   }

   elsif($function =~ /^\s*fgte\s*$/i)
   {
      $Y = &evalFractionGreaterThanOrEqual($X, $$args[0]);
   }

   return $Y;
}

##----------------------------------------------------------------------------------------
## $double evalFractionGreaterThanOrEqual(\@list X, $double value=0)
##
## Counts the number of values that are greater or equal to $value.
##----------------------------------------------------------------------------------------
sub evalFractionGreaterThanOrEqual
{
   my ($X, $value) = @_;
   $value = defined($value) ? $value : 0.0;

   my $non_missing = 0;
   my $count       = 0;
   foreach my $x (@{$X})
   {
      if($x =~ /\d/)
      {
         $non_missing++;

         if($x >= $value)
         {
            $count++;
         }
      }
   }

   my $fraction = $non_missing > 0 ? $count / $non_missing : undef;

   return $fraction;
}

##----------------------------------------------------------------------------------------
## $int evalGreaterThanOrEqual(\@list X, $double value=0)
##
## Counts the number of values that are greater or equal to $value.
##----------------------------------------------------------------------------------------
sub evalGreaterThanOrEqual
{
   my ($X, $value) = @_;
   $value = defined($value) ? $value : 0.0;

   my $count = 0;
   foreach my $x (@{$X})
   {
      if($x =~ /\d/ and $x >= $value)
      {
         $count++;
      }
   }

   return $count;
}

##----------------------------------------------------------------------------------------
## $double evalMean(\@list X)
##----------------------------------------------------------------------------------------
sub evalMean
{
   my ($X) = @_;
   my $result = 0;
   my $num  = 0;

   for(my $i = 0; $i < scalar(@{$X}); $i++)
   {
      if($$X[$i] =~ /\S/ and not($$X[$i] =~ /NaN/))
      {
         $result += $$X[$i];
         $num++;
      }
   }
   if($num > 0)
   {
      $result /= $num;
   }
   else
   {
      $result = 'NaN';
   }

   return $result;
}

sub meanCols
{
   my ($matrix, $max_cols) = @_;
   ## n is the number of replicates
   my $n = scalar(@{$matrix});
   ## m is the number of data columns
   my $m = defined($max_cols) ? $max_cols : &maxColDim($matrix);

   my @ave;

   my @ok; # number of non-missing data values for column j
   for(my $j = 0; $j < $m; $j++)
   {
      $ave[$j] = 0.0;

      $ok[$j]  = 0.0;

      for(my $i = 0; $i < $n; $i++)
      {
         if(defined($$matrix[$i][$j]) and $$matrix[$i][$j] =~ /\d/)
         {
            $ave[$j] += $$matrix[$i][$j];

            $ok[$j]  += 1.0;
         }
      }
   }

   for(my $j = 0; $j < $m; $j++)
   {
      if($ok[$j] == 1)
      {
         $ave[$j] = $ave[$j];
      }
      elsif($ok[$j] > 1)
      {
         $ave[$j] /= $ok[$j];
      }
      else
      {
         $ave[$j] = 'NaN';
      }
   }

   return \@ave;
}

sub maxColDim
{
   my ($matrix) = @_;

   my $m = 0;

   for(my $i = 0; $i < $n; $i++)
   {
      my $m_ = scalar(@{$matrix[$i]});

      if($m_ > $m)
      {
         $m = $m_;
      }
   }

   return $m;
}

sub by_safe_numeric
{
   my $compare = undef;

   if(not(defined($b)) or $b =~ /NaN/i)
   {
      $compare = -1;
   }
   elsif(not(defined($a)) or $a =~ /NaN/i)
   {
      $compare = 1;
   }
   else
   {
      $compare = ($a <=> $b);
   }

   return $compare;
}

##----------------------------------------------------------------------------------------
## $double evalMedian (\@list X, $int sorted=0)
##----------------------------------------------------------------------------------------
sub evalMedian
{
   my ($X, $sorted) = @_;

   $sorted = defined($sorted) ? $sorted : 0;

   my $result = undef;

   if(not($sorted))
   {
      my @sorted_X = sort by_safe_numeric @{$X};

      $X = \@sorted_X;
   }

   my $non_missing = 0;

   foreach my $x (@{$X})
   {
      if($x =~ /\d/)
      {
         $non_missing++;
      }
   }

   my $middle = int($non_missing / 2.0);

   my $i = 0;

   foreach my $x (@{$X})
   {
      if($x =~ /\d/)
      {
         $i++;
      }
      if($i == $middle)
      {
         $result = $x;
      }
   }

   return $result;
}

##----------------------------------------------------------------------------------------
## $double evalMax (\@list X)
##----------------------------------------------------------------------------------------
sub evalMax
{
   my ($X) = @_;

   my $result = undef;

   foreach my $x (@{$X})
   {
      if($x =~ /\S/ and not($x =~ /NaN/) and not(defined($result)) or $x > $result)
      {
         $result = $x;
      }
   }

   return $result;
}

##----------------------------------------------------------------------------------------
## $double evalMin (\@list X)
##----------------------------------------------------------------------------------------
sub evalMin
{
   my ($X) = @_;

   my $result = undef;

   foreach my $x (@{$X})
   {
      if($x =~ /\S/ and not($x =~ /NaN/) and not(defined($result)) or $x < $result)
      {
         $result = $x;
      }
   }

   return $result;
}

sub truncateNumber
{
   my ($X, $places) = @_;

   $places = defined($places) ? $places : 2;

   my $n = scalar(@{$X});

   my @Y;

   for(my $i = 0; $i < $n; $i++)
   {
      $Y[$i] = ($$X[$i] =~ /\d/) ? sprintf('%.' . $places . 'f', $$X[$i]) : $$X[$i];
   }

   return \@Y;
}

##----------------------------------------------------------------------------------------
## $double evalFunctionString ($string function="mean", $string X=$_, $string delim="\t")
##----------------------------------------------------------------------------------------
sub evalFunctionString
{
   my ($function, $string, $delim) = @_;
   $string   = defined($string)   ? $string   :     $_;
   $delim    = defined($delim)    ? $delim    :   "\t";

   my @list = split($delim, $string);

   return &evalFunction($function, \@list);
}

1
