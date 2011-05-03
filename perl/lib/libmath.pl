require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

sub integrate
{
   my ($X, $intervals, $sorted) = @_;
   $sorted = defined($sorted) ? $sorted : 0;

   my $n = scalar(@{$X});

   $intervals = defined($intervals) ? $intervals : $n - 1;

   my $area = 0;

   if($n > 0)
   {
      if(not($sorted))
      {
         my @X = sort { $$a[0] <=> $$b[0]; } @{$X};
         $X = \@X;
      }

      my $range = $$X[$n - 1][0] - $$X[0][0];
      my $delta = $range <= 0 ? $min_y : ($range / $intervals);
      my @knot  = @{$$X[0]};
      my $p     = scalar(@knot);

      for(my $i = 0; $i < $intervals; $i++)
      {
         $knot[0]   = $$X[0][0] + $delta * (0.5 + $i);
         my $interp = &interp($X, \@knot);

         if(defined($$interp[0]))
         {
            # $knot[1]   = $$interp[0];
            # print STDOUT join(" ", @knot), "\n";
            $area += $$interp[0] * $delta;
         }
      }
   }

   return $area;
}

#------------------------------------------------------------------------------
# \@list interp(\@\@list X, \@list x, \@list independent=[0])
#------------------------------------------------------------------------------
sub interp
{
   my ($X, $x, $independent) = @_;
   $independent = defined($independent) ? $independent : [0];

   my $n = scalar(@{$X});

   my $p = scalar(@{$x});

   my $min_i1 = undef;
   my $min_i2 = undef;
   my $min_d1 = undef;
   my $min_d2 = undef;
   for(my $i = 0; $i < $n; $i++)
   {
     my $sqrdist  = &squaredEuclid($$X[$i], $x, $independent);
     my $distance = (defined($sqrdist) and $sqrdist > 0) ? sqrt($sqrdist) : undef;
     if(not(defined($min_d1)) or (defined($distance) and $distance < $min_d1))
     {
        $min_i2 = $min_i1;
        $min_d2 = $min_d1;

        $min_i1 = $i;
        $min_d1 = $distance;
     }
   }
   $min_i2 = defined($min_i2) ? $min_i2 : $min_i1;
   $min_d2 = defined($min_d2) ? $min_d2 : $min_d1;

   my @y;

   if(defined($min_i2) and defined($min_d2) and ($min_d1 + $min_d2 > 0))
   {
      my $pred = &list2Set($independent);
      for(my $j = 0; $j < $p; $j++)
      {
         if(not(exists($$pred{$j})))
         {
            my $y1 = $$X[$min_i1][$j];
            my $y2 = $$X[$min_i2][$j];
            my $y  = ($min_d2 * $y1 + $min_d1 * $y2) / ($min_d1 + $min_d2);
            push(@y, $y);
         }
      }
   }

   return \@y;
}

#------------------------------------------------------------------------------
# $double squaredEuclid(\@list x, \@list y, \@list subset=undef)
#------------------------------------------------------------------------------
sub squaredEuclid
{
   my ($x, $y, $subset) = @_;

   my $result = 0;
   if(not(defined($subset)))
   {
      my $n = scalar(@{$x});
      my $m = scalar(@{$y});
      my $q = $n < $m ? $n : $m;
      for(my $i = 0; $i < $q; $i++)
      {
         $result += ($$x[$i] - $$y[$i]) * ($$x[$i] - $$y[$i]);
      }
   }
   else
   {
      my $n = scalar(@{$x});
      my $m = scalar(@{$y});
      my $q = scalar(@{$subset});
      for(my $j = 0; $j < $q; $j++)
      {
         my $i = $$subset[$j];

         if($i < $n and $i < $m and $i >= 0)
         {
            $result += ($$x[$i] - $$y[$i]) * ($$x[$i] - $$y[$i]);
         }
      }
   }
   return $result;
}


1
