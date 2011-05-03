#!/usr/local/bin/perl

use strict;
use warnings;

my @fields = (
                  'id'
	        , 'generic_name'
	        , 'brand_names'
	        , 'swissprot_target'
	        , 'pharmgkb'
	        , 'kegg'
	        , 'iupac_name'
	        , 'category'
	        , 'mechanism'
	        , 'pharmacology'
	        , 'desc'
	     );

my %data;
my %fsm;
&clearHash(\%data);
&clearHash(\%fsm);
print STDOUT join("\t", @fields), "\n";
while(<>) {
   if(/^#BEGIN_DRUGCARD\s+(DB\d+)/) {
      $data{'id'} = $1;
   }
   elsif(/^#\s+Generic_Name:/) {
      $fsm{'next_is_generic_name'} = 1;
   }
   elsif(/^#\s+Brand_Names:/) {
      $fsm{'next_is_brand_names'} = 1;
   }
   elsif(/^#\s+Drug_Target_\d+_SwissProt_ID:/) {
      $fsm{'next_is_swissprot_target'} = 1;
   }
   elsif(/^#\s+PharmGKB_ID:/) {
      $fsm{'next_is_pharmgkb'} = 1;
   }
   elsif(/^#\s+KEGG_Drug_ID:/) {
      $fsm{'next_is_kegg'} = 1;
   }
   elsif(/^#\s+Drug_Category:/) {
      $fsm{'next_is_category'} = 1;
   }
   elsif(/^#\s+Chemical_IUPAC_Name:/) {
      $fsm{'next_is_iupac_name'} = 1;
   }
   elsif(/^#\s+Mechanism_Of_Action:/) {
      $fsm{'next_is_mechanism'} = 1;
   }
   elsif(/^#\s+Pharmacology:/) {
      $fsm{'next_is_pharmacology'} = 1;
   }
   elsif(/^#\s+Description:/) {
      $fsm{'next_is_desc'} = 1;
   }
   elsif(/^#END_DRUGCARD\s+DB/) {
      &printData(\%data);
      &clearHash(\%data);
   }
   else {
      my @keys = keys(%fsm);
      foreach my $key (@keys) {
         $key =~ s/next_is_//;
         &storeData($key, $_, \%data, \%fsm);
      }
   }
}

exit(0);

sub storeData {
   my ($key, $line, $data, $fsm) = @_;
   if($line =~ /^\s*$/) {
      &clearHash($fsm);
   }
   else {
      chomp($line);
      if(not(exists($$data{$key}))) {
         $$data{$key} = $line;
      }
      else {
         $$data{$key} .= ',' . $line;
      }
   }
}

sub printData {
   my ($data) = @_;
   my @d;
   foreach my $field (@fields) {
      my $d = defined($$data{$field}) ? $$data{$field} : '';
      push(@d, $d);
   }
   print STDOUT join("\t", @d), "\n";
}

sub clearHash {
   my ($hash) = @_;
   my @keys = keys(%{$hash});
   foreach my $key (@keys) {
      delete($$hash{$key});
   }
}



