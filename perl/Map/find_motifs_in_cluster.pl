#!/usr/bin/perl
# bof: find_motifs_in_cluster.pl -- 

use strict;

require "$ENV{MYPERLDIR}/lib/libattrib.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";

my $arg;
my $input_file=undef;
my $prefix=undef;
my $master_out_file=undef;
my $motif_output_file=undef;
my $delim1='=';	# Primary delimiter
my $delim2=',';	# Secondary delimiter
my $verbose=1;
my $zcat = 'zcat';
my $cat = 'cat';
my $uppercase=0;
my $cmd = '';
my @files_to_remove;
my $tracking_num = time();

while(@ARGV)
{
  $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDERR <DATA>;
    exit(0);
  }
  elsif($arg eq '-u')
  {
    $uppercase=1;
  }
  elsif($arg eq '-q')
  {
    $verbose=0;
  }
  elsif($arg eq '-d1')
  {
    $delim1 = shift @ARGV;
  }
  elsif($arg eq '-d2')
  {
    $delim2 = shift @ARGV;
  }
  elsif(length($input_file)<1)
  {
    $input_file = $arg;
  }
  else
  {
    print STDERR <DATA>;
    exit(1);
  }
}

if(not(defined($input_file)) or not(-f $input_file))
{
  print STDERR "The input file, $input_file, is not a valid FMC file, quitting.\n";
  exit(2);
}

if($input_file =~ /^([^.]+)\.fmc\.in$/)
{
  $prefix = $1;
  $master_out_file = $prefix . '.fmc.xml';
}
else
{
  print STDERR "The input file must end with the extension .fmc.in, quitting.\n";
  exit(2);
}

if(not(open(MASTER_OUT,">$master_out_file")))
{
  print STDERR "Unable to create master output file $master_out_file, quitting.\n";
  exit(2);
}

# Read in the attribute-value pairs from the file
my %AV = &getAVArray($input_file,$delim1);

# Lookup information about what runs need to be executed.

# Read in paramters general to all runs

# See if the user supplied a temporary file.
my $tmp_dir = exists($AV{'tmp_dir'}) ? $AV{'tmp_dir'} : '.';

# Should we remove temporarily created files?
my $rm_tmp_files = exists($AV{'rm_tmp_files'}) ? 
				$AV{'rm_tmp_files'} : 'true';

# How many runs are there:
my $num_runs = $AV{'num_runs'};
my $num_porfs = $AV{'num_porfs'};
my $num_norfs = $AV{'num_norfs'};
my $upstream_sequence_file = $AV{'upstream_sequence_file'};
my $background_sequence_file = $AV{'background_sequence_file'};
my $three_prime_numbering = exists($AV{'three_prime_numbering'}) ? $AV{'three_prime_numbering'} : 'false';

# Assert that the user specified a number of runs.
if(not($num_runs))
{
  print STDERR "The setting \"num_runs\" was missing, quitting.\n";
  exit(3);
}
if(not($upstream_sequence_file))
{
  print STDERR "The setting \"upstream_sequence_file\" was missing, quitting.\n";
  exit(3);
}

# Read in the ORF names:
my $o;
my $orf;
my @porfs = load_vec_to_memory($AV{'porf_file'});
for($o=1; $o<=$num_porfs; $o++)
{
  $orf = "porf_$o";
  if(not(exists($AV{$orf})))
  {
    print STDERR "WARNING: no paramter $orf as expected, ignoring.\n";
  }
  else
  {
    push(@porfs, $AV{$orf});
  }
}
my $found_porfs = $#porfs+1;
if($found_porfs <= 0)
{
  print STDERR "The setting \"num_porfs\" was missing, quitting.\n";
  exit(3);
}

my @norfs = load_vec_to_memory($AV{'norf_file'});
for($o=1; $o<=$num_norfs; $o++)
{
  $orf = "norf_$o";
  if(not(exists($AV{$orf})))
  {
    print STDERR "WARNING: no paramter $orf as expected, ignoring.\n";
  }
  else
  {
    push(@norfs, $AV{$orf});
  }
}
my $found_norfs = $#norfs+1;

print STDERR "Successfully read $input_file.  Results will be written to $master_out_file.\n",
	"\n",
	"Number positive ORFs = $found_porfs\n",
	"Number negative ORFs = $found_norfs\n",
	"Number of runs = $num_runs\n",
	"\nCommon settings for all runs are:\n",
	"Upstream sequence file = $upstream_sequence_file\n",
	"Background sequence file = $background_sequence_file\n",
	"Numbering relative to 3' end = $three_prime_numbering\n",
	"\n";

