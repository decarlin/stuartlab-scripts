#!/usr/bin/perl -w
use warnings;
use strict;
use Getopt::Long;
use List::Util qw(max min); # import the max and min functions

my $line;
my $path;
my $fillPath;
my @data;
my %pathway;
my %pathwaySize;
my %genes;
my %acceptedPathways;
my %overlap;
my %lostGenes;

my $defaultOverlapOutputPrefix = "nr_sets--sets_overlap_result";
my $overlapFile = undef;
my $printAccepted = 0;
my $printAcceptedGenes = 0;
my $printLostGenes = 0;
my $cutoffProportion = 0.50;	#default overlap cut-off
my $minAllowedSetSize = undef;			#default minimum genes per pathway

my $localGenesFlag = 0;
my $globalGenesFlag = 0;

my $setsFile = undef;

my $printRejectedOnly = 0; # do we want to ONLY print the rejected items? (probably not)
my $printAll = 0; # prints both rejected AND accepted sets (each row starts with "ACCEPTED" or "REJECTED" , so you can tell which is which)

sub printUsageAndExit {
  print STDOUT <DATA>;
  exit(1);
}

GetOptions(
		     "s|sets=s"  => \$setsFile,
		   , "o|overlap=s"  => \$overlapFile
		   , "c|cutoff=f" => \$cutoffProportion
		   , "v|invert-match" => sub { $printRejectedOnly = 1; }
		   , "a|all" => sub { $printAll = 1; }
		   , "sms|set_min_size=i" => \$minAllowedSetSize
		   , "h|?|help|man" => sub { printUsageAndExit(); }
		  ) or printUsageAndExit();


if (defined($setsFile) && defined($overlapFile)) {
  die "\n\nERROR IN INPUT: Please specify EITHER a sets file, OR an overlap file. If you don't know which to omit, omit the overlap file and one will be automatically generated from the sets file.\n";
}


if (!defined($overlapFile)) {
  if (!defined($setsFile)) {
	die "\n\nERROR in input arguments: You must specify EITHER a sets file (--sets=SETSFILE) *OR* a sets_overlap.pl output file (--overlapfile=OVERLAP_OUTPUT).\nIf you don't know what this means, then it means you probably should specify a sets file (--sets=YOUR_SETS_FILE). The sets file format is, on each line:  SOME_SET_NAME   member1   member2  member3.\nOne sets file (for yeast) that we frequently use is the GO pathway set found in \$MAPDIR/Data/GeneSets/Go/Yeast/lists_t.tab  .\n";
  }
  $overlapFile = $defaultOverlapOutputPrefix . "_" . $setsFile . ".tmp";
  print STDERR "We are using the following file as the overlap output file: \"$overlapFile\"\n";
  print STDERR "Note: if you delete that file, nr_sets.pl will automatically regenerate it.\n";
  print STDERR "Note: You can also specify your own file with the --if you delete that file, nr_sets.pl will automatically regenerate it.\n";
}

if (defined($setsFile) && (not -f $overlapFile)) {
  print STDERR "Running sets_overlap... (this can take a while: check progress with the \"top\" command if you want to make sure it is in fact running).\n";
  if (not -f $setsFile) {
	die "\n\nERROR: We were trying to generate an overlap file from the sets file \"$setsFile\", but that file appears not to exist! (Or maybe we can't read it.)\n";
  }
  system("sets_overlap.pl -noself -do '	' -p 0.8 -q $setsFile $setsFile > $overlapFile");
  print STDERR "Done running sets_overlap.\n";
}

print STDERR "Reading overlap from file $overlapFile, with overlap cutoff at $cutoffProportion...\n";

my %accepted = ();
my %rejected = ();

open(FILE, "$overlapFile") or die "Could not open $overlapFile\n"; {

  my $masterSetName = undef;

  my $skipToNextCaret = 1;

  while (my $line = <FILE>) {
	chomp($line);
	next if ($line =~ /^\s*$/);	# skip blank lines

	if ($line =~ /^\>/) {  # found a new path to look at...
	  my @sp = split(/\t/, $line);
	  $masterSetName = $sp[0];	#grab the current pathway name
	  $masterSetName =~ s/^\>//;			#take out the >
	  $accepted{$masterSetName} = 0; # accept it tentatively... but we might reject it later
	  $skipToNextCaret = 0; # stop skipping, and actually consider the elements that follow
	  next;
	}
	if ($skipToNextCaret || !defined($masterSetName)) {
	  next;
	}
	my @ldat = split(/\t/, $line);
	my $comparisonSetName   = $ldat[0];

	if (exists($accepted{$comparisonSetName}) && defined($accepted{$comparisonSetName}) && ($comparisonSetName ne $masterSetName)) {
	  # Ok, let's see if the master set is similar to this other guy that we already accepted...
	  my $score      = $ldat[1];
	  my $numOverlap = $ldat[2];
	  my $numInMasterSet = $ldat[3];
	  my $numInOtherSet   = $ldat[4];

	  my $numInSmallerOfTheSets = min($numInMasterSet, $numInOtherSet);
	  my $proportionOverlap       = $numOverlap / $numInSmallerOfTheSets;

	  $accepted{$masterSetName} = max($accepted{$masterSetName}, $proportionOverlap); # store the highest-found overlap proportion so far (just for our amusement)

	  #print "Comparing $comparisonSetName to master set $masterSetName, which gives overlap of $proportionOverlap. $numOverlap, $numInOtherSet." . "\n";
	  if ($proportionOverlap > $cutoffProportion || (defined($minAllowedSetSize) && ($numInMasterSet < $minAllowedSetSize))) {
		# too overlap-y -- reject!
		if (defined($masterSetName) && exists($accepted{$masterSetName})) {
		  delete($accepted{$masterSetName});  # <-- remove from the accepted set!
		}
		$rejected{$masterSetName} = $proportionOverlap;
		$skipToNextCaret = 1;	# <-- ok, now skip to the next "master" item
	  }
	}
  }
} close(FILE);


