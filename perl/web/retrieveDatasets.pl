#!/usr/local/bin/perl -w


use strict;
use warnings;
use diagnostics;
use Getopt::Long;

require "$ENV{MYPERLDIR}/lib/libstats.pl";

sub main();

my $organism = "";
my @headings = ();
my @terms = ();
my $date;
my $minDate = "";
my $maxDate = "";
my $remoteDir = "";
my $datasetNamesFile = "datasets.lst";
my $help;

GetOptions("organism=s" => \$organism,
	   "meshHeadings=s" => \@headings,
	   "searchTerm=s" => \@terms,
	   "date" => \$date,
	   "minDate=s" => \$minDate,
	   "maxDate=s" => \$maxDate,
	   "remoteDir=s" => \$remoteDir,
	   "datasetNamesFile=s" => \$datasetNamesFile,
	   "help" => \$help);

main();

sub main() {

    if($help) {
	print "\n\nThis script uses a set of search terms to download all GEO datasets that have been indexed with those search terms.\n\n";
	print "The user can specify some or all of the following parameters:\n\n ";
	print "\t--organism  => the organism currently has to be specified with the scientific name, such as 'mus musculus' for mouse, or 'homo sapiens' for human\n\n";
	print "\t--meshHeadings => any number of mesh terms as identified by the NCBI searches; before using this, make sure your Mesh Headings are correct\n\n";
	print "\t--searchTerm => any number of any kind of search term, such as 'cancer' or 'lymphoma', etc.\n\n";
	print "\t--date => a command line option that is just a switch and has to be specified if the 'minDate' and 'maxDate' options are to be used\n\n";
	print "\t--minDate => the earliest date that you want datasets from (the format can be YYYY or MM/YYYY)\n\n";
	print "\t--maxDate => the latest date that you want datasets from (the format can be YYYY or MM/YYYY)\n\n";
	print "\t--remoteDir => the full path to the directory where the datasets are to be deposited\n\n";
	print "\t--datasetNamesFile => the file name where all dataset numbers found by the search will be written to\n\n";
	print "Here is an example call to this script: \n\n";
	print "\tretrieveDatasets.pl --organism 'homo sapiens' --meshHeadings 'humans' --searchTerm 'cancer' --remoteDir /projects/sysbio/map/Data/Expression/Any/Geo/Remote --datasetNamesFile datasets.lst --date --minDate 2005/12/31 --maxDate 2006\n";
	exit();
    }


    my $root = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GDS[ETYP]+AND+";
    if($organism =~ m/ /) {
	$organism =~ s/ /\+/g;
    }
    my $organismPortion = $organism . "[orgn]";
    my $connector = "+AND+";
    $root = $root . $organismPortion;
    if($date) {
	my $datePortion = $minDate . ":" . $maxDate . "[PDAT]";
	$root = $root . $connector . $datePortion; ;
    }
    my $i = 0;
    for ($i = 0; $i < scalar(@headings); $i++) {
       	# if there is a space then there are probably 2 words, so need to wrap in quotes
       	if($headings[$i] =~ m/ /) {
	    $root = $root . $connector . "\"" . $headings[$i] . "\"" . "[mh]";
	} else {
	    $root = $root . $connector . $headings[$i] . "[mh]";
	}
    }

    for($i=0; $i < scalar(@terms); $i++) {
	if($terms[$i] =~ m/ /) {
	    $root = $root . $connector . "\"" . $terms[$i] . "\"";
	} else {
	    $root = $root . $connector . $terms[$i];
	}
    }

    $root = $root . "&usehistory=y";
    system("wget '$root' -O inter.tmp");

    my $line = "";
    my $queryKey = "";
    my $webEnv = "";
    my $lineA = "";
    my $lineB = "";

    open(TEMP, "inter.tmp") or die "Can't find intermediate file. Please, make sure the url was constructed correctly.";
    while($line = <TEMP>) {
	chomp($line);
	$lineA = $line;
	$lineB = $line;
	if($lineA =~ m/QueryKey/i) {
	    #Changed by decarlin 5/3/2010
	    $lineA =~ s/^.*\<QueryKey\>//;
	    $lineA =~ s/\<\/QueryKey\>.*$//g;
	    print "here is line A:", $lineA, "\n";
	    #this should leave only one number
	    $queryKey = $lineA;
	  }
	if($lineB =~ m/WebEnv/i) {
	    $lineB =~ s/^.*\<WebEnv\>//g;
	    $lineB =~ s/\<\/WebEnv\>.*$//g;
	    #this should leave just the cookie number
	    $webEnv = $lineB;
	    last;
	}
    }
    print "The query key is: ", $queryKey, "\n";
    print "The cookie thing is: ", $webEnv. "\n";

    close(TEMP);
    #The next step is to construct the eSummary url which will be responsible for getting all the correct files

    my $summaryUrl = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gds&&query_key=";
    $summaryUrl = $summaryUrl . $queryKey . "&WebEnv=" . $webEnv;
    system("wget '$summaryUrl' -O summary.tmp");

    my $gdsID = "";
    my $gplID = "";
    my $datasetUrlRoot = "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/GDS";
    my $platformUrlRoot = "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/by_platform";
    my $datasetUrl = "";
    my $platformUrl = "";
    my @platforms = ();

    open(GDS, "summary.tmp") or die "Can't find summary file";
    open(DAT, '>', $datasetNamesFile) or die "Can't open dataset file";

    while($line = <GDS>) {
	$datasetUrl = "";
	$platformUrl = "";
	chomp($line);
	if($line =~ m/\<Id\>/i) {
	    $line =~ s/^\s+\<Id\>//g;
	    $line =~ s/\<\/Id\>//g;
	    $gdsID = $line;
	    print DAT "GDS", $gdsID, ".soft.gz","\n";
	    $datasetUrl = $datasetUrlRoot . "/GDS" . $gdsID . ".soft.gz";
	    system("wget --retr-symlinks --passive-ftp -Q 0 -N -nd -t 1 -P '$remoteDir' '$datasetUrl'");
	}

	if($line =~ m/\<Item\ Name\=\"GPL\"/) {
	    $line =~ s/^\s+\<Item\ Name\=\"GPL\"\ Type\=\"String\"\>//g;
	    $line =~ s/\<\/Item\>//g;
	    $gplID = $line;
	    if($gplID =~ m/;/) {
		#then there is more than one platform
		@platforms = split(";", $gplID);
		for($i=0; $i < scalar(@platforms); $i++) {
		    $platformUrl = "";
		    $platformUrl = $platformUrlRoot . "/GPL" . $platforms[$i] . "/GPL" . $platforms[$i] . "_family.soft.gz";
		}
	    } else {
		$platformUrl = $platformUrlRoot . "/GPL" . $gplID . "/GPL" . $gplID . "_family.soft.gz";
	    }
	    system("wget --no-clobber --retr-symlinks --passive-ftp -Q 0 -nd -t 1 -P '$remoteDir' '$platformUrl'");
	}
    }
    close(GDS);
    close(DAT);
#    system("rm summary.tmp; rm inter.tmp");

    # assuming that all datasets and platforms have been downloaded correctly,
    # the next step involves putting creating the proper directories for each 
    # dataset, including the correct Network and Umls subdirectories
    # this step will be done by the next script: makeDatasetDirectories.pl
}

