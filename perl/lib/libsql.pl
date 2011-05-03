#
# Windows-based example of using Access with ODBC stolen from:
#
# http://www.wdvl.com/Authoring/Languages/Perl/PerlfortheWeb/simple_query.html
#
use DBI;
use strict;

# Takes a DSN data source name (the name of the Access database
# as labelled in the ODBC connectivity control panel), a username
# and a password.  If the username and password are blank will
# try to establish connection without them.
#
sub getDbMsAccess # ($dsn [, $username, $password])
{
  my $dsn = shift @_;
  my $username = ($#_>=0) ? shift @_ : '';
  my $password = ($#_>=0) ? shift @_ : '';
  my $dbh = (length($username)>0 and length($password)>0) ?
  		DBI->connect("dbi:ODBC:$dsn", $username, $password) :
  		DBI->connect("dbi:ODBC:$dsn");
  return $dbh;
}

# $dsn = "DBI:mysql:host=localhost;database=$dbname"; 

sub getDbMySql # ($dsn [, $username, $password])
{
  my ($dbname, $host, $username, $password) = @_;
  $host        = defined($host) ? $host : 'localhost';
  my $dsn      = "DBI:mysql:host=$host;database=$dbname";
  my $username = ($#_>=0) ? shift @_ : '';
  my $password = ($#_>=0) ? shift @_ : '';
  my $dbh      = DBI->connect($dsn, $username, $password);
  return $dbh;
}

# Just prepares an SQL statement and returns a handle to the statement.
# First argument is a database handle and second is the SQL statement
# in a string.
#
sub openSql # ($dbh, $sql)
{
  my $dbh = shift @_;
  my $sql = shift @_;
  my $sth = $dbh->prepare($sql);
  return $sth;
}

# Execute the SQL statement contained in a statement handle.
#
sub doSql # ($sth)
{
  my $sth = shift @_;
  $sth->execute or die("Could not execute SQL statement\n");
}

# Prepares and executes the sql command and also returns a handle
# to the statement.  First argument is a database handle, second is
# the SQL statement in a string.
#
sub openDoSql # ($dbh, $sql)
{
  my $dbh = shift @_;
  my $sql = shift @_;

  # Prepare the command (get a statement handle):
  #
  my $sth = &openSql($dbh, $sql);
  defined($sth) or die("Could not open SQL statement handle for -->$sql<--\n");
  &doSql($sth);
  return $sth;
}

# Gets all the results from the previous SQL call associated with the
# statement handle.  First argument is a handle to the statement.
# Second is a delimiter for pasting entries from each
# row together.  This returns a big table in an array where each item
# is a row from the result.  If no delimiter is given, defaults to tabs.
#
sub fetchSql # ($sth, $delim)
{
  my $dbh = shift @_;
  my $sth = shift @_;
  my $delim = ($#_>=0) ? shift @_ : "\t";
  my @rows;
  my @row;
  my $r=0;

  # Alternatives to fetchrow_array() are:
  #
  #	$sqlHandle->dumpresults();	# Dumps everything simply formatted.
  #
  while(@row = $sth->fetchrow_array())
    { @rows[$r++] = join($delim, @row); }
  return @rows;
}

# Tell the database we're done with the statement.  First argument is
# a statement handle.
#
sub closeSql # ($sth)
{
  my $sth = shift @_;
  return $sth->finish();
}

# Executes an SQL statement (prepares and also closes it).
#
sub execSql # ($dbh, $sql)
{
  my $dbh = shift @_;
  my $sql = shift @_;
  my $sth = &openDoSql($dbh, $sql);
  &closeSql($sth);
}

# Perform an SQL command that returns results in a table.
#
sub execFetchSql # ($dbh, $sql, $delim)
{
  my $dbh = shift @_;
  my $sql = shift @_;
  my $delim = shift @_;
  my $sth = &openDoSql($dbh, $sql);
  my @results = &fetchSql($sth, $delim);
  &closeSql($sth);
  return @results;
}

# Disconnect from a database.  First argument is a database handle.
#
sub closeDb # ($dbh)
{
  my $dbh = shift @_;
  return $dbh->disconnect();
}

# Creates a table.  Returns 0 on success and and non-zero
# on failure.
#
sub createTable # ($dbh, $table, @fields)
{
  my $dbh = shift @_;
  my $table = shift @_;
  my $fields = join(",",@_);

  &execSql($dbh, "create table $table ($fields);");

  return 0;
}

# Drop a table
#
sub dropTable # ($dbh, $table)
{
  my $dbh = shift @_;
  my $table = shift @_;
  &execSql($dbh, "drop table $table;");

  return 0;
}

# Prepare for a tuple to be inserted into a table
#
sub prepInsertTable # ($dbh, $table, @fields) return $sth
{
  my $dbh = shift @_;
  my $table = shift @_;
  my @fields = @_;
  my $fields = join(",", @_);

  my $q;
  my @qs;
  for($q=0; $q<=$#fields; $q++)
    { $qs[$q] = '?'; }

  my $sql = "insert into $table($fields) values(" . join(",",@qs) . ")";
  my $sth = $dbh->prepare($sql);
  return $sth;
}

# Insert a single tuple into a table and then close the statement
#
sub insertTable # ($dbh, $table, @fields, @tuple)
{
  my $dbh = shift @_;
  my $table = shift @_;
  my @fields = splice(@_, 0, int(($#_+1)/2));
  my @tuple = @_;

  my $sth = &prepInsertTable($dbh, $table, @fields);
  $sth->execute(@tuple);
  &closeSql($sth);
}

# Insert many tuples into a table.
#
sub insertTableMany # ($dbh, $table, $delim, $numFields, @fields, @tuples)
{
  my $dbh = shift @_;
  my $table = shift @_;
  my $delim = shift @_;
  my $numFields = shift @_;
  my @fields = splice(@_, 0, $numFields);
  my @tuples = @_;

  my $sth = &prepInsertTable($dbh, $table, @fields);
  my $tuple;
  my @tuple;
  foreach $tuple (@tuples)
  {
    if($tuple =~ /\S/)
    {
      @tuple = split($delim,$tuple);
      $sth->execute(@tuple);
    }
  }
  &closeSql($sth);
}

sub normalizeField # ($field)
{
  my $field = shift @_;

  # Convert strange characters to underscores
  $field =~ s/[.-]/_/g;

  # Protect fields that start with a number
  $field =~ s/^(\d)/_\1/;

  return $field;
}


1