# Create a temporary FASTA file that will hold the upstream sequences for
# all the orfs.  Note it is assumed that all alignment programs use the
# common FASTA format.

my $porf_fasta = "$tmp_dir/fmc_$tracking_num" . '_porfs_' . &getPathSuffix($prefix) . '.fa';
&extract_orf_seqs($tmp_dir, $rm_tmp_files, 
				$tracking_num,
				$upstream_sequence_file, 
				$uppercase, $verbose, 
				$porf_fasta,@porfs);

my $norf_fasta = "$tmp_dir/fmc_$tracking_num" . '_norfs_' . &getPathSuffix($prefix) . '.fa';
if (length($background_sequence_file) > 0)
{
  &extract_orf_seqs($tmp_dir, 
		    $rm_tmp_files,
		    $tracking_num,
		    $background_sequence_file, 
		    $uppercase, $verbose, 
		    $norf_fasta, @norfs);
}

# Read in parameters particular to each run and then run 
my $r;
my $run;
my $program;
my $upstream_size;
my $initial_consensus;
my $program_number;
print MASTER_OUT "<Motifs>\n";
for($r=1; $r<=$num_runs; $r++)
{
  $run = $AV{"run_$r"};
  ($program, $upstream_size, $initial_consensus) = split($delim2,$run); 

  # If any parameters are variables, look up their values
  if($program =~ /^program_(\d+)/)
  {
    $program_number = $1;
    $program = $AV{$program};
    $program =~ tr/A-Z/a-z/;
  }

  if($upstream_size =~ /^upstream_size_\d+/)
  {
    $upstream_size = $AV{$upstream_size};
  }

  if($initial_consensus =~ /^initial_consensus_\d+/)
  {
    $initial_consensus = $AV{$initial_consensus};
  }

  if($verbose)
  {
    print STDERR "|____ run_$r program_[$program] ",
    			"upstream_size_[$upstream_size] ",
			"initial_consensus_[$initial_consensus] ____|\n";
  }

  # Tailor the positive and negative sequences to this run.
  my $porf_fasta_run = "$tmp_dir/fmc_" . $tracking_num . "_porf_run_$r.fa";
  my $norf_fasta_run = "$tmp_dir/fmc_" . $tracking_num . "_norf_run_$r.fa";
  my %porf_seq_lens = &modify_orf_seqs($porf_fasta, $upstream_size, $porf_fasta_run);
  my %norf_seq_lens = &modify_orf_seqs($norf_fasta, $upstream_size, $norf_fasta_run);
  push(@files_to_remove,$porf_fasta_run);
  push(@files_to_remove,$norf_fasta_run);

  $cmd='';
  if($program eq 'meme')
  {
    # my $meme_result_file = "$tmp_dir/meme_run_" . $r . '_' . $tracking_num . ".out";
    # push(@files_to_remove,$meme_result_file);

    # Set (or get) the executable for the MEME program.
    my $meme = "meme";
    if (exists($AV{"program_exe_$program_number"})) { $meme = $AV{"program_exe_$program_number"}; }

    # Build up a list of arguments to pass to MEME:
    my $meme_args = "";
    my $use_both_strands = $AV{"use_both_strands"} eq 'true' ? 'true' : 'false';
    $meme_args .= $use_both_strands eq 'true' ? ' -revcomp ' : ''; 
    $meme_args .= exists($AV{"motif_length"}) ? " -w " . $AV{"motif_length"} : "";
    $meme_args .= exists($AV{"meme_max_iter"}) ? " -maxiter " . $AV{"meme_max_iter"} : "";
    $meme_args .= exists($AV{"max_seconds"}) ? " -time " . $AV{"max_seconds"} : "";
    $meme_args .= " -dna";
    $meme_args .= " -text";
    $meme_args .= " -maxsize 1000000";

    if(length($initial_consensus)>0)
    {
      $meme_args .= " -cons $initial_consensus";
    }
    # $cmd .= " | fasta2stab.pl > $meme_result_file";
    # $cmd .= " > $meme_result_file";
    $cmd = "$meme $porf_fasta_run $meme_args";

    if(length($cmd)>0)
    {
      print STDERR "<<--- Run $r (MEME) Started --->>\n";
      print STDERR "$cmd\n";
      # `$cmd`;
      if(not(open(MEME_OUT,"$cmd |")))
      {
        print STDERR "!!! Error executing MEME, failed to create output	pipe.\n";
      }
      else
      {
	# Initialize MEME result variables
        my $meme_out='';
	my $num_motifs=0;
	my %consensus;
	my $consensus='';
	my $motif=''; # Keeps track of which motif is being processed.
	my $evalue;
	my $pvalue; # p-value associated with a motif and an ORF.
	my $block;
	my $strand='';
	my $dummy;
	my %motifs;
	my %widths;
	my $width;
	my %sites;
	my %llrs;
	my %evalues;
	my %seen_combined_text;
	my @motifs; # Motif names stored along with their e-values for sorting.
	my %orfs;
	my @orfs;
	my @hits;
	my $hit;
	my ($position,$strand,$pvalue);
	my $in_pssm=0;
	my %pssm;
	my $pssm;
	while(<MEME_OUT>)
	{
	  $meme_out .= $_;
	  chop;
# print STDOUT "$_\n";

	  # Get some information about the motif in general
	  if(/^MOTIF\s+(\d+)\s+width\s*=\s*(\d+)\s+sites\s*=\s*(\d+)\s+llr\s*=\s*(\d+)\s+E-value\s*=\s*([0-9.e\+\-]+)/)
	  {
	    $motif = $1;
	    $widths{$motif} = $2;
	    $sites{$motif} = $3;
	    $llrs{$motif} = $4;
	    $evalue = $5;
	    $seen_combined_text{$motif}=0;
	    push(@motifs,"$motif $evalue");
# print STDERR "\n\n\n++++++++++\n\nmotif[$1] width[$2] sites[$3] llr[$4] e-value[$5]\n\n\n++++++++++\n\n\n";
	  }

	  # Get the consensus sequence for the motif.
	  elsif(/^Multilevel\s+([ACGTacgt]+)/)
	  {
	    $consensus{$motif} = $1;
# print STDERR "\n\n\nYES --> [$1]\n\n\n";
	  }

	  # Mark whether we've seen the text indicating the final results
	  # for this motif are going to be reported for each ORF.
	  elsif(/^\s*Combined\s+block\s+diagrams:\s+non-overlapping/)
	  {
	    $seen_combined_text{$motif} = 1;
	  }

	  # Get the p-values associated with the ORFs along with where
	  # the motif occurs in the ORF.
	  elsif($seen_combined_text{$motif} and
	  	/^\S+\s+[0-9.e\+\-]+\s+\S+/)
#	  	/^(\S+)\s+([0-9.e\+\-]+)\s+(\d+)_\[([\+\-]*)([0-9]+)\]_(\d+)/)
	  {
	    # ($orf,$pvalue,$block) = ($1,$2,$3);
	    s/-[-]+//g;
	    if(/\S/)
	    {
	      ($orf,$pvalue,$block) = split;
	      $orfs{$motif} .= "$orf $pvalue $block" . "\t";
	    }
	  }
	  # See if the position-specific scoring matrix is being reported now:
	  elsif(/Motif\s+\d+\s+position-specific\s+scoring\s+matrix/)
	  {
	    $in_pssm=1;
	  }

	  # Get the position-specific scoring matrix:
	  elsif($in_pssm)
	  {
	    if(not(/\S/))
	    {
	      $pssm{$motif} = $pssm;
	      $in_pssm=0;
	    }
	    elsif(/^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$/)
	    # elsif(/^\s*(\S+)\s+(\S+)/)
	    {
	      # MEME returns in A, C, G, T (alphabetical) order:
	      $pssm .= "$1;$2;$3;$4 ";
	    }
	  }
	}
        close(MEME_OUT);


	# Save the raw MEME output to a file.
	my $motif_out_path = $prefix . ".fmc.run_$r.$program.txt";
	my $motif_out_file = &getPathSuffix($motif_out_path);
	if(not(open(MEME_OUT,">$motif_out_path")))
	{
	  print STDERR "Could not create MEME output file $motif_out_path.\n";
	}
	else
	{
	  print MEME_OUT $meme_out;
	  close(MEME_OUT);
	}

	# Sort the motifs by their E-values.
	@motifs = sort by_evalue @motifs;

	foreach $motif (@motifs)
	{
	  ($motif,$evalue) = split(' ', $motif);
	  chop($orfs{$motif});

	  $consensus = $consensus{$motif};
	  print MASTER_OUT "  <Motif",
	  		" Consensus=\"$consensus\"",
	  		" Program=\"$program\"",
			" NumOrfs=\"$found_porfs\"",
			" UseBothStrands=\"$use_both_strands\"",
			" EValue=\"$evalue\"",
			" ProgramDumpFile=\"$motif_out_file\">\n";
# print STDOUT "[$motif] [$evalue] [$orfs{$motif}]\n";
	  # $widths{$motif} = $2;
	  # $sites{$motif} = $3;
	  # $llrs{$motif} = $4;
	  # $evalues{$motif} = $5;
	  # $seen_combined_text{$motif}=0;

	  # Print out which ORFs the motif occurs in (first sort by p-value)
	  @orfs = split("\t",$orfs{$motif});
	  @orfs = sort by_pvalue @orfs;
	  print MASTER_OUT "    <POrfs Upstream=\"$upstream_size\">\n";
	  my $width = $widths{$motif};
	  my $len;
	  foreach $orf (@orfs)
	  {
	    ($orf, $pvalue, $block) = split(/\s+/, $orf);
	    $len = $porf_seq_lens{$orf};

	    print MASTER_OUT	"      <Orf Name=\"$orf\"",
	    			" PValue=\"$pvalue\">\n";

	    # Extract where the motif hits the sequence (possibly multiple):
	    @hits = &block2hits($block,$width);

	    foreach my $hit (@hits)
	    {
	      ($position,$strand,$pvalue) = split("\t",$hit);

	      if($three_prime_numbering eq 'true')
	      {
	        $position = $len - $position + 1;
	      }

	      print MASTER_OUT	"        <Position",
	      			" Num=\"$position\"",
				" PValue=\"$pvalue\"",
				" Strand=\"$strand\">",
				"</Position>\n";
	    }

	    print MASTER_OUT	"      </Orf>\n";
	  }
	  print MASTER_OUT "    </POrfs>\n";

	  # Print the PSSM out:
	  $pssm = $pssm{$motif}; chop($pssm);
	  my @pssms = split(' ',$pssm);
	  my $p=0;
	  print MASTER_OUT "    <Weights>\n";
	  foreach $pssm (@pssms)
	  {
	    print MASTER_OUT "      <Position",
	    		     " Num=\"$p\"",
			     " Weights=\"$pssm\">",
			     "</Position>\n";
	    $p++;
	  }
	  print MASTER_OUT "    </Weights>\n";
	  print MASTER_OUT "  </Motif>\n";
	}
      }
      print STDERR ">>--- Run $r (MEME) Completed ---<<\n";
    }
  }
  elsif($program eq 'MOTOR')
  {
	 my $motor_args = "";
	 $motor_args .= " " . $AV{"motor_weights_file"};
	 $motor_args .= $AV{"use_both_strands"} eq "true" ? " -u " : ""; 
	 $motor_args .= exists($AV{"motif_length"}) ? " -L " . $AV{"motif_length"} : "";
	 $motor_args .= exists($AV{"motor_seed_length"}) ? " -S " . $AV{"motor_seed_length"} : "";
	 $motor_args .= exists($AV{"motor_projection_dist"}) ? " -p " . $AV{"motor_projection_dist"} : "";
	 $motor_args .= exists($AV{"motor_projection_num"}) ? " -n " . $AV{"motor_projection_num"} : "";
	 $motor_args .= exists($AV{"motor_num_test_seeds"}) ? " -T " . $AV{"motor_num_test_seeds"} : "";

    my $motor_result_file = "$tmp_dir/motor_run_" . $r . '_' . $tracking_num . ".out";
	 my $motor = "/u/erans/develop/frog_linux/SamplePrograms/test_pssm ";
	 if (exists($AV{"program_exe_$program_number"})) { $motor = $AV{"program_exe_$program_number"}; }
    $cmd = "$motor $porf_fasta $motor_args";
    $cmd .= " > $motor_result_file";
    push(@files_to_remove,$motor_result_file);
    if(length($cmd)>0)
    {
      print STDERR "<<--- Run $r (MOTOR) Started --->>\n";
      print STDERR "$cmd\n";
      `$cmd`;
      print STDERR ">>--- Run $r (MOTOR) Completed ---<<\n";
    }
  }
}
print MASTER_OUT "</Motifs>\n";

