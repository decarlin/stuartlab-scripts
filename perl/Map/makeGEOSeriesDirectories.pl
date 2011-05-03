#!/usr/local/bin/perl -w

###################
#
# makeGEOSeriesDirectories.pl
#
###################
#
# Author: Daniel Sam
# Lab: Josh Stuart, BME, UCSC
#
# Date:
#
# ##############################

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
    my $author_f = "";
    my $author_m = "";
    my $author_l = "";
    my $titleInfo = "";
    my $year = "";
    my %datasets = ();

    my $searchDir = $outputDir . "/Categories/" . $searchName;
    system("mkdir -p $searchDir");

    my $logFileName = $searchDir . "/" . $log;

    open(DATA, $listOfDatasets);

    $result = "";

    while($line = <DATA>) {
	chomp($line);
        my @x = split('\t', $line, -1);

#print $pubmedID, "\n";
        for(my $i=1; $i<scalar @x; $i++) {
	   $datasets{$x[0]}{$x[$i]} = ();  #datasets{pubmedID}{GEOseries}  # can have multiple series per paper
	}
    }
    close(DATA);

    foreach my $paper (sort keys %datasets) {
print ">", $paper, "\n";
	$author = "";
	$author_f = "";
	$author_m = "";
	$author_l = "";
	$authorListInfo = "";
	$titleInfo = "";
	$year = "";
	$url = "";
	my $fullPath = "";
	my $dirName = "";
	my $nameForSoftLink = "";
  
	if($paper =~ /NA/) {
	  my @gse = keys %{$datasets{$paper}}; # should only be one gse for unpublished  TODO can have more than one
          my $file = $sourceDir . "/" . $gse[0];
	  my $result = `zcat $file | perl -n -e 'if(/^\!Series_contact_name|^\!Series_submission_date/) {print;}'`;
	  #my $result = `zcat $file | grep "^\!Series_contact_name"`;
	  #($author) = $result =~ /\!Series_contact_name = .*,.*,(.*)/;
	  print "RESULT:$result\n";
	  ($author_f,$author_m,$author_l) = $result =~ /\!Series_contact_name = (.*),(.*),(.*)/;
	  ($year) = $result =~ /\!Series_submission_date = .* (\d\d\d\d)/;
	  $author =~ s/ /-/g;
	  $author_f =~ s/ /-/g;
	  $author_m =~ s/ /-/g;
	  $author_l =~ s/ /-/g;
	  $author_f =~ s/[^[:ascii:]]//g;
	  $author_m =~ s/[^[:ascii:]]//g;
	  $author_l =~ s/[^[:ascii:]]//g;

	  print "$file\n$result";
	  print "\t$author_l.$author_f.$author_m\t$year\n";
	  my @digits = split("", $year);
	  my $newYear = $digits[2] . $digits[3];
	  $dirName = "$author_l.$author_f.$author_m" . $newYear . "_NA";
	  print "$dirName\n";
	  #last;
	}
	else {
	  $url = $urlBase . $paper . "[UID]";
	  # now we have to run the pubmed id to get the page
	  $result = `wget '$url' -O $tempOutputFile`;
	  #$authorListInfo = `grep -i 'AuthorList' $tempOutputFile`;
	  $authorListInfo = `grep -i '%22%5BAuthor%5D' $tempOutputFile | head -1`;
print "AUTHORLIST:$authorListInfo","\n";
	  $authorListInfo =~ m/Term=\%22([^%]*)\%20([^%]*)\%22\%5BAuthor\%5D/i;
	  #($author,$author_f) =~ m/Term=\%22([^%]*)\%20([^%]*)\%22\%5BAuthor\%5D/;
          $author = "";
	  $author = $1;

	  if(!defined($1)) {
	     $authorListInfo =~ s/.*?Term=\%22(.*?)\%22\%5BAuthor\%5D.*/$1/;
	     #$authorListInfo =~ s/\%CC\%81//;
	     print "$authorListInfo\n";
             ($author,$author_f) = $authorListInfo =~ m/(.*)\%20(.*)/;
	     $author =~ s/\%CC\%81//g;
	     $author =~ s/\%CC\%//g;
	     $author =~ s/\%//g;
	     $author =~ s/\d//g;
	  }

print "author: ",$author,"\n";
          $author =~ s/ //g;
	  $author =~ s/[^[:ascii:]]//g;
	  #$author = s/[^\w\W-\.]//g;
print $author,"\n";
	  $titleInfo = `grep -i '<title>' $tempOutputFile`;
	  $titleInfo =~ m/\[.*([1-2][0-9][0-9][0-9]).*\]/;
	  $year = $1;
print $year,"\n";
	  my @digits = split("", $year);
	  $" = '';
	  my $newYear = $digits[2] . $digits[3];
	  #my $newYear = "@digits";
	  $" = " ";

	  $dirName = $author . $newYear . "_" . $paper;
	  chomp($dirName);
       }
	$fullPath = $outputDir . "/" . $dirName;

	$nameForSoftLink = $searchDir ;#. "/" . $dirName;

print $dirName, "\n";
print $nameForSoftLink,"\n";
print $fullPath,"\n";
#die;
my $cwd = `pwd`;
#if(1) {
#unless(-d $fullPath) {
        if(-d $outputDir and 
	   $dirName ne "") {
print "TEST\n";

	    system("mkdir -p $fullPath/Network/Corr/Modes");
	    system("mkdir -p $fullPath/Umls");
	    system("ln -s /projects/sysbio/Map/Templates/Make/GEO/geo_series.mak $fullPath/Makefile");

	    #system("ln -s /projects/sysbio/map/Templates/Make/geo.mak $fullPath/Makefile");
	    #system("ln -s /projects/sysbio/map/Templates/Make/network_corr.mak $fullPath/Network/Corr/Makefile");
	    #system("ln -s /projects/sysbio/map/Templates/Make/modes.mak $fullPath/Network/Corr/Modes/Makefile");
	    #system("ln -s /projects/sysbio/map/Templates/Make/geo_umls.mak $fullPath/Umls/Makefile");

	    #need to make a datasets.fa file
	    # THIS is where the multiple datasets per paper information has to go
	    my $set = "";

	    my $datasetsFile = $fullPath . "/geo_gse.tab";
	    open(DATASETS, ">>", $datasetsFile);

	    foreach $set (keys %{$datasets{$paper}}) {
		# so now if there is only one dataset per paper this gets executed only once
		#$file = $sourceDir . "/" . $set;
		#$result = `zcat $file | grep -i '!dataset_platform' | grep -v 'organism' | grep -v 'technology'`;
		chomp($result);
		#@ids = split(" = ", $result);
		my $platform = $ids[1];
print $set,"\n";
my ($gseID) = $set =~ /(GSE\d+)_.*/;
system("mkdir -p $fullPath/$gseID");
	    system("mkdir -p $fullPath/$gseID/Network/Corr/Modes");
	    system("mkdir -p $fullPath/$gseID/Umls");
	    system("mkdir -p $fullPath/$gseID/Annotation");
	    system("ln -s /projects/sysbio/Map/Templates/Make/GEO/geo_gse.mak $fullPath/$gseID/Makefile");
	    ##  system("cd $fullPath/$gseID; make; cd $cwd");

print DATASETS $gseID, "\n";
#print DATASETS "GB_ACC->Genbank:Refseq\n";
		#@ids  = split(/\./, $set);
		#my $gdsID = $ids[0];
		#print DATASETS $gdsID, "\n";
	    }

	    close(DATASETS);
            
	    unless(-e $datasetsFile) {
	      system("rm -f $fullPath/geo_gse.tmp ; uniq.pl -f 1 $datasetsFile > $fullPath/geo_gse.tmp ;  mv $fullPath/geo_gse.tmp $datasetsFile");
	    
	    # WARNING possible mistake
	    # assume downloaded GSE is the same as already existing GSEs in Author dir or is not
	    # another additional GSE that hasn't already been downloaded in Author dir
	    # fix is remove (touch) but then may have to re-make the data.tab and sample.tab.gz files
	      system("cd $fullPath; make series_sample_desc.tab; touch -c *; cd $cwd");
	      #system("make data.tab");
            
	      #system("cd $fullPath; make; cd ..");
	    }
	    # this should be sufficient to create the expression matrix
	    # the next step is to create the network and umls files
	    #if($network) {
	    #system("cd $fullPath/Network/Corr; make; cd ../..");
	    #}
	    #if($modes) {
	    #system("cd $fullPath/Network/Corr/Modes; make; cd ../../..");
	    #}
	    #if($umls) {
	    #system("cd $fullPath/Umls; make data.tab.gz; cd ..");
	    #}

	    system("ln -s $fullPath $nameForSoftLink");
	}
#}
	
    }
}

