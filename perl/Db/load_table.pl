#!/usr/bin/aperl

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libsql.pl";

use strict;

my $arg;
my $verbose=1;
my $delim = "\t";
my $dsn = '';
my $table = '';
my $delete = 0;
my $create = 0;
my %metas;
my %types;
my @types;
my $meta;
my $type;
my $col;
my $keyCol=0;
my $f;
my $defaultType = 'varchar(255)';
my $defaultMeta = '';
my %numbers;
my %chars;
my @tuple;

while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    &printSyntax();
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif($arg eq '-dt')
  {
    $defaultType = shift @ARGV;
  }
  elsif($arg eq '-dm')
  {
    $defaultMeta = shift @ARGV;
  }
  elsif($arg eq '-c')
  {
    $delete = 0;
    $create = 1;
  }
  elsif($arg eq '-o')
  {
    $delete = 1;
    $create = 1;
  }
  elsif($arg eq '-t')
  {
    @types = split(',', shift @ARGV);
    foreach $type (@types)
    {
      ($col, $type,$meta) = split(':',$type);
      $col--;
      $meta =~ s/_/ /g;
      $types{$col} = $type;
      $metas{$col} = $meta;
    }
  }
  elsif($arg eq '-k')
  {
    $keyCol = int(shift @ARGV);
  }
  elsif(length($dsn)<1)
  {
    $dsn = $arg;
  }
  elsif(length($table)<1)
  {
    $table = $arg;
  }
  else
  {
    &printSyntax();
    exit(1);
  }
}

$keyCol--;

if(length($dsn)<1)
{
  print STDERR "No data source supplied.\n";
  exit(2);
}

if(length($table)<1)
{
  print STDERR "No table name supplied.\n";
  exit(3);
}

# Connect to the database.
not($verbose) or print STDERR "Opening MS Access database $dsn ...";
my $dbh = &getDbMsAccess($dsn);
not($verbose) or print STDERR " done.\n";

my $line=0;
my $passify=1000;
my @fields;
my @tuples;
my @schema;
while(<STDIN>)
{
  if(/\S/ and not(/^\s*#/))
  {
    $line++;

    chop;
    if($line==1)
    {
      @fields = split($delim);

      if($delete)
      {
	not($verbose) or print STDERR "Dropping table $table ...";
        &dropTable($dbh, $table);
	not($verbose) or print STDERR " done.\n";
      }

      if($create)
      { 
	not($verbose) or print STDERR "Creating table $table ...";
	for($f=0; $f<=$#fields; $f++)
	{
	  $type = defined($types{$f}) ? $types{$f} : $defaultType;
	  $meta = defined($metas{$f}) ? $metas{$f} : $defaultMeta;
	  $fields[$f] = &normalizeField($fields[$f]);
	  $schema[$f] = "$fields[$f] $type $meta";
	  if($type =~ /[Nn][Uu][Mm][Bb][Ee][Rr]/)
	    { $numbers{$f} = 1; }
	  elsif($type =~ /[Cc][Hh][Aa][Rr]\s*\((\d+)/)
	    { $chars{$f} = int($1); }
	}
        &createTable($dbh, $table, @schema);
	not($verbose) or print STDERR " done.\n";
      }
      not($verbose) or print STDERR "Loading data from standard input ...";
    }
    else
    {
      @tuple = split($delim);
      # foreach $f (keys(%numbers))
      # {
	# print STDERR "[$tuple[$f]] --> ";
      #   $tuple[$f] = &truncateNumber($tuple[$f]);
	# print STDERR "[$tuple[$f]]\n";
      # }
      foreach $f (keys(%chars))
      {
        $tuple[$f] = &truncateChar($tuple[$f], $chars{$f});
      }
      $tuples[$line-2] = join($delim,@tuple);
    }

    if($line%$passify==0 and $verbose)
    {
      print STDERR ".";
    }
  }
}

# Load the tuples into the table.
not($verbose) or print STDERR " done.\nLoading tuples into table ...";
&insertTableMany($dbh, $table, $delim, $#fields+1, @fields, @tuples);
not($verbose) or print STDERR " done.\n";

&closeDb($dbh);

exit(0);

sub printSyntax
{
  my $name = &getPathSuffix(&dos2unix($0));
  print STDERR "Syntax: $name [OPTIONS] DSN TABLE < FILE\n",
	"\n",
	"Loads the rows in the FILE into the table TABLE in the database\n",
	"  referenced by the data source name DSN.\n",
	"\n",
	"DSN: data source name: name of the ODBC connection to an MS Access\n",
	"  database.\n",
	"TABLE: the name of the table to write the records to.\n",
	"FILE contains one header line followed by rows of data.  Each\n",
	"  row is loaded as a tuple into the table.\n",
	"\n",
	"OPTIONS are\n",
	"\n",
	"-q: Quiet mode: turn verbosity off (default verbose)\n",
	"-d DELIM: set the field delimiter (default is tab)\n",
	"-c: Create the table (default is to append to an existing table\n",
	"-o: Overwrite the table (delete first then create with new tuples)\n",
	"-dt TYPE: Set the default type for fields equal to TYPE (default\n",
	"  is varchar(255)\n",
	"-dm META: Set the default meta for fields equal to META (default is\n",
	"  nothing.\n",
	"-t LIST: supply a list of types for the fields.  The list is a\n",
	"  a list of tuples.  The outer list is seperated by commas\n",
	"  and the inner lists are seperated by colons.  Each tuple can\n",
	"  be either a pair or a triplet of COL:TYPE:META where COL is the\n",
	"  the column of the field whose type is being specified, TYPE is\n",
	"  a legal SQL type for the column, and META is other information\n",
	"  for the field such as primary key information or how to handle\n",
	"  NULL values.  For example the list:\n",
	"\n",
	"    1:varchar(100),2:int:primary_key\n",
	"\n",
	"  says the first field is a variable character up to 100 characters\n",
	"  long while the second field is an integer and is the primary key.\n",
	"  Note that underscores in the meta position are converted into\n",
	"  spaces.  If no type is specified for a field than it is assumed\n",
	"  to be equal to the default type (use -dt to set this).\n",
  	"\n";
}

sub truncateNumber
{
  my $num = shift @_;
  # $num =~ s/([.]\d\d\d\d\d\d\d)\d+/\1/;
  $num =~ s/([.]\d\d)\d+/\1/;

  return $num;
}

sub truncateChar
{
  my $char = shift @_;
  my $len  = int(shift @_);
  if($len>=length($char))
    { return $char; }
  return substr($char, 0, $len);
}