# program_1=alignace
# program_2=meme
# initial_concensus_1=CACTGACTG
# upstream_size_1=500
# upstream_size_2=1000
# num_runs=3
# run_1=program_1,upstream_size_1,initial_concensus_1
# run_2=program_1,upstream_size_1
# run_3=program_2,upstream_size_2
# upstream_sequence_file=/firepower/sc2/eran/data/yeast/all_upstream.fasta
# orf_1=YLR046W
# orf_2=YBG046C
# orf_3=YLR0346W
# orf_4=YLR086W

push(@files_to_remove,$porf_fasta);
push(@files_to_remove,$norf_fasta);

if($rm_tmp_files eq 'true')
  { &cleanup(@files_to_remove); }

exit(0);

sub extract_orf_seqs # ($tmp_dir, $rm_tmp_files, $tracking_num, $fasta_file, $uppercase, $verbose, $orf_fasta_file, @orfs)
{
  my $tmp_dir = shift;
  my $rm_tmp_files = shift;
  my $tracking_num = shift;
  my $fasta_file = shift;
  my $uppercase = shift;
  my $verbose = shift;
  my $zcat = 'zcat';
  my $cat = 'cat';
  my $orf_fasta_file = shift;
  my @orfs = @_;
  my $fasta_file_tmp;
  my @files_to_remove;
  my %orfs;
  my %orig;
  my $prev;
  my $orf;
  my $seq_name = undef;
  my $seq = undef;

  # If the file is gzipped, place a zcat in the pipe:
  my $pipe = '';
  if($fasta_file =~ /^(.+\.[^.]+)\.[Gg][Zz]$/)
  { 
    $pipe = "$zcat < $fasta_file |";
    $fasta_file = $1;
  }
  # Otherwise do a regular cat:
  else
  {
    $pipe = "$cat < $fasta_file |";
  }

  # If the file is a STAB file, convert to FASTA in the pipe:
  if($fasta_file =~ /^(.+)\.[Ss][Tt][Aa][Bb]$/)
  {
    $pipe .= ' stab2fasta.pl |';
  }

# print STDERR "pipe: [$pipe]\n";

  # Try to open the FASTA pipe:
  if(not(open(FASTA,$pipe)))
  {
    print STDERR "Could not open FASTA pipe $pipe for parsing.\n";
    exit(7);
  }

  # Try to open the output file for writing
  elsif(not(open(ORFS, ">$orf_fasta_file")))
  {
    print STDERR "Could not open OUTPUT file $orf_fasta_file for writing.\n";
    exit(7);
  }

  # Create a new FASTA file containing only the sequences belong to the ORFs
  # in the list.
  else
  {
    # convert the orf list into a hash for lookup:
    foreach $orf (@orfs)
    {
      $prev = $orf;
      if($uppercase)
      {
        $orf =~ tr/a-z/A-Z/;
      }
      $orfs{$orf} = 1;
      $orig{$orf} = $prev;
    }
    while(<FASTA>)
    {
      chop;
      if(/^\>\s*(\S+)/)
      {
	if(defined($seq_name) and exists($orfs{$seq_name}))
	{
	  print ORFS ">$orig{$seq_name}\n$seq\n";
	}
        $seq_name = $1;
	if($uppercase)
	{
	  $seq_name =~ tr/a-z/A-Z/;
	}
	$seq_name =~ s/\s//g;
	$seq = '';
      }
      elsif(/\S/)
      {
	s/\s//g;
        $seq .= $_;
      }
    }
    # see if last sequence is one of the ORFs we want.
    if(defined($seq_name) and exists($orfs{$seq_name}))
    {
      print ORFS ">$orig{$seq_name}\n$seq\n";
    }
    close(FASTA);
    close(ORFS);
    # Create a new FASTA file that contains only the sequences requested.
  }

  if($rm_tmp_files eq 'true')
    { &cleanup(@files_to_remove); }
}

