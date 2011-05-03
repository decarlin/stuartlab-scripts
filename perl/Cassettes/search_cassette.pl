#!/usr/bin/perl

use CGI qw(:standard);
use CGI;

use strict;

# use lib '/home/httpd/lib';
# use Kimlab qw (KimlabMember ProteomeStatement);

print header;

my $query = new CGI;

# Get the parameters from the CGI object:
my $submit        = param('submit');
my $gene_names    = param('gene_names');
my $organism      = param('organism');
my $label         = param('label');

# Set some data information
my ($url_prefix,$url_suffix) = &getUrl($organism);

if(not(param))
{
   &printForm();
}
else
{
   if($gene_names)
   {
      &computeCassette($organism, $gene_names, $label, $url_prefix, $url_suffix);
   }
   else
   {
      print b((font({-color=>'red', size=>4},"error: Please, enter a genelist!"))), br;
      &printForm();
   }
}


##-------------------------------------------------------------------------------------------
##
##-------------------------------------------------------------------------------------------
sub printForm
{

   print start_html('Enter Genelist'),

        "<body bgcolor=\"lightblue\">\n",

            $query->start_form,

            b("Enter your query list of ORF names:"), br,

            textarea(-name=>'gene_names',
                         -rows=>10,
                         -cols=>30,
                         -wrap=>'soft'), br,

            $query->p(
                   "<b>Organism</b>:",br,
                           "<input type=radio name=organism value=worm checked>",
                           "<i>C. elegans</i>",br,
                           "<input type=radio name=organism value=yeast>",
                           "<i>S. cerevisiae</i>",br,
                   br, br,

                           # "<input type=checkbox name=label value=1>",
                           # "Would you like the genes from your list to be labeled? ",br,br,

                           submit(-name=>'submit',
                                     -value=>'Find Cassette')),
      $query->end_form,
      br, br,
      "<center><i>",
      "Please send any questions/comments to ",
      "<a href=\"mailto:jstuart\@stanford.edu\">",
      "Josh Stuart",
      "</a></i></center>";
}

