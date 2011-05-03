#!/usr/bin/perl -w

# This program selects the "best" N items with a given key.
# See the DATA below for examples.
# Basically the idea is that you often have a whole lot of
# repeated experiments, and want to compare the "best" run (or runs) of each.

# Join will just find you a random-ish item, but this program
# can be used on the command line to just get the minimum or maximum
# items.

# Note that aggregate.pl is also similar to this, in that it combines the values for similar-key fields.

# By Alex Williams, Nov. 2006.

use POSIX qw(ceil floor);
use List::Util qw(max min);

use strict;
use warnings;

use File::Basename;
use Getopt::Long;

sub main();

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}


# ==1==
sub main() { # Main program
    my ($delim) = "\t"; # default column delimiter
    my ($max) = 0; # set to zero to start (must be zero or else it screws up below!)...
    my ($first) = 0; # set to zero to start
    my ($min) = 0; # also set to zero!
    my ($keyCol) = 1; # default
    my ($valCol) = undef; # undefined to start, but switches to the default value of 2 later
    my ($numBestToPrint) = 1; #default... how many "best" items do we print normally?

    my ($printWarnings) = 1; # warnings are on by default

    my ($numHeaderLines) = 0; # default is no headers

    GetOptions("help|?|man" => sub { printUsage(); }
	       , "delim|d=s" => \$delim
	       , "max" => sub { $max = 1; }
	       , "min" => sub { $min = 1; }
	       , "first" => sub { $first = 1; }
	       , "n=i" => \$numBestToPrint
	       , "k=i" => \$keyCol
	       , "v=i" => \$valCol
	       , "h=i" => \$numHeaderLines
	       , "--nowarn" => sub { $printWarnings = 0; }
	) or printUsage();

    if (($max + $min + $first) != 1) {
	die "You must specify exactly ONE of --max, --min, or --first on the command line.\n";
    }

    if ($first && (!defined($valCol))) {
	die "If you specify --first, the value column is not used to sort. Therefore, do not specify -v=COL! (Remove the -v NUM option from the command line and try again.)\n";
    }

    if (!defined($valCol)) {
	$valCol = 2; # default
    }

    if ($keyCol < 1) { die "select_best_item.pl: Key column ($keyCol) is less than one!\n"; }
    if ($valCol < 1) { die "select_best_item.pl: Value column ($valCol) is less than one!\n"; }

    my $keyIndex = $keyCol - 1;
    my $valIndex = $valCol - 1;

    my @allLines = ();

    my %lineIndex = (); # tells you which line a certain key/value pair is from
    my %allKeys = (); # just a list of all the keys
    my %allVals = (); # this is a hash that holds arrays of values. So it's hash{someKey} is an ARRAY of every value for someKey.

    my $lineNum = 0;
    while (my $theLine = <>) {
	if ($lineNum < $numHeaderLines) {
	    # if it's a header line, then just print it and go to the next line...
	    print $theLine;
	    $lineNum++;
	    next;
	}

	push(@allLines, $theLine);

	chomp($theLine); # removes newlines...
	my @splitLine = split(/$delim/, $theLine);

	my $numItems = scalar(@splitLine);

	my $theKey;
	my $theVal;

	if ($keyIndex >= $numItems) {
	    if ($printWarnings) {
		print STDERR "select_best_item.pl: WARNING: Found a line with only $numItems elements--this means there is no key value! Skipping it.\n";
	    }
	    next;
	} else {
	    $theKey = $splitLine[$keyIndex];
	}

	if ($valIndex >= $numItems) {
	    if ($printWarnings) {
		print STDERR "select_best_item.pl: WARNING: Found a line with only $numItems elements, so there was no sortable value for the given key (therefore, we will pretend that the value for this line was NA). (This could also very likely be a problem that indicates an incorrect value column specified with the -v option, but for now we will treat that as a 'no data' line)...\n";
		print STDERR "Here was the line: " . join(':', @splitLine) . "\n";
	    }
	    $theVal = '';
	} else {
	    $theVal = $splitLine[$valIndex];
	}

	#print "Theval: $theVal, thekey = $theKey\n";

	# Read in all the keys and values.
	# Now go through each key, sort by the values, and print the top N values.

	$allKeys{$theKey} = 1;

	#print "Value: $theVal   Key: $theKey \n";

	if (!defined($allVals{$theKey})) {
	    @{$allVals{$theKey}} = ();
	    @{$lineIndex{$theKey}{$theVal}} = ();
	}
	push(@{$allVals{$theKey}}, $theVal); # For this key, we have one entry with this value
	push(@{$lineIndex{$theKey}{$theVal}}, ($lineNum-$numHeaderLines)); # For this key and value pair, we have one line with (potentially different) other data
	$lineNum++; # this must come AFTER linenum is used!!! The indices will not match up otherwise!
    }

    # Note that the lineIndex array is inherently sorted from least to greatest, because we add the line numbers in ascending order. "Push" adds to the END of an array.

    foreach my $key (keys(%allKeys)) {
	my @sortedValues;

	if ($first) {
	    @sortedValues = @{$allVals{$key}};
	} else {
	    my $grepQuery = '(NA|^$)'; # Grep out anything that's NA or blank!
	    my @NAs = grep {/$grepQuery/} @{$allVals{$key}}; # NAs are special and ALWAYS sort as worst
	    my @realValues = grep {!/$grepQuery/} @{$allVals{$key}};
	    if ($max) { # max: the highest values come first (NA comes at the end)
		@sortedValues = reverse sort {$a <=> $b} @realValues;
	    } elsif ($min) { # min: the lowest values come first (NA comes at the end)
		@sortedValues = sort {$a <=> $b} @realValues;
	    } else {
		die "ERROR. none of --first, --max, and --min were specified.\n";
	    }
	    push(@sortedValues, @NAs); # @NAs are the worst no matter what! So we put them on the end of the soted array.
	}

	for (my $i = 0; $i < $numBestToPrint && $i < scalar(@sortedValues); $i++) {
	    my $thisVal = $sortedValues[$i];
	    my $thisIndex = pop( @{$lineIndex{$key}{$thisVal}} );

	    #print "This index: $thisIndex.    This val:  $thisVal  \n";

	    if (!defined($thisIndex)) {
		die "select_best_item.pl: Curious error in select_best_item.pl... there should not be any undefined elements in the index array!";
	    }
	    # Note that in the case of tied key-value pairs,
	    # we print the ones we found EARLIER in the
	    # file. This is a natural consequence of adding
	    # the items to the array in line number order.
	    if (defined($allLines[$thisIndex])) {
		print $allLines[$thisIndex];
	    }
	}
    }

} # end main()


