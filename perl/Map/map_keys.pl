#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/libmap_data.pl";

use strict;

my $organism = '';
my @databases;
my $col = 1;
my $delim = "\t";
my $fin = \*STDIN;
my $verbose = 1;
my $log = '';
my $opened_log = 0;
my $printed_log_header=0;
my $entity = 'Gene';
my $headers = 0;
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
  elsif($arg eq '-k')
  {
    $col = int(shift @ARGV);
  }
  elsif($arg eq '-h')
  {
    $headers = shift @ARGV;
  }
  elsif($arg eq '-entity')
  {
    $entity = shift @ARGV;
  }
  elsif($arg eq '-log')
  {
    $log = shift @ARGV;
  }
  elsif(-f $arg)
  {
    open($fin,$arg) or die("Could not open file '$arg' for reading.");
  }
  elsif(length($organism)==0)
  {
    $organism = $arg;
  }
  else
  {
    push(@databases,$arg);
  }
}
$col--;

length($organism)>0 or die("Please supply an organism name.");

my %aliases;
my %found_aliases;
my %errors;
my %read_aliases;
my %database2aliases;
my $line=0;
my $count=0;
$entity = &getMapEntityName($entity);
while(<$fin>)
{
  $line++;
  # print STDERR "($line";
  if(/\S/)
  {
    chomp;
    $count++;
    if($count > $headers)
    {
      my @tuple = split($delim);
      my $key = &clean_key($tuple[$col]);
      my $map_database = '';

      # print STDERR "[$key,$entity,$organism,(", join(',',@databases), ")] --> ";
      ($key,$map_database) = &extractKey($key,$entity,$organism,@databases);
      # print STDERR "[$key,$entity,$organism,$map_database]\n";

      # Read in the mapping from this database to MAP
      if(length($map_database)>0 and not(exists($read_aliases{$map_database})))
      {
        $verbose and print STDERR "Reading $entity aliases for organism '$organism' (database=$map_database)...";
        my $aliases_ref = &getMapAliases($entity,$organism,$map_database);

        $database2aliases{$map_database} = $aliases_ref;

        my $num_aliases = scalar(keys(%{$aliases_ref}))+1;
        # print STDERR join("-", keys(%aliases)), "\n";

        if($num_aliases>=0)
        {
          $found_aliases{$map_database} = 1;
          $verbose and print STDERR " $num_aliases key aliases found.\n";
        }
        else
        {
          $found_aliases{$map_database} = 0;
          $verbose and print STDERR "No key aliases were found.\n";
        }

        $read_aliases{$map_database} = 1;
      }
      # print STDERR "[$key,$map_database]\n";

      my $map_key = $key;
      if(length($map_database)>0 and exists($found_aliases{$map_database}))
      { 
        my $aliases_ref = $database2aliases{$map_database};

        # print STDERR "{{$key}} ==> \n";
        $map_key = $$aliases_ref{$key};
        # print STDERR "{{$map_key}}\n";
      }
   
      if(length($map_key)>0)
      {
        $tuple[$col] = $map_key;
        print join($delim,@tuple), "\n";
      }
      elsif(length($key)>0 and not(exists($errors{$key})))
      {
        if(length($log)>0 and not($opened_log))
        {
          if(not(open(LOG,">>$log")))
          {
            $verbose and print STDERR "Could not append to log file '$log'; not logging errors.\n";
            $log = '';
          }
          $opened_log = 1;
        }

        if(length($log)>0)
        {
          if(not($printed_log_header))
          {
            print LOG &getMapLogErrorHeader("Unresolved $map_database keys");
            $printed_log_header = 1;
          }
          print LOG "$key\n";
        }
        $errors{$key} = 1;
      }
    }
    else
    {
      print "$_\n";
    }
  }
  # print STDERR ") ";
}
close($fin);

if(length($log)>0)
{
  if($printed_log_header)
  {
    print LOG &getMapLogErrorFooter();
  }
  close(LOG);
}

exit(0);

sub clean_key
{
  my $key = shift;
  $key =~ s/^\s+//;
  $key =~ s/\s+$//;
  $key =~ tr/a-z/A-Z/;
  return $key;
}

__DATA__
syntax: map_keys.pl [OPTIONS] ORGANISM [DATABASE1 DATABASE2 ...] < FILE

ORGANISM:  one of worm, yeast, human, or fly (common species name, case-insensitive).

DATABASEi: What database the keys originate.  Should be one of: LocusLink, Genbank,
           FlyBase, WormBase, SGD, etc.  A file in the MAP data repository should exist at
           ~/Map/Data/Aliases/Gene/ORGANISM/DATABASE/data.tab for the resolution to work.  Note
           this field is matched case insensitively.  If the database is unknown and can be
           determined from the keys in the file then do not supply DATABASE.  If more than
           1 database is supplied then each is tried in turn for every key in the order
           listed.

OPTIONS are:

-q: Quiet mode (default is verbose)
-k COL: Specify the ORF column to be COL (default is 1).
-log FILE: Record keys that could not be resolved into MAP keys into file FILE.
-entity ENTITY: Set the biological entity to ENTITY.  The default is Gene which directs the
                script to resolve keys for genes.  Valid entities are:

                      Chromosome - chromosome names and numbers
                      Contig     - contigs from genomes being assembled
                      Gene       - genes, cosmid ids, ORFs, loci, etc.
                      Strand     - names for chromosomes strands (e.g. plus, +, watson, etc.)

