use strict;

use Term::ANSIColor;

sub printUsage() {
  print STDOUT <DATA>;
}

sub printUsageAndQuit() {
    printUsage();
    exit(1);
}

sub quitWithUsageError($) {
  print color("red");
  print "Error: " . $_[0];
  print color("reset");

  printUsage();

  print color("red");
  print "Error: " . $_[0];
  print color("reset");
  exit(1);
}

# Assert that ARG1 is true, or else
# die with the message in ARG2 (optional)
# Used for debugging / asserting that things are true in code.
# Usage: labAssert(2 + 2 == 4, "math has failed.");
sub labAssert($;$) {
  if (not ($_[0])) {
	my $message = "libsystem.pl: Programmer-specified assertion failed!\n";
	$message .= "libsystem.pl: ";
	if (defined($_[1]) && (length($_[1]) > 0)) {
	  $message .= "Assertion failure message is:\n";
	  $message .= "libsystem.pl: " . qq{\"$_[1]\"};
	} else {
	  $message .= "(No assertion failure message was given, however.)";
	}
	die "\n" . ("*" x 80) . "\n" . $message . "\n" . ("*" x 80) . "\n";
  }
}

# +-------------------------------------------------------------------
# | int systemAndPrint(string, HANDLE_FOR_PRINTING=STDERR)
# +-------------------------------------------------------------------
# Prints a command, then executes it on the UNIX system with "system"
# The return value is the EXIT CODE of system, not the output string!
# If HANDLE_FOR_PRINTING is not defined, print to STDERR
# Example: systemAndPrint("ls", *STDOUT)
#       or systemAndPrint("grep -i 'THING' myFile.txt") <-- defaults to STDERR
sub systemAndPrint($;$) {
	my ($cmd, $WHERE) = @_;
	chomp($cmd); # <-- remove trailing irrelevant newline, if there is one
	if (!defined($WHERE)) { $WHERE = *STDERR; }
	print $WHERE "Executing the following command: $cmd\n";
	return system($cmd);
}



1;
