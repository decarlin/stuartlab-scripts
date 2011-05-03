#!/usr/bin/perl

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
}

my $exe = "$ENV{MYPERLDIR}/lib/map_learn";

my $gx_file = $ARGV[0];

my $r = int(rand(100000));
my $tmp_xml = "/tmp/tmp_$r.xml";
my $tmp_clu = "/tmp/tmp_$r.clu";
open(XML, ">$tmp_xml");

print XML "<MAP>\n";
print XML "  <RunVec>\n";
print XML "    <Run Name=\"Eval\">\n";
print XML "      <Step Name=\"LoadFromGeneXPress\" Type=\"GeneXPress\">\n";
print XML "        <Microarray Name=\"Generic\" File=\"$gx_file\">\n";
print XML "        </Microarray>\n";
print XML "      </Step>\n";
print XML "      <Step Name=\"PrintClusters\" Type=\"GeneXPress\" FormatType=\"Cluster\">\n";
print XML "        <Microarray Name=\"Generic\" OutputFile=\"$tmp_clu\">\n";
print XML "        </Microarray>\n";
print XML "      </Step>\n";
print XML "    </Run>\n";
print XML "  </RunVec>\n";
print XML "</MAP>\n";

`$exe $tmp_xml >& /dev/null`;

system("cat $tmp_clu");

`rm $tmp_clu`;
`rm $tmp_xml`;

exit(0);

__DATA__

extract_clusters.pl <GeneXPress file>

   Calls the executable map_learn on the GeneXPress file to
   produce all the gene lists from it.
