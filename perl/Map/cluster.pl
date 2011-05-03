#!/usr/bin/perl

use strict;

if($#ARGV == -1)
{
  print STDOUT <DATA>;
  exit(0);
}

my $exe = "$ENV{MYPERLDIR}/lib/map_learn";

my $maxiter = 10;
my $K = '';
my $file = '';
my $metric = 'Euclidean';
my $precision = 3;
my $row_headers = 1;
my $col_headers = 1;
my $key_col = 1;
my $verbose = 1;
my $preprocess = 'None';
my $method = 'K-means';
my $maxmerges = 10;
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
  elsif($arg eq '-method')
  {
    $method = shift @ARGV;
  }
  elsif($arg eq '-maxiter')
  {
    $maxiter = shift @ARGV;
  }
  elsif($arg eq '-maxmerges')
  {
    $maxmerges = shift @ARGV;
  }
  elsif($arg eq '-metric')
  {
    $metric = shift @ARGV;
  }
  elsif($arg eq '-precision')
  {
    $precision = shift @ARGV;
  }
  elsif($arg eq '-preprocess')
  {
    $preprocess = shift @ARGV;
  }
  elsif($arg eq '-rowheaders')
  {
    $row_headers = shift @ARGV;
  }
  elsif($arg eq '-colheaders')
  {
    $col_headers = shift @ARGV;
  }
  elsif($arg eq '-key')
  {
    $key_col = shift @ARGV;
  }
  elsif(length($K)==0)
  {
    $K = $arg;
  }
  elsif(length($file)==0)
  {
    $file = $arg;
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}
$key_col--;

my $domain = '';
for(my $i=1; $i<=$K; $i++)
{
  $domain .= ($i>1) ? ";$i" : "$i";
}
if(length($domain)==0)
{
  $domain = '1';
}

(-f $file) or die("File '$file' is not a regular file.");

my $r = int(rand(100000));
my $tmp_xml = "/tmp/tmp_$r.xml";
my $tmp_txt = "/tmp/tmp_$r.txt";
open(XML, ">$tmp_xml") or die("Could not create temporary XML driver file '$tmp_xml'");

print XML "<MAP>\n",
          "  <MicroarraySet>\n",
          "    <Microarray Name=\"microarray\" Species=\"none\" File=\"$file\"\n",
          "      RowHeaders=\"$row_headers\" ColHeaders=\"$col_headers\" KeyCol=\"$key_col\">\n",
          "    </Microarray>\n",
          "  </MicroarraySet>\n",
          "  <AttributeGroupSet>\n",
          "    <AttributeGroup Name=\"modules\" Type=\"GeneAttributes\" ValueDomain=\"$domain\">\n",
          "      <Attribute Name=\"g_module\">\n",
          "      </Attribute>\n",
          "    </AttributeGroup>\n",
          "  </AttributeGroupSet>\n",
          "  <RunVec>\n",
          "    <Run Name=\"cluster\">\n",
          "      <Step Name=\"load\" Type=\"LoadMicroarray\" MicroarrayName=\"microarray\"\n",
          "        PreProcess=\"$preprocess\">\n",
          "      </Step>\n",
          "      <Step Name=\"cluster\" Type=\"Cluster\"\n",
          "        MicroarrayName=\"microarray\" AttributeGroup=\"modules\" TargetAttribute=\"g_module\"\n",
          "           Method=\"$method\" Metric=\"$metric\" NumClusters=\"$K\"\n",
          "        MaxIterations=\"$maxiter\"\n",
          "        MaxMergesPerNode=\"$maxmerges\">\n",
          "      </Step>\n",
          "      <Step Name=\"print\" Type=\"PrintMicroarray\"\n",
          "        MicroarrayName=\"microarray\"\n",
          "        Attribute=\"g_module\"\n",
          "        Precision=\"$precision\" OutputFile=\"$tmp_txt\">\n",
          "      </Step>\n",
          "    </Run>\n",
          "  </RunVec>\n",
          "</MAP>\n";
close(XML);

my $cmd = "$exe $tmp_xml" . ($verbose ? '' : '>& /dev/null');

`$cmd`;

system("cat $tmp_txt");

`rm $tmp_txt`;
`rm $tmp_xml`;

exit(0);

__DATA__
syntax: map_kmeans.pl [OPTIONS] K TABFILE

K - number of clusters

TABFILE - tab-delimited file with 1 row and 1 column header.

OPTIONS are:

-q: Quiet mode: turn verbosity off (default is verbose)
-rowheaders N: Set the number of row headers to N (default 1)
-colheaders N: Set the number of column headers to N (default 1)
-key N: Set the key column to N (default 1)
-method METHOD: Set the clustering method to METHOD.  Legal values are:

      K-means (default)
      Hierarchical

-metric METRIC: set the metric to METRIC.  Legal values are:

      Euclidean (default)
      PCluster

-maxiter N: Set the maximum number of iterations to N (default is 10).  (K-means only)
-maxmerges N: Set the maximum merges per node to N (default is 10).  (Hierarchical only)
-precision N: Set the precision to N decimal places (default is automatic).  Setting to 0 makes
              precision automatic.
-preprocess TRANSFORM: Subject the data to the preprocessing specified in TRANSFORM.  Legal values are:

      None (default)
      ZeroTransform
      ZeroTransformGenes
      ZeroTransformExperiments
      CenterTransformGenes
      CenterTransformExperiments
      ScaleTransformGenes
      ScaleTransformExperiments
      RankTransformGenes
      RankTransformExperiments

