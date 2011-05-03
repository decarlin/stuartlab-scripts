#!/usr/bin/perl

use strict;
use warnings;

my $headers       = 0;
my $deterministic = undef;
my $blanks        = 1;

#
#First check arguments for 'cry for help'
#-d switch: no random number seed
#
#while(@ARGV){
#   my $arg = shift @ARGV;
#   if ($arg eq '--help'){
#      print <DATA>;
#      exit(0);
#   }
#   elsif($arg eq '-d'){
#      #$deterministic = shift(@ARGV);
#      $deterministic = '0';
#   }
#}

#
#Read in positions, print out results
#
my @positions;
while(<STDIN>)
{
   if($blanks or /\S/)
   {
      push(@positions, $_);
   }
}

&scrambleGenePositions(\@positions, $headers, $deterministic, \*STDOUT);

# my $scrambled = &scrambleGenePositions(\@positions, $headers, $deterministic);
# foreach my $scrambled_line (@{$scrambled})
# {
#    print STDOUT $scrambled_line;
# }


#
#Subroutine:scrambleGenePositions
#
sub scrambleGenePositions
{
    my ($positions, $headers, $deterministic, $file) = @_;

    $headers = defined($headers) ? $headers : 0;

#
#set the random number seed for the rand operator:
#
    $deterministic = defined($deterministic) ? $deterministic : time()^($$+($$<<15));

#
#call srand function,for debugging set $deterministic to 0:
#
    srand($deterministic);

    my @list;
    my %orfnames;
    my %positions;
    my $gene;
    my $chrom;

    my @header;
    for(my $i = 0; $i < $headers; $i++)
    {
       push(@header, $$positions[$i]);
    }

#
#read in the positions.tab file with info for all chromosomes,
#create an array for the orfnames of each chrom,
#create a hash of arrays of arrays for the remaining position info, each key is a chrom
#
    my $num_positions = scalar(@{$positions});
    for(my $i = $headers; $i < $num_positions; $i++)
    {
       @list = split(/\t/, $$positions[$i]);
       if (defined($list[2]) and $list[2] =~ /\d/)
       {
           $gene  = shift(@list);
           $chrom = $list[0];

           push(@{$orfnames{$chrom}}, $gene);
           #reference to an anonymous array:
           push(@{$positions{$chrom}}, [@list]);
           #$aa++;print STDERR "C:$aa, $chrom, [@list]\n";
       }
    }

#
#random selection of elements from the orfnames of 
#make new hash with scrambled orfnames
#

    my $nr_orf;
    my @scrambled_orfnames;
    my $ref_orfnames;
    my $returned_ref;
    my %scrambled_orfnames;

    foreach $chrom (keys %orfnames)
    {
        $nr_orf                        = scalar (@{$orfnames{$chrom}});
        $ref_orfnames                  = $orfnames{$chrom};
        $returned_ref                  = &RAND($ref_orfnames,$nr_orf,$chrom);
        @{$scrambled_orfnames{$chrom}} = @$returned_ref;
    }

   #
   # print header to output file
   #
   my @scrambled = @header;

   #
   #print scrambled orfnames and position info to output file
   #
   foreach $chrom(keys %scrambled_orfnames)
   {
      my $nr_elements = scalar(@{$positions{$chrom}});
      for(my $i=0;$i<$nr_elements;$i++)
      {
         my $for_output = $scrambled_orfnames{$chrom}[$i] . "\t" .
                             join("\t",@{$positions{$chrom}[$i]});
         push(@scrambled, $for_output);

         if(defined($file))
         {
            print $file $for_output;
         }
      }
   }
   return (\@scrambled);
}

#
#Subroutine in Subroutine
#

sub RAND
{
   my ($orf,$nr_orf,$chrom)=@_;
   my $nr_orfnames=$nr_orf;
   my @orf=@$orf;
   my $x='';
   my (@scrambled_orfnames);


   while (@orf)
   {
      my $i=int(rand($nr_orfnames));
      $x=splice(@orf,$i,1);
      push(@scrambled_orfnames,$x);
      $nr_orfnames--;
   }

   return(\@scrambled_orfnames);
}


__DATA__
syntax: scramble_positions_diff_chrom.pl [OPTIONS] <POSITIONS >OUTPUT

[OPTIONS]    -d: for random seed number 0; not active 

This script randomly associates gene names from one chromosome with position informations (chrom start end)from that same chromosome. 
It takes one file as input:

POSITIONS  -- a tab-delimited file containing the genome position
              information of the genes from all chromosomes

and prints the result to an OUTPUT file.

The script is now a big subroutine that can be used in other programs 
Written to be used like this:

@positions=("gene1\tchrom1\tstart1\tend1,"gene2\tchrom2\tstart2\tend2",....);
$scrambled=&scrambleGenePositions(\@positions);

sub scrambleGenePositions {
    my ($positions)=@_;
    my @scrambled;
    ...
    return \@scrambled;
}
