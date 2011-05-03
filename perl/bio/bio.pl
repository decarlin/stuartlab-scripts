#! /usr/bin/perl

if ($ARGV[0] eq "join_genes") { system("bio_join_genes.pl"); }
elsif ($ARGV[0] eq "add_column") { system("bio_add_column.pl"); }
elsif ($ARGV[0] eq "update_column") { system("bio_update_column.pl"); }
elsif ($ARGV[0] eq "convert_to_bicluster") { system("bio_convert_to_bicluster.pl"); }
elsif ($ARGV[0] eq "convert_to_pah") { system("bio_convert_to_pah.pl"); }
elsif ($ARGV[0] eq "fasta_to_sql") { print system("fasta_to_sql.pl"); }