##-------------------------------------------------------------------------------------------
##
##-------------------------------------------------------------------------------------------
sub computeCassette
{
   # read data file into a hash
   my ($organism, $gene_names, $label, $url_prefix, $url_suffix) = @_;

   # Extract the user's list of genes:
   my $query_genes = &readGeneList($gene_names);

   my @summary;

   # Hits.
   my @hits;
   my %best;
   my %middle;

   # Annotations.
   my ($annotation_name, $annotations) = &readAnnotations($organism);
   
   # Open a pipe for sending the genes to the cassette finder:
   my $tmp_query_file = "tmp/__query_" . join('_',split(' ',`date`)) . "_key_" . $$;
   system("mkdir -p tmp; chmod 777 tmp");

   # Write the query genes to the temporary file.
   open(QUERY_FILE, ">$tmp_query_file") or die("Could not open query file '$tmp_query_file'");
   foreach my $query_gene (keys(%{$query_genes}))
      { print QUERY_FILE "$query_gene\n"; }
   close(QUERY_FILE);

   if(open(RESULTS, "bin/client_cassettes.pl $tmp_query_file $organism tmp |"))
   {
      while(<RESULTS>)
      {
         chop;
         my @tuple = split("\t");
         if($tuple[0] =~ /^WORST-HIT\s+\d+:/i)
         {
            shift(@tuple);
            my ($query_index, $orf, $score) = @tuple;
            push(@hits, "$query_index\t$orf\t$score");
         }
         elsif($tuple[0] =~ /^BEST-HIT\s+\d+:/i)
         {
            shift(@tuple);
            my ($query_index, $orf, $score) = @tuple;
            $best{$orf} = 1;
         }
         elsif($tuple[0] =~ /^MIDDLE-HIT\s+\d+:/i)
         {
            shift(@tuple);
            my ($query_index, $orf, $score) = @tuple;
            $middle{$orf} = 1;
         }
         elsif(not($tuple[0] =~ /^HIT\s+\d+:/))
         {
            push(@summary, $_);
         }
      }

      # Print out summary information.
      print "<table border=\"true\">\n",
            "   <tr bgcolor=\"black\">\n",
            "      <td><font color=\"white\">Summary Data</font></td>\n",
            "      <td><font color=\"white\">Value</font></td>\n",
            "   </tr>\n";
      
      foreach $_ (@summary)
      {
	 if(/\S/)
	 {
	    my ($data,$value) = split("\t",$_);
	    print "   <tr>\n",
	          "      <td>$data</td>\n",
	          "      <td><font color=\"red\">$value</font></td>\n",
	          "   </tr>\n";
	 }
      }
      print "</table>\n";

      # Print the table's header.
      print "<br><br>\n<table border=\"true\">\n",
            "   <tr bgcolor=\"black\">\n",
            "      <td><font color=\"white\">Cassette</font></td>\n",
            "      <td><font color=\"white\">Score</font></td>\n",
            "      <td><font color=\"white\">ORF</font></td>\n";

      # Include annotation columns if we have them.
      if(defined($annotation_name) and length($annotation_name)>0)
      {
         print "      <td><font color=\"white\">Gene</font></td>\n",
               "      <td><font color=\"white\">$annotation_name</font></td>\n";
      }
      print "   </tr>\n";

      foreach my $hit (@hits)
      {
         my ($query_index, $orf, $score) = split("\t",$hit);

         my $query_indicator = exists($$query_genes{$orf}) ? 
                               '<font color="red"><b>Query</b></font>' : 
                               '<i>New Member</i>';

         my $qcolor  = exists($$query_genes{$orf}) ? 'lightgrey' : 'white';

         my $bgcolor = exists($best{$orf})         ? 'red'       :           (
                       exists($middle{$orf})       ? 'orange'    : 'yellow'  );

         my $fgcolor = exists($best{$orf})         ? 'white'     :          (
                       exists($middle{$orf})       ? 'black'     : 'black'  );

         my $url    = $url_prefix . $orf . $url_suffix;
         print "   <tr bgcolor=\"$qcolor\">\n";
         print 
               "      <td bgcolor=\"$bgcolor\"><font color=\"$fgcolor\">$score</font></td>\n",
               "      <td>$query_indicator</td>\n",
               "      <td><a href=\"$url\">$orf</a></td>\n";
         if(exists($$annotations{$orf}))
         {
            my ($gene,$annot) = split("\t", $$annotations{$orf});
            print "      <td>$gene</td>\n",
                  "      <td>$annot</td>\n";
         }
         print "   </tr>\n";
      }
      print "</table>\n";
   }
   close(RESULTS);

   # system("rm -f $outfile");
}

##-------------------------------------------------------------------------------------------
##
##-------------------------------------------------------------------------------------------
sub readGeneList
{
   my ($gene_names) = @_;
   my %genes;
   $gene_names = uc($gene_names);

   my $delim = '\s';

   my (@fields, $gene);

   @fields = split(/$delim/, $gene_names); 
   foreach $gene (@fields)
   {
      $gene =~ s/^\s+//;
      $gene =~ s/\s+$//;
      if($gene =~ /\S/)
         { $genes{$gene} = 1; }
   }
   return \%genes;
}

# ($prefix,$suffix)
sub getUrl # ($organism)
{
   if($organism =~ /worm/i)
   {
      return ('http://www.wormbase.org/db/seq/sequence?name=',';class=Sequence');
   }
   elsif($organism =~ /yeast/i)
   {
      return ('http://genome-www4.stanford.edu/cgi-bin/SGD/locus.pl?locus=','');
   }
   return ('','');
}

# ($name, \%annotations)
sub readAnnotations # ($organism)
{
   my ($organism) = @_;
   my ($name, %annotations);
   my $dir = "annot/$organism";
   if(opendir(DIR,$dir))
   {
      my @files = readdir(DIR);
      my $file;
      for($file = shift @files; ($file =~ /^\./) and scalar(@files); $file = shift @files) {}
      if(not($file =~ /^\./) and open(FILE, "$dir/$file"))
      {
         while(<FILE>)
         {
            if(/\S/)
            {
               chop;
               my ($orf,$gene,$annot) = split("\t");
               $annotations{$orf} = "$gene\t$annot";
            }
         }
         $name = &remPathExt($file);
      }
   }
   return ($name, \%annotations);
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub remPathExt
{
  my $path = shift @_;
  $path =~ s/\.[^\.]*$//;
  return $path;
}

