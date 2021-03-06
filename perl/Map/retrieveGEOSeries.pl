#!/usr/local/bin/perl -w

#####################################
# 
# retrieveGEOSeries.pl
# 
# #####################
#
# Author: Daniel Sam
# Lab: Josh Stuart, BME, UCSC
#
# Date:
#
#####################################

use strict;
use warnings;
use diagnostics;
use Getopt::Long;

require "$ENV{MYPERLDIR}/lib/libstats.pl";

sub main();

my $organism = "";
my @headings = ();
my @terms = ();
my $sampleSrc = "";
my $sampleType = "";
my $date;
my $minDate = "";
my $maxDate = "";
my $platFormType = "";
my $remoteDir = "";
my $datasetNamesFile = "datasets.lst";
my $published_flag = 0;
my $userOverride = undef;
my $help;
my $gds=0;

#edit: Daniel Carlin 5/26/2010  Added a flag --gds to return only gds files rather than gse's

GetOptions("organism=s" => \$organism,
	   "meshHeadings=s" => \@headings,
	   "searchTerm=s" => \@terms,
	   "sampleSrc=s" => \$sampleSrc,
	   "sampleType=s" => \$sampleType,
	   "date" => \$date,
	   "minDate=s" => \$minDate,
	   "maxDate=s" => \$maxDate,
	   "platFormType=s" => \$platFormType,
	   "remoteDir=s" => \$remoteDir,
	   "datasetNamesFile=s" => \$datasetNamesFile,
	   "published=s" => \$published_flag,
	   "override=s" => \$userOverride,
	   "help" => \$help,
	   "gds" => \$gds);


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

    my $i;
    my $root;
    if ($gds)
    {
	$root = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=";
    }
    else
    {
	$root = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GSE[ETYP]+AND+";
    }

    if(defined($userOverride)) {
       $root .= $userOverride;
    }
    else {
       if($organism =~ m/ /) {
	   $organism =~ s/ /\+/g;
       }
       my $organismPortion = $organism . "[ORGANISM]";
       my $connector = "+AND+";
       $root = $root . $organismPortion;
     
       if($sampleSrc) {
          if($sampleSrc =~ m/ /) {
	      $sampleSrc =~ s/ /\+/g;
          }
          $root = $root . $connector . $sampleSrc . "[sample+source]";
       }
    
       if($sampleType) {
          $sampleType =~ s/ /\+/g;
          $root = $root . $connector . $sampleType . "[sample+type]";
       }

       if($date) {
	   my $datePortion = $minDate . ":" . $maxDate . "[PDAT]";
	   $root = $root . $connector . $datePortion; ;
       }

       if($platFormType) {
          $platFormType =~ s/ /\+/g;
          $root = $root . $platFormType . "[Platform+Technology+Type]";
       }

       $i = 0;
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
	     $root = $root . $connector . "\"" . $terms[$i] . "\"[mt]";
	  } else {
	    $root = $root . $connector . $terms[$i] . "[mt]";
	  }
       }
    }
#$remoteDir = "/projects/sysbio/users/dsam/Map/Collaboration/NormLee/BreastCancer_metastatic_and_nonmetastatic/Map/Data/Expression/Any/Geo";
#$root="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GSE[ETYP]+AND+human[ORGANISM]+AND+(colon[mt]+OR+colorectal[mt])";

    $root = $root . "&usehistory=y";
print $root,"\n";

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
	    #this should leave only one number
	    ($queryKey) = $lineA =~ /<QueryKey>(.*)<\/QueryKey>/;
	  }
	if($lineB =~ m/WebEnv/i) {
	    #this should leave just the cookie number
	    ($webEnv) = $lineB =~ /<WebEnv>(.*)<\/WebEnv>/;
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
    my $gseID = "";
    my $gplID = "";
    #my $datasetUrlRoot = "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/GDS";
    my $datasetUrl = "";
    my $platformUrlRoot = "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/by_platform";
    my $datasetUrlRoot = "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/SOFT/by_series/GSE";
    my $platformUrl = "";
    my @platforms = ();
    my $pubmed_flag = 0;
    open(GDS, "summary.tmp") or die "Can't find summary file";
    open(DAT, '>', $datasetNamesFile) or die "Can't open dataset file";

    while($line = <GDS>) {
       #$datasetUrl = "";
	$platformUrl = "";
	chomp($line);
	if($line =~ /<Item Name=\"GSE\".*>(.*)<\/Item>/) {
	   $gseID = $1;
	   print DAT ">GSE$gseID", "_family.soft.gz", "\n";
	   $datasetUrl = $datasetUrlRoot . $gseID . "/GSE" . $gseID . "_family.soft.gz";

	   if(!$published_flag) {
	      system("wget --retr-symlinks --passive-ftp -Q 0 -N -nd -t 1 -P '$remoteDir' '$datasetUrl'");
	  }
	}

	if($line =~ /<Item Name=\"PubMedIds\" Type=\"List\"><\/Item>/) {
	   $pubmed_flag = 0;
	   print DAT "NA\n";
	}
	elsif($line =~ /\"PubMedIds\"/) {
	   $pubmed_flag = 1;
	}
	elsif($pubmed_flag) {
	   if($line =~ /<Item Name=\"int\" Type=\"Integer\">(\d+)<\/Item>/) {
	      print DAT "$1\n";
	      if($published_flag) {
		 system("wget --retr-symlinks --passive-ftp -Q 0 -N -nd -t 1 -P '$remoteDir' '$datasetUrl'");
	     }
	   }
	   $gseID = "";
	}
	elsif($line =~ /^\s*<\/Item>/) {
	   $pubmed_flag = 0;
	   $gseID = "";
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
	    #system("wget --no-clobber --retr-symlinks --passive-ftp -Q 0 -nd -t 1 -P '$remoteDir' '$platformUrl'");
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

