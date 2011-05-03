#!/usr/bin/perl -w

use warnings;
use strict;

use Pod::Usage;
use English;
use Getopt::Long;

sub getFileReaderMethod($);


#main
{
	my $input_file = "-";
	my $delim = "\t";
	my $fh;
	
	GetOptions(
				"file=s"		=> \$input_file,
				"delim=s"		=> \$delim,
				"help|?"		=> sub {pod2usage("verbose"=>1);},
				"man"			=> sub {pod2usage("verbose"=>2);}
				);

	#if no -f or -file parameter passed, check to see if the filename was left in ARGV
	if($input_file eq "-") { $input_file = shift @ARGV; }
	
	if(not defined($input_file) or $input_file eq "-")
	{	#if filename is '-' or no file was passed, read from STDIN
		$input_file = "STDIN";
		$fh = \*STDIN;
	}
	else
	{	#Check to make sure file is valid.  If it is, open file handle
		unless( -e $input_file) { die("$input_file is not a valid file.\n"); }
		open ($fh, getFileReaderMethod($input_file)) or die("cannot open '$input_file'\n");
	}
	
	my @matrix;
	my $o_row_count = 0;	#original row count
	my $o_col_count = 0;	#original col count
	
	print STDERR "Reading in table from '$input_file'...";
	FILE_LINE: while(my $line = <$fh>)
	{
		chomp $line;
				
		my @row = split($delim, $line);
		$matrix[$o_row_count] = [@row];
		
		$o_col_count = max(scalar @row, $o_col_count);
		$o_row_count++;
	}
	print STDERR " done ($o_row_count by $o_col_count).\n";

	print STDERR "Transposing to $o_col_count by $o_row_count...";
	for( my $i = 0; $i < $o_col_count; $i++)
	{
		#print the first element of each row (just one way to solve the end case problem of delimiters)
		if( defined($matrix[0][$i]) ) { print $matrix[0][$i]; }
		
		for( my $j = 1; $j < $o_row_count; $j++)
		{
			print $delim;
			#if the element was defined, print it.
			if( defined($matrix[$j][$i]) ) { print $matrix[$j][$i]; }
		}
		print "\n";
	}
	print STDERR " done.\n";
	
} #end main

sub max
{
	my ($lhs, $rhs) = @_;
	return $lhs > $rhs ? $lhs : $rhs;
}

#This function was adapted from josh's libfile.pl script
sub getFileReaderMethod($)
{
    # Looks at the extension of a file and finds a suitable
    # way to read it. Transparently handles gzipped files, for example.
	my ($filename) = @_;
	if ($filename =~ /\.gz$/ or $filename =~ /\.Z$/)
	{
		return "zcat $filename |"; # Transparently read from gzipped files
	}

	return "< $filename"; # <-- "<" is the default reader method
}




#######################################################################
#							Documentation							#
#######################################################################

=pod

=head1 NAME

This script transposes a file

=head1 VERSION

Last modified date: August 09th, 2010.

=head1 AUTHOR

Sam Boyarsky

=head1 SYNOPSIS

B<fast_transpose.pl> B<--file=s>[B<--delim=s>][B<--help>][B<--man>] 

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--file>

Required. Specify the matrix filename.

=item B<--delim>

Specify the matrix delimiter. (default: tab)

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual for the script.


=back

=head1 DESCRIPTION

This script takes a matrix file and transposes it (columns become rows, rows become columns)

=cut
