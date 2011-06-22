#!/usr/local/bin/perl

use strict;

sub usage 
{
	my $msg = shift;
	print <<EOF;
##
## Convert Sets file to JSON output
## Usage:  perl $0 --sets_file <sets_file> > <json_output_file>
##
EOF
	print $msg."\n";	
}

use Getopt::Long;
use Set;

my $sets_file = '';
GetOptions(
	"sets_file=s" => \$sets_file);

die &usage() unless (-f $sets_file);

open (SETS_FH, $sets_file) || die;
my $errstr = '';
@sets = Set::parseSetLines(\$errstr, @lines);
close (SETS_FH);
if ($sets[0] == 0) {
	pop @sets;
	print $errstr."\n";
	die "Failed to parse set lines!\n";
}

foreach my $set in (@sets) {
	print $set->serialize();
}
