#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/libseq.pl";

my $beg = undef;
my $end = undef;
my @fasta_files;
my $location_file = undef;
my $organism = undef;
my $verbose = 1;
my $unzip = 0;
my $boundaries = 0;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-unzip')
  {
    $unzip = 1;
  }
  elsif($arg eq '-boundaries')
  {
    $boundaries = 1;
  }
  elsif(not(defined($beg)))
  {
    $beg = int($arg);
    # Correct for the lack of 0 in sequence numbering:
    $beg = $beg>0 ? $beg-1 : $beg;
  }
  elsif(not(defined($end)))
  {
    $end = int($arg);
    # Correct for the lack of 0 in sequence numbering:
    $end = $end>0 ? $end-1 : $end;
  }
  elsif(not(defined($location_file)) and (-f $arg))
  {
    open($location_file,$arg) or
      die("Could not open location file '$arg' for reading.");
  }
  elsif(not(defined($location_file)) and ($arg eq '-'))
  {
    $location_file = \*STDIN;
  }
  elsif((-f $arg) or ($arg eq '-'))
  {
    push(@fasta_files,$arg);
  }
  elsif(not(defined($organism)))
  {
    $organism = $arg;
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

# Infer the organism from the current directory.
if(length($organism)==0)
{
  $organism = &getMapOrganismFromPath(`pwd`);
}
else
{
  $organism = &getMapOrganismName($organism);
}

# Try to find the FASTA sequence file in the standard MAP location.
if($#fasta_files==-1 and length($organism)>0)
{
  my $file = &getMapDir('Data') . "/Genome/Sequence/$organism/data.fad";
  push(@fasta_files,$file);
}

# Try to find the location file in the standard MAP location.
if(not(defined($location_file)) and length($organism)>0)
{
  my $file = &getMapDir('Data') . "/Genome/Location/$organism/data.tab";
  open($location_file, $file) or
    die("Could not open the location file '$file' for reading.");
}

defined($beg)           or die("No beginning position supplied.");
defined($end)           or die("No end position supplied.");
$#fasta_files>=0        or die("No FASTA file(s) supplied/found.");
defined($location_file) or die("No location file supplied/found.");

# $verbose and print STDERR "Organism = '$organism'\n";

my %plus;
my %minus;
while(<$location_file>)
{
  if(/\S/)
  {
    chomp;
    my ($gene,$seq_id,$five,$three) = split("\t");
    $five--;
    $three--;
    if($five<=$three)
    {
      if(not(exists($plus{$seq_id})))
      {
        $plus{$seq_id} = "$gene $five $three";
      }
      else
      {
        $plus{$seq_id} .= "\t$gene $five $three";
      }
      # print STDERR "[$seq_id] [$gene] [$five] [$three]\n";
    }
    else
    {
      if(not(exists($minus{$seq_id})))
      {
        $minus{$seq_id} .= "$gene $three $five";
      }
      else
      {
        $minus{$seq_id} .= "\t$gene $three $five";
      }
    }
  }
}
close($location_file);

foreach my $seq_id (keys(%plus))
{
  $plus{$seq_id} .= "\tfive_prime -1 -1\tthree_prime 1000000000000 1000000000000";
  $minus{$seq_id} .= "\tthree_prime -1 -1\tfive_prime 1000000000000 1000000000000";
}

my %seq2regions;
foreach my $seq_id (sort {$a<=>$b} keys(%plus))
{
  # my $seq = $seqs{$seq_id};

  # Sort the ORFs by beginning position
  my @plus = sort by_beg split("\t",$plus{$seq_id});

  my @regions;
  $seq2regions{$seq_id} = \@regions;

  # Store positions on the plus strand for this sequence
  for(my $i=1; $i<$#plus-1; $i++)
  {
    my ($my_id,$my_left,$my_right)          = split(" ",$plus[$i]);
    my ($left_id,$left_left,$left_right)    = split(" ",$plus[$i-1]);
    my ($right_id,$right_left,$right_right) = split(" ",$plus[$i+1]);

    $left_right = ($left_right >= $my_left)  ? $my_left-1 : $left_right;
    $right_left = ($right_left <= $my_right) ? $my_right+1 : $right_left;

    my $left  = $my_left + $beg;
    my $right = $my_left + $end;

    # print "[$seq_id] [$left_id] [$left_left] [$left_right]\n";
    # print "[$seq_id] [$right_id] [$right_left] [$right_right]\n";
    # print "[$left_left,$left_right] [$my_left,$my_right] [$right_left,$right_right] ($left,$right) --> ";

    # If boundaries checking is on, make the region not cross the 5' gene or our 3' end
    if($boundaries)
    {
      $left   = ($left  <= $left_right) ? $left_right+1 : $left;
      $right  = ($right <= $left_right) ? $left_right+1 : $right;
      $left   = ($left  >= $right_left) ? $right_left-1 : $left;
      $right  = ($right >= $right_left) ? $right_left-1 : $right;
    }

    # my $sub_seq = substr($seq,$left,$right-$left+1);

    # print ">$my_id\n$sub_seq\n";

    my $region = "$my_id\tplus\t$left\t$right";
    push(@regions,$region);
  }

  # Store positions on the minus strand.
  my @minus = sort by_beg split("\t",$minus{$seq_id});
  for(my $i=1; $i<$#minus-1; $i++)
  {
    my ($my_id,$my_left,$my_right)          = split(" ",$minus[$i]);
    my ($left_id,$left_left,$left_right)    = split(" ",$minus[$i-1]);
    my ($right_id,$right_left,$right_right) = split(" ",$minus[$i+1]);

    $left_right = ($left_right >= $my_left)  ? $my_left-1 : $left_right;
    $right_left = ($right_left <= $my_right) ? $my_right+1 : $right_left;

    my $left  = $my_right - $end;
    my $right = $my_right - $beg;

    # If boundaries checking is on, make the region not cross the 5' gene or our 3' end
    if($boundaries)
    {
      $left   = ($left  <= $left_right) ? $left_right+1 : $left;
      $right  = ($right <= $left_right) ? $left_right+1 : $right;
      $left   = ($left  >= $right_left) ? $right_left-1 : $left;
      $right  = ($right >= $right_left) ? $right_left-1 : $right;
    }

    # my $sub_seq = &revCompliment(substr($seq,$left,$right-$left+1));
    # print ">$my_id\n$sub_seq\n";

    my $region = "$my_id\tminus\t$left\t$right";
    push(@regions,$region);
  }
  $seq2regions{$seq_id} = \@regions;
}

# Print out the regions requested.
my %seqs;
my %seq_lens;
my $num_seqs=0;
my $num_seqs_no_regions=0;
my $num_base_pairs=0;
my $num_base_pairs_no_regions=0;
foreach my $fasta_file (@fasta_files)
{
  my $fasta     = undef;
  my $skip_file = 0;

  if($fasta_file eq '-')
  {
    if($unzip)
    {
      open($fasta,"zcat | fasta2stab.pl |") or die("Unable to unzip FASTA standard input.");
    }
    else
    {
      open($fasta,"cat | fasta2stab.pl |") or die("Unable to read FASTA standard input.");
    }
  }
  elsif(-f $fasta_file)
  {
    if($unzip)
    {
      open($fasta,"zcat $fasta_file | fasta2stab.pl |") or die("Unable to unzip FASTA file '$fasta_file'.");
    }
    else
    {
      open($fasta,"cat $fasta_file | fasta2stab.pl |") or die("Unable to read FASTA file '$fasta_file'.");
    }
  }
  else
  {
    $verbose and print STDERR "WARNING: bad FASTA file '$fasta_file' given, skipping.\n";
    $skip_file = 1;
  }

  if(not($skip_file))
  {
    $verbose and print STDERR "Printing regions from sequence '$fasta_file'...";
    while(<$fasta>)
    {
      if(/\S/)
      {
        chomp;
        my ($seq_id,$seq) = split("\t");
	my $seq_len = length($seq);
        # print "[$seq_id] [$seq]\n";

	$num_seqs++;
	$num_base_pairs += $seq_len;

	# Print out all the regions for this sequence:
	if(exists($seq2regions{$seq_id}))
	{
	  my @regions = @{$seq2regions{$seq_id}};

	  foreach my $region (@regions)
	  {
            my ($my_id,$strand,$left,$right) = split("\t",$region);
	    $left  = $left < 0 ? 0 : $left;
	    $right = $right < 0 ? 0 : $right;
	    $right = $right >= $seq_len ? $seq_len-1 : $right;
	    $left  = $left > $right ? $right : $left;

	    # print STDERR "[$seq_len] [$my_id] [$strand] [$left] [$right]\n";

	    my $len = $right - $left + 1;
	    my $sub_seq = substr($seq,$left,$len);

	    if($strand eq 'minus')
	    {
	      $sub_seq = &revCompliment($sub_seq);
	    }

            print ">$my_id\n$sub_seq\n";
	  }
	}
	else
	{
	  $verbose and print STDERR "WARNING: No regions found on sequence '$seq_id'.\n";
	  &logMapError("$seq_id had no regions.\n");
	  $num_seqs_no_regions++;
	  $num_base_pairs_no_regions += $seq_len;
	}
      }
    }
    close($fasta);
    $verbose and print STDERR " done.\n";
  }
}

$verbose and print STDERR "$num_seqs total sequences processed ",
                          "($num_seqs_no_regions had no regions).\n",
			  "$num_base_pairs total base pairs read ",
			  "($num_base_pairs_no_regions in sequences without regions).\n";
exit(0);

sub by_beg
{
  if($a =~ /^\S+\s+(\S+)/)
  {
    my $abeg = int($1);
    if($b =~ /^\S+\s+(\S+)/)
    {
      my $bbeg = int($1);

      # Make sure -1 is greater than any other number
      # $abeg = ($abeg==-1) ? $bbeg+1 : $abeg;
      # $bbeg = ($bbeg==-1) ? $abeg+1 : $bbeg;

      return $abeg <=> $bbeg;
    }
  }
  return 0;
}

__DATA__
syntax: get_orf_seqs.pl [OPTIONS] BEG END [{ORGANISM | LOCATIONS_TABFILE FASTA1 [FASTA2...]}]

Prints the ORF-centric sequence from base-pair BEG to base-pair END centered on every
ORF in FASTA format.  Either supply an organism name or the fasta files to parse.  If
an organism is supplied, looks up where in the MAP data hierarchy the sequences and
appropriate locations files are located and uses those.  If neither an organism nor
sequence and location files are supplied then the script tries to infer the organism
from the current working directory.  If '-' is supplied instead of a file name then
the file is read from standard input.

ORGANISM: MAP organism name (e.g. Yeast, Fly, Worm, Human)

FASTA's: FASTA-formatted files containing the genomic sequence.  Every sequence should
be in this file.  The line starting with ">" should have the sequences key that the locations
refer to.

LOCATIONS_TABFILE: tab-delimited file containing ORF position information.  Format is:

	ORF_KEY <tab> SEQ_KEY <tab> FIVE <tab> THREE

where ORF_KEY is the identifier for the ORF, SEQ_KEY is the identifier to the sequence (should
match one of the FASTA sequence names in FASTA_FILE), FIVE is the 5' position of the ORF
(the first base in the first codon; i.e. "A" in "ATG"), and THREE is the 3' position.  If FIVE
is greater than THREE than a sequence on the minus strand is retrieved, otherwise a sequence
on the plus strand is retrieved.

OPTIONS are:

-q: Quiet mode (default is verbose).
-unzip: Unzip the FASTA files before extracting regions.
-boundaries: Turn on boundaries checking (default is off).  Sequences returned are truncated if
             necessary to force them not to overlap with neighboring genes.

