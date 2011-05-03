#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libfile.pl";

use strict;

$| = 1;

my @flags   = (
                  [    '-p', 'scalar',          '', undef]
                , [   '-s1', 'scalar',     '.html', undef]
                , [   '-s2', 'scalar',          '', undef]
                , ['--file', 'scalar',         '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $prefix  = "<a href=\"" . $args{'-p'};
my $suffix1 = $args{'-s1'} . '">';
my $suffix2 = $args{'-s2'} . '</a>';
my @extra   = @{$args{'--extra'}};
my $file    = $args{'--file'};
my $regex   = $extra[0];

defined($regex) or die("No regular expression supplied");

my $filep = &openFile($file);
while(<$filep>)
{
   s/($regex)/$prefix\1$suffix1\1$suffix2/g;
   print;
}

exit(0);

__DATA__

wrap_url.pl [OPTIONS] REGEX [FILE | < FILE]

For any string S matching the regular expression REGEX, the script
produces the string:

         '<a href="' . PREFIX . S . SUFFIX1 . '">' . S . SUFFIX2 . '</a>'

OPTIONS are:

-p PREFIX: set the url prefix to PREFIX.  This is the text after the '<a href="' string
           and before S.  Default is blank.

-s1 SUFFIX: set the first suffix to SUFFIX.  This is the text after S and before
            the '">' string in the URL locator.  Default is '.html'.

-s2 SUFFIX: set the second suffix to SUFFIX.  This is the text after the "visable" S
            but before the final '</a>'.

