#!/usr/bin/perl -w

@bg = (0.282, 0.220, 0.229, 0.267); # NR
$sm = 0.1;

$in = 0;
@bp = qw(A C G T);

#print "ALPHABET= ACGT\n";
$group = shift;
$group = "" unless defined $group;

print "<Motifs SeqFile=\"yeast_proms.fasta\">\n";

while (<>) {
    chomp;
    if (m/^\/\//) {
	%h = ();
    }

    if (m/^AC/ || m/^ID/ || m/^NA/ || m/^DE/ || m/^BF/) {
	@line = split;
	$_ = shift @line;
	defined($h{$_}) ? $h{$_}.="@line" : $h{$_} = "@line";
    }

    if (m/^P0/) {
	$len = 0;
	$seq = $buf = "";
	$in = 1;
    	$tic = 0;
    }

    if (m/^XX/ && $in)
    {
	if ($h{'ID'} =~ m/^$group/)
        {
	    print "<Motif ";
	    print "Consensus=\"$seq\" ";

	    foreach (sort keys %h)
            {
	        if ($_ eq "ID")
		{
		  $h{$_} =~ /[\$](.*)/;
		  print "Source=\"TRANSFAC\" Name=\"$1\">\n";
		}

		#print "## $_: $h{$_}\n";
	    }

	    print "   <Weights ZeroWeight=\"0\">\n";

	    #print "## Best Sequence: $seq\n";
	    #print "## (rev.comp) Sequence: " . &comp($seq) . "\n";
	    #print "log-odds matrix: alength= 4 w= $len\n";
	    print "$buf";
	    #print "## Total Information Content in matrix = $tic\n";
	    #print "### $tic " . $tic/$len . "\n\n";

	    print "   </Weights>\n";

	    print "</Motif>\n";
	}
	$in = 0;
    }

    if (m/^[0-9][0-9]/) {
	@line = split;
	shift @line;
	@probs[0..3] = @line;
	$sum = $probs[0] + $probs[1] + $probs[2] + $probs[3] + 4*$sm;

	$ic = log2(4);
	for $i (0 .. 3) {
	    $probs[$i] = ($probs[$i]+$sm) / $sum;
	    $logs[$i] = log2($probs[$i]/$bg[$i]);
	    $ic += $probs[$i] * log2($probs[$i]);
	}
	$tic += $ic;

#  	$buf .= sprintf("%10.3f %10.3f %10.3f %10.3f [%7.4f]\n", @logs, $ic);
#	$buf .= sprintf("%10.3f %10.3f %10.3f %10.3f\n", @probs);
# 	$buf .= sprintf("%10.3f %10.3f %10.3f %10.3f\n", @logs);
 	$buf .= sprintf("      <Position Num=\"$len\" Weights=\"%.2f;%.2f;%.2f;%.2f\"></Position>\n", @logs);
	$seq .= $bp[&max4(@logs)];
	$len++;
    }
}

print "</Motifs>\n";

sub comp() {
    local ($a);
    local $a = reverse shift;
    $a =~ tr/ACGTRYBDHVKM/TGCAYRVHDBMK/;
    return $a;
}

sub max4() {
    local($_12, $_34);
    $_12 = ($_[0] >= $_[1]) ? 0 : 1;
    $_34 = ($_[2] >= $_[3]) ? 2 : 3;
    return ($_[$_12] >= $_[$_34]) ? $_12 : $_34;
}

sub log2() {
    $_ = shift;
    return log($_)/log(2);
}