sub modify_orf_seqs # ($fasta_in, $upstream_size, $fasta_out)
{
  my ($fasta_in, $upstream_size, $fasta_out) = @_;
  my ($beg,$len,$subseq,$seq,$seq_name);
  my %seq_lens;

  if(not(open(FASTA_IN,$fasta_in)))
  {
    print STDERR "find_motifs_in_cluster.pl: modify_orf_seqs():\n",
    		"\tcould not open FASTA input file $fasta_in.\n";
    #exit(6);
  }
  elsif(not(open(FASTA_OUT,">$fasta_out")))
  {
    print STDERR "find_motifs_in_cluster.pl: modify_orf_seqs():\n",
    		"\tcould not open FASTA output file $fasta_out.\n";
    exit(6);
  }
  else
  {
    while(<FASTA_IN>)
    {
      chop;
      if(/^\>\s*(\S+)/)
      {
	if(defined($seq_name))
	{
	  $subseq = &manipulate_seq($seq,$upstream_size);
	  $seq_lens{$seq_name} = length($subseq);
	  print FASTA_OUT ">$seq_name\n$subseq\n";
	}
        $seq_name = $1;
	if($uppercase)
	{
	  $seq_name =~ tr/a-z/A-Z/;
	}
	$seq = '';
      }
      elsif(/\S/)
      {
	s/\s//g;
        $seq .= $_;
      }
    }
    # Print the last sequence out
    if(defined($seq_name))
    {
      $subseq = &manipulate_seq($seq,$upstream_size);
      $seq_lens{$seq_name} = length($subseq);
      print FASTA_OUT ">$seq_name\n$subseq\n";
    }
    close(FASTA_IN);
    close(FASTA_OUT);
    return %seq_lens;
  }
}

