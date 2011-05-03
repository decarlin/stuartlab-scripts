#!/usr/bin/perl -w


# trash.pl is meant to be a "safer rm," which moves things to a trash can
# instead of immediately removing them. trash.pl will mangle names, so it's
# not necessarily going to be easy to restore things.

# Any slashes will be replaced with __PATH__, which means that restoring
# any directory structure will be exceedingly annoying. So be careful!



#
# Use and abuse as much as you want.
# Put it in /usr/local/bin/ or $HOME/bin/
# Daniel Cote a.k.a Novajo, dccote@novajo.ca
#
# Modified later!
#
# Most recent version of this file available at
# http://www.novajo.ca/trash.html
#
# Instead of deleting files, this script moves them to the appropriate trash folder.
# Trash folders are either private ($HOME/.Trash/) or public (/Volumes/name/.Trashes/
# and /.Trashes).  In the directory .Trashes/, each user has a trash folder named after
# its userid (501, 502, etc...).
#
# This script will simply stop if anything goes wrong. If by any chance it appears
# that it might overwrite a file, it will let you know and ask for a confirmation.
#
# This script could be used as a replacement for rm.  The options passed as arguments
# are simply discarded.

# Usage: trash [options] file1|dir1 file2|dir2 file3|dir3 ...
# You can use wildcards. To erase a directory, you are probably better off just naming
# the directory (e.g. trash Documents/) as opposed to trash Documents/* since the first
# case will actually keep the hierarchy and simply move Documents into the trash whereas
# the second one will move each item of the document folder into the trash individually.
#

use strict;
use warnings;

use Cwd ('abs_path', 'getcwd');
use File::Basename;

if ( scalar @ARGV == 0) {
    die "trash.pl needs at least one argument. It works in a similar fashion to *rm*.\nUsage: trash.pl thing1 thing2 thing3 ...\n\n";
}

my $MAX_INDEX = 1000; # <-- number of duplicate-named files allowed in a directory

my $username = `whoami`;
chomp($username);
if (!(length($username) > 0)) {
    die qq{We could not get your username! We need it to make the trash can!\n};
}
if (!defined($username) || (length($username) <= 0) || $username =~ /[\/\\"' 	*+]/) {
    die qq{The username is either blank, or it has either a space in it, or a tab, or a star, or a plus, or a quotation mark, or a slash, or a backslash! We cannot reliably create a trash directory without it being dangerous!!!\n};
}


# We drop any option passed to command "trash"
# This allows to use trash as a replacement for rm
# (Incidentally, we cannot remove files that start with hyphens using trash.pl, either.)
while ( $ARGV[0] =~ m|^-|i) { # if the option starts with a hyphen...
    shift @ARGV;
}

foreach my $itemToDelete (@ARGV) {

    if (not (-e $itemToDelete)) {
	# the item doesn't even exist, so skip it with no warnings
	print "trash.pl: Not deleting \"$itemToDelete\", because it did either not exist or could not be read. Check that this file actually exists!\n";
	next;
    }

    if (not (-f $itemToDelete || -d $itemToDelete || -l $itemToDelete)) {
	# The thing to delete has to be either a file (-f), a directory (-d), or a symlink (-l).
	print "trash.pl: Not deleting \"$itemToDelete\": it was not a file, directory, or symlink.\n";
	next;
    }

    my $thepath = undef;

    if (-l $itemToDelete) {
	# the "item to delete" is a symbolic link. Therefore, do NOT follow the symlink and delete the real file. Instead, just delete the symlink.
	$thepath = $itemToDelete; # <-- just delete the symlink, DON'T follow the link to the real file!!!
    } else {
	$thepath = abs_path($itemToDelete); # <-- figure out what the full path of this file is.
    }

    #print "Item to delete: " . $thepath . "\n";

    my $basename = basename($thepath);
    my $dirname  = dirname($thepath);

    #print "Full name of the thing we are deleting to make: " . $thepath . "\n";
    #print "Location to put it: " . "/tmp/alexgw/Trash" . $thepath . "\n";

    #print "Specific file/folder: " . $basename . "\n";
    #print "Directory that it is in: " . $dirname . "\n";
    #print "\n";

    my $trash = qq{/tmp/${username}/Trash};

    if (! -e $trash) {
	print qq{trash.pl: Making trash directory "$trash"\n};
	`mkdir -p $trash`;
	`chmod og-rwx $trash`; # making it so no one else can read it...
	`chmod u+rwx $trash`; # but we can read it...
    }

    if (!(-d $trash)) {
	die "Error: $trash is not a directory";
    }

    if (!(-l $thepath) && !(-e $thepath)) {
	# need to check that there is a symlink (-l) at the location, OR a real thing (-e)
	die "Error getting full path to file: $thepath does not exist\n";
    }

    my $UNSAFE_CHARS = q{"'*+\$;};
    if ($thepath =~ /[$UNSAFE_CHARS]/) {
	die "Uh oh, trash.pl has no idea how to deal with filenames with any of these " . length($UNSAFE_CHARS) . " unusual characters in them: $UNSAFE_CHARS . That might be bad news, so we are just going to abort. Try using the real /bin/rm in this case.";
    }

    my $index = 2;

    my $trashedDirLoc  = "$trash/$dirname";

    if (! -d $trashedDirLoc) {
	print qq{trash.pl: Making a new trash subdirectory at $trashedDirLoc\n};
	system(qq{mkdir -p "$trashedDirLoc"});
    }

    my $tab = "     ";

    my $trashedFileLoc =
	($thepath =~ m{^\/})
	? "${trash}${thepath}"
	: "${trash}/${thepath}";
    
    while (-e $trashedFileLoc) {
	print STDOUT "trash.pl: There was already a file in the trash named\n";
	print STDOUT "${tab}${tab}" . qq{"$trashedFileLoc"} . "\n";
	print STDOUT "${tab}so we are trying to rename the file before trashing it...\n";

	$trashedFileLoc =
	    ($thepath =~ m{^\/})
	    ? "${trash}${thepath}_${index}"
	    : "${trash}/${thepath}_${index}";
	
	$index++;
	if ($index >= $MAX_INDEX) {
	    die qq{Error trying to rename \"$itemToDelete\" to avoid overwriting an existing file with the same name that is already in the trash (there are too many files with the same name).\nYou should probably empty the trash.};
	}
    }

    if (-l $itemToDelete) {
	print STDOUT qq{trash.pl: Trashing the symbolic link $itemToDelete -> $trashedFileLoc\n};
    } else {
	print STDOUT qq{trash.pl: $itemToDelete -> $trashedFileLoc\n};
    }

    system(qq{mv "$thepath" "$trashedFileLoc"});
}
