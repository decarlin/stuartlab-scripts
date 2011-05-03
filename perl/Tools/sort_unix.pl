#!/usr/bin/perl

#use List::Util 'shuffle';
#@shuffled = shuffle(@list);
# Check out: perldoc -q array

# This is basically just a wrapper to GNU "sort" that adds the option of having a header line.
# It does have one limitation: it can only sort ONE file while dealing with the header properly (whereas GNU sort cats all the command line arguments together).

use POSIX      qw(ceil floor);
use List::Util qw(max min);
use Term::ANSIColor;
use File::Basename;
use Getopt::Long;
require "$ENV{MYPERLDIR}/lib/libsystem.pl";
use strict;
use warnings;
use diagnostics;

sub main();


# ==1==
sub main() { # Main program
	my $delim = "\t";
	my $numHeaderLines = 0;
	
	$Getopt::Long::passthrough = 1; # ignore arguments we don't recognize in GetOptions, and put them in @ARGV

	GetOptions("help|?|man" => sub { printUsageAndQuit(); }
		   , "header|h=s" => \$numHeaderLines
		   , "d=s" => \$delim
	       ) or printUsageAndQuit();

	if (1 == 0) {
	  quitWithUsageError("1 == 0? Something is wrong!");
	}

	my $numUnprocessedArgs = scalar(@ARGV);
	if ($numUnprocessedArgs == 0) {
	    #quitWithUsageError("Error in arguments! You must send exactly one filename to this program. Note that currently you CANNOT pipe data to it through <STDIN>. That should be fixed.\n");
	}

	my $remainingArgsString;
	my $theFileName;

	my $HEADER_FILENAME   = "sortAGW_TEMP_HEADER_FOR_SORTING_DELETE_THIS.tmp";
	my $REMAINDER_FILENAME = "sortAGW_TEMP_SORTED_WITHOUT_HEADER.tmp";
	my $STDIN_FILENAME     = "sortAGW_TEMP_STDIN_FILENAME.tmp";

	$theFileName = $ARGV[-1];

	if (!defined($theFileName) or (not -f $theFileName) ) {
	    $theFileName = $STDIN_FILENAME;
	    $remainingArgsString = join(" ", @ARGV);
	    open (OUT, "> ${STDIN_FILENAME}");
	    while (<STDIN>) {
		print OUT $_;
	    }
	    close(OUT);

	} else {
	    $remainingArgsString = join(" ", @ARGV[0..($#ARGV-1)] );
	}

	#die $theFileName;
	#die $remainingArgsString;

	print STDERR color("yellow");
	print STDERR "STDERR: Sorting begins here: ===============================\n";
	print STDERR color("reset");

	my $sortCommand = "sort -t \'$delim\' $remainingArgsString";
	if ($numHeaderLines > 0) {
	    system("cat $theFileName | head -n $numHeaderLines > $HEADER_FILENAME");
	    system("cat $theFileName | tail -n +" . ($numHeaderLines+1) . " | $sortCommand > $REMAINDER_FILENAME");
	    system("cat $HEADER_FILENAME $REMAINDER_FILENAME"); # <-- this is the final output that the user sees
	    unlink($HEADER_FILENAME); # delete the temp files
	    unlink($REMAINDER_FILENAME); # delete the temp files
	    unlink($STDIN_FILENAME); # delete the temp files
	} else {
	    system("cat $theFileName | $sortCommand");
	}
	
	print STDERR color("green");
	print STDERR "STDERR: Sorting ends here: ===============================\n";
	my $headerStr = "";
	if ($numHeaderLines == 1) { $headerStr = "(with one header line) "; }
	if ($numHeaderLines > 1) { $headerStr = "(with $numHeaderLines header lines) "; }
	print STDERR "STDERR: Finished sorting \"$theFileName\" " . $headerStr . "! Sort command was: $sortCommand\n";
	print STDERR color("reset");
} # end main()


main();


END {
  # Runs after everything else.
  # Makes sure that the terminal text is back to its normal color.
    print STDERR color("reset");
}

exit(0);
# ====

__DATA__

sort_unix.pl  [OPTIONS] [OPTIONS_TO_GNU_SORT]   FILENAME

 * [OPTIONS]: Options for this program (see below)
 * [OPTIONS_TO_GNU_SORT]: Options that are honored by the default unix "sort". "man sort" to see what they are.
 * FILENAME must come *last*.
 * Multiple filenames are not necessarily correctly supported.

by Alex Williams, 2009


This is basically just a wrapper to GNU "sort" that adds the option of having a header line.

It does have one limitation: it can only sort ONE file while dealing with the header properly (whereas GNU sort cats all the command line arguments together).

See the examples below for more information.

CAVEATS:

* The very LAST argument must be the filename to sort.

* Only properly handles ONE file. Beware of passing in multiple files!

* The default delimiter is a TAB. (Unlike UNIX sort, which uses any whitespace.)

* sort -k 1,1 is DIFFERENT from sort -k 1   . (That is also true in UNIX sort.)

OPTIONS:

  --delim or -d = DELIMITER   (Default: tab)
     Sets the file delimiter to DELIMITER.

  Other options are just passed through to GNU sort.

EXAMPLES:

sort_unix.pl somefile

cat somefile | sort_unix.pl -d 'Z' --rev

cat somefile | tail -n 10 | sort_unix.pl --rev


KNOWN BUGS:

  None known

TO DO:

  Nothing yet.


--------------
