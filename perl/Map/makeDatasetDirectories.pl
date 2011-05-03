#!/usr/local/bin/perl -w


use strict;
use warnings;
use diagnostics;
use Getopt::Long;

require "$ENV{MYPERLDIR}/lib/libstats.pl";

sub main();

my $listOfDatasets = "";
my $sourceDir = "";
my $tempOutputFile = "";
my $outputDir = "";
my $modes;
my $umls;
my $network;
my $searchName = "";
my $log = "";
my $help;

GetOptions("listOfDatasets=s" => \$listOfDatasets,
	   "sourceDir=s" => \$sourceDir,
	   "tempOutputFile=s" => \$tempOutputFile,
	   "outputDir=s" => \$outputDir,
	   "modes" => \$modes,
	   "umls" => \$umls,
	   "network" => \$network,
	   "searchName=s" => \$searchName,
	   "log=s" => \$log,
	   "help" => \$help);

main();

sub main() {

    if($help) {
	print "\n\nThis script is not to be used by itself but in conjunction with the 'retrieveDatasets.pl' script. While the other script downloads all scripts associated with a given search,";
	print " this script sets up all the directories for the data, network, modes and umls and structure for those. Besides creating directories, this script also sets up a directory for this ";
	print "search under the Categories sub directory in each organism's directory. It also creates soft links to the dataset directories, so that the user knows which datasets came up under this ";
	print "search\n\n";
	print "Here are the available command line options: \n\n";
	print "\t--listOfDatasets => a file name that's the list of the datasets found in the search performed with 'retrieveDatasets.pl'\n\n";
	print "\t--sourceDir => the path to the directory where the datasets can be actually found\n\n";
	print "\t--tempOutputFile => a file name for temporary pubmed search output\n\n";
	print "\t--outputDir => the path to the directory where you want the directories to be setup: usually this is in /map/Data/Expression/SomeOrganism\n\n";
	print "\t--modes => an option that's a switch, if the user wants modes to be run within the newly created directories\n\n";
	print "\t--umls => an option that's a switch, if the user wants umls/mmtx to be run within the newly created directories\n\n";
	print "\t--network => an option that's a switch, if the user wants a network to be run and created within the newly created directories\n\n";
	print "\t--searchName => this is the name under which this search will be recorded in the Categories directory (the name with which this search will be associated\n\n";
	print "\t--log => a file name where all 'failed' datasets for which directories could not be created were written to\n\n";
	print "Here is an example call to the script: \n\n";
	print "\tmakeDatasetDirectories.pl --listOfDatasets datasets.lst --sourceDir /projects/sysbio/map/Data/Expression/Any/Geo/Remote --tempOutputFile authors.tmp --outputDir /projects/sysbio/map/Data/Expresion/Human --network --searchName '2006' --log log.txt\n\n";
	exit();
    }
    my $line = "";
    my $file = "";
    my $result = "";
    my $pubmedID = "";
    my $urlBase  = "http://www.ncbi.nlm.nih.gov/sites/entrez?Db=Pubmed&term=";
    my @ids = ();
    my $url = "";
    my $authorListInfo = "";
    my $author = "";
    my $titleInfo = "";
    my $year = "";
    my %datasets = ();

    my $searchDir = $outputDir . "/Categories/" . $searchName;
    system("mkdir $searchDir");

    my $logFileName = $searchDir . "/" . $log;

    open(DATA, $listOfDatasets);
    open(LOG, ">>", $logFileName);

    $result = "";

    while($line = <DATA>) {
	chomp($line);
	$file = $sourceDir . "/" . $line;
	$result = `zcat $file | grep -i '\!dataset_pubmed_id'`;
	# get the pubmed ids so that the authors names can be picks up from the sites
	# @ids = split(" = ", $result);
	$result =~ m/(\d{1,8})/;
	$pubmedID = $1;
	#$pubmedID = $ids[1];

	# here I need to deal with the multiple datasets to a paper problem
	if($pubmedID) {
	    $datasets{$pubmedID}{$line} = $line;
	} else {
	    print LOG $line, "\n";
	}
    }
    close(DATA);
    close(LOG);

    my $paper = "";

    foreach $paper (sort keys %datasets) {

	$author = "";
	$authorListInfo = "";
	$titleInfo = "";
	$year = "";
	$url = "";
	my $fullPath = "";
	my $dirName = "";
	my $nameForSoftLink = "";

	$url = $urlBase . $paper . "[UID]";
	# now we have to run the pubmed id to get the page
	$result = `wget '$url' -O $tempOutputFile`;
	$authorListInfo = `grep -i 'AuthorList' $tempOutputFile`;
	$authorListInfo =~ m/Term=\%22([^%]*)\%20([^%]*)\%22\%5BAuthor\%5D/;

	$author = $1;

	$titleInfo = `grep -i '<title>' $tempOutputFile`;
	$titleInfo =~ m/\[.*([1-2][0-9][0-9][0-9])\]/;
	$year = $1;

	my @digits = split("", $year);
	my $newYear = $digits[2] . $digits[3];

	$dirName = $author . $newYear . "_" . $paper;
	chomp($dirName);
	$fullPath = $outputDir . "/" . $dirName;

	$nameForSoftLink = $searchDir . "/" . $dirName;

	unless(-d $fullPath) {
	    system("mkdir $fullPath");
	    system("mkdir $fullPath/Network");
	    system("mkdir $fullPath/Network/Corr");
	    system("mkdir $fullPath/Network/Corr/Modes");
	    system("mkdir $fullPath/Umls");


	    system("ln -s /projects/sysbio/map/Templates/Make/geo.mak $fullPath/Makefile");
	    system("ln -s /projects/sysbio/map/Templates/Make/network_corr.mak $fullPath/Network/Corr/Makefile");
	    system("ln -s /projects/sysbio/map/Templates/Make/modes.mak $fullPath/Network/Corr/Modes/Makefile");
	    system("ln -s /projects/sysbio/map/Templates/Make/geo_umls.mak $fullPath/Umls/Makefile");

	    #need to make a datasets.fa file
	    # THIS is where the multiple datasets per paper information has to go
	    my $set = "";

	    my $datasetsFile = $fullPath . "/datasets.fa";
	    open(DATASETS, ">", $datasetsFile);

	    foreach $set (keys %{$datasets{$paper}}) {
		# so now if there is only one dataset per paper this gets executed only once
		$file = $sourceDir . "/" . $set;
		$result = `zcat $file | grep -i '!dataset_platform' | grep -v 'organism' | grep -v 'technology'`;
		chomp($result);
		@ids = split(" = ", $result);
		my $platform = $ids[1];

		print DATASETS ">", $platform, "\n";
		print DATASETS "GB_ACC->Genbank:Refseq\n";
		@ids  = split(/\./, $set);
		my $gdsID = $ids[0];
		print DATASETS $gdsID, "\n";
	    }

	    close(DATASETS);
	    system("cd $fullPath; make data.tab; cd ..");
	    # this should be sufficient to create the expression matrix
	    # the next step is to create the network and umls files
	    if($network) {
		system("cd $fullPath/Network/Corr; make; cd ../..");
	    }
	    if($modes) {
		system("cd $fullPath/Network/Corr/Modes; make; cd ../../..");
	    }
	    if($umls) {
		system("cd $fullPath/Umls; make data.tab.gz; cd ..");
	    }
	}
	system("ln -s $fullPath $nameForSoftLink");
    }
}