sub manipulate_seq # ($seq, $upstream_size)
{
  # First take subsequence:
  my ($seq,$upstream_size) = @_;
  my $beg = length($seq) - $upstream_size;
  $beg = ($beg<0) ? 0 : $beg;
  my $len = $upstream_size;
  $len = ($len>length($seq)) ? length($seq) : $len;
  my $subseq = substr($seq, $beg, $len);

  return $subseq;
}

sub cleanup # (@files)
{
  my @files = @_;
  foreach my $file (@files)
  {
    if(-f $file)
    {
      # Delete the file.
      unlink($file);
    }
  }
}

# Sorts motifs by their E-value
sub by_evalue # ($a,$b) - globals
{
  my ($a_motif,$a_ev) = split(/\s+/,$a);
  my ($b_motif,$b_ev) = split(/\s+/,$b);
  return $a_ev<=> $b_ev;
}

# Sorts ORFs by p-value
sub by_pvalue # ($a,$b) - globals
{
  my ($a_orf,$a_pv) = split(/\s+/,$a);
  my ($b_orf,$b_pv) = split(/\s+/,$b);
  return $a_pv<=> $b_pv;
}

# Extracts motif occurrance information from a MEME block diagram:
sub block2hits # ($block,$slen,$width) 
	# - $block - diagram
	# - $width - length of the motif
{
  my ($block,$width) = @_;

  # Blocks are underscore delimited and have following format (example):
  #
  # 684_[-1(5.74e-07)]_168_[+1(2.59e-05)]_130
  #
  # which has 2 hits: one at position 684+width+168
  my @tokens = split('_', $block);
  my @hits;
  my $strand;
  my $pvalue;
  my $position=0;
  foreach my $token (@tokens)
  {
    if($token =~ /^\[([\+\-])1\(([0-9e\-\+.]+)\)\]/)
    # if($token =~ /^\[([\+\-])/)
    {
# print STDERR "\n\n[$token]\n\n";
      ($strand,$pvalue) = ($1,$2);
      push(@hits,"$position\t$strand\t$pvalue");
    }
    else
    {
      $position += ($position==0) ? int($token)+1 : int($token)+$width+1;
    }
  }
  return @hits;
}

__DATA__
syntax: find_motifs_in_cluster.pl FILE

where FILE (usually with *.fmc extension) has the following format:

program_1=alignace
program_2=MEME
initial_concensus_1=CACTGACTG
upstream_size_1=500
upstream_size_2=1000
run_1=program_1,initial_concensus_1,upstream_size_1
run_2=program_1,upstream_size_1
run_3=program_2,upstream_size_2
upstream_sequence_file=/firepower/sc2/eran/data/yeast/all_upstream.fasta
orf_1=YLR046W
orf_2=YBG046C
orf_3=YLR0346W
orf_4=YLR086W

# Newly added parameters:
background_sequence_file=$HOME/D/worm/dna/dn_1000.fa.gz

output: file (called example.fmc.xml) with the following format:

num_motifs=2
motif_1=example_1.CGAGC.motif
motif_2=example_2.CTGAGAGC.motif
motif_3=example_3.CTGAGAGC.motif

each motif file (like example_3.CTGAGAGC.motif) has:
concensus=CTGAGAGC
pvalue=3.4e-10
upstream_size=500
num_genes=345
output_start=alignace
.... (the stuff we thought was relevant from alignace's output) ....
output_end=alignace