main();
exit(0);
# ====

__DATA__

select_best_item.pl [OPTIONS] (--max|--min|--first) -n=(number to print) -k=(key column) -v=(value column) < [FILE]

    Selects the maximum (or minimum) values associated with
    a given key.

    Note that the value NA and completely blank values are
    special and always sorts as worst, no matter what.


    You must specify --min or --max to tell this script
	whether you want the n *smallest* items or the n
	*largest* items.


    It reads from STDIN, or the first unprocessed argument
    specified if that is a file name. For example:


    cat the_file | select_best_item.pl -max
    will work, as will
    select_best_item.pl -max the_file


    It prints out the entire line for the "best" items, and
    does not print any lines that are not in the top n. This
    is useful if you want to pick out the best experiment(s)
    only, from a list of repeats.

    In the event of ties--where a particular key has several
    entries with the same value--when you have specified *n*
    items to print for each entry, the EARLIER *n* lines are
    printed, and the later ones are ignored.


# Note: This program is very similar to topk.pl.
# So check that out if you find that this program doesn't support the functionality
# you are looking for.

OPTIONS:

    --max or --min or --first : For each KEY, select the
    	line(s) with the MAXIMUM (--max) or MINIMUM (--min)
    	values. You must specifiy either max or min on the
    	command line. --first just prints the first value
    	found in the file, without any sorting.


    Blank values and the hard-coded value NA (capitalized!)
    always sort as the worst, whether in --max or --min (but
    not in --first). Other non-numeric values will confuse
    this program! Replace all NDs and N/As with NA before
    you run this program on it!

    -h=NUMBER (default: 0) : Number of header lines. Default
    	is 0. Specify with -h=0 or just plain -h 0.

    -n=NUMBER (default: 1) : Prints out the best n lines for
	each key, where "best" means that the value
	associated with that particular line is among the n
	minimum or n maximum values for that key. Defaults
	to 1.


    -d=DELIMITER or --delim=DELIMITER (default is a tab)
	Sets the column delimiter to DELIMITER. --delim=','
	would read a comma-delimited file, as an example.


    -k=NUM (default: 1) (this is the column with the name of
	the item) Sets the KEY column to column NUM. The
	first column is column 1 (not zero). Among items
	with the same KEY, we are looking for the "best"
	items (the ones with the best values).


    -v=NUM (default: 2) : This is the column with numeric
    	sortable data. Sets the VALUE column to column NUM.
    	The first column is column 1 (not zero). We look
    	through the value columns to figure out which items
    	to keep, and which to discard, based on the
    	numerical value. So if you had a bunch of country
    	names in column 3, province names in column 4, and
    	the land area of each province in column 8, you
    	might try: select_best_item.pl --max -k 3 -v 8



Example:

	If the file "the_file.tab" is a tab-delimited file as follows:

	A	1
	A	2	some value	another value
	A	3
	B	1
	B	2	a thing	something
	B	NA

Then select_best_item.pl -k=1 -v=2 --max the_file.tab will print to
	standard out:

	A	3
	B	2	a thing	something

	Note that the output order is not particularly specified, so you
	may want to sort the output.

Also note that NA is a special "worst" value that sorts as
the worst no matter what, when using --max or --min (but not --first).