if ($printAll || !$printRejectedOnly) {
  foreach my $x (keys(%accepted)) {
	print "ACCEPTED" . "\t" . $x . "\t" . sprintf("%.4f", $accepted{$x}) . "\n";
  }
}

if ($printAll || $printRejectedOnly) {
  foreach my $y (keys(%rejected)) {
	print "REJECTED" . "\t" . $y . "\t" . sprintf("%.4f", $rejected{$y}) . "\n";
  }
}




__DATA__

nr_sets.pl [OPTIONS] --sets=SETS_FILE or --overlap=OVERLAP_FILE

NR Sets means "non-redundant sets." It goes through a sets file (see YOUR_SETS below),
and keeps each set it finds, UNLESS that set has too much similarity to a set that it
has already been accepted.

(Set selection is based on the order that sets are encountered in the file. You can re-sort
the set file if you want to change the order. Note that the first set it finds in a file is
ALWAYS kept. The farther down the file you go, the more and more possibilities there are
for a set to be rejected due to similarity with an already-accepted set.)

First you need a sets_overlap output list. OR you can let nr_sets generate one automatically.

In order to run nr_sets.pl directly from a list of sets

Where YOUR_SETS is a tab-delimited file of the lists_t.tab format, which looks like this:

YOUR_SETS file looks like:
  Alphabet   A   B   C   D   E   F   G   H
  Consonants B   C   D   F   G   H
  Vowels     A   E   I   O   U
  Numbers    1   2   3   4   5   6   7
  Odds       1   3   5   7

Then you can run nr_sets.pl like this:
   nr_sets.pl --sets=YOUR_SETS --cutoff=0.5 > NON_REDUNDANT_NAMES

You can also manually generate an overlap file by running:
  sets_overlap.pl -do '   ' -noself -p 0.99 -q  YOUR_SETS  YOUR_SETS  >  YOUR_OVERLAP_OUTPUT
                        ^
                        |
        note, this must be a literal tab!
     (Ctrl-V, tab, to insert on command line)

Output from  nr_sets.pl --all --cutoff=0.5 --sets=YOUR_SETS_EXAMPLE   looks like this:
ACCEPTED        Numbers         0.0000
ACCEPTED        Vowels          0.4000
ACCEPTED        Alphabet        0.0000
REJECTED        Odds            1.0000
REJECTED        Consonants      1.0000
  ^               ^              ^
Status          Set name        Maximum overlap with another set (between 0 and 1)

"Vowels" made it past the 0.5 cutoff, but it would be rejected by a 0.3 cutoff.


CAVEAT:
  The overlap file that is auto-generated is NOT regenerated each time. You will
  need to manually delete it if you want to recalculate the sets.

OPTIONS:

  --sets = SETS_FILE (this is in lists_t.tab format: see the YOUR_SETS example above)
    Note that the sets file is only used to generate an overlap file. After that,
    we just look for the overlap file with the given name. Therefore, if you change
    the sets and want to re-run the program, you MUST DELETE the auto-generated
    overlap file.
  or
  --overlap = OVERLAP_FILE (this is sets_overlap output, when run with -do ' ' (tab))
    (This file will be automatically generated if you supply a sets file only.)

  -v or --invert-match:
    Only prints the REJECTED sets.

  -a or --all:
    Print both rejected AND accepted sets.

  -c or --cutoff = PROPORTION:  (0.5 is default, valid range is 0.0 through 1.0)
    Amount of maximum overlap to allow before excluding a set.
    Note that the size of the SMALLER set is what we use to account for the proportion
    of overlap. So a set with one item has 1.0 proportion overlap with a set that has a million
    items, as long as that one item is in both sets.

  --min = MINIMUM: (default: all sets are accepted)
    Minimum number of genes in accepted pathway. We reject any set with fewer than this many
    items, regardless of anything else.

