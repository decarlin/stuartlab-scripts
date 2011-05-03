#!/usr/local/bin/perl

require "$ENV{MYPERLDIR}/lib/libhtml.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

use strict;

sub parseBioCartaHtml(\$$$$)
{
   my ($page_ref, $table_no, $gene_col, $id_col) = @_;
   $table_no = defined($table_no) ? $table_no : 7;
   $gene_col = defined($gene_col) ? $gene_col : 4;
   $id_col   = defined($id_col) ? $id_col : 7;

   my ($pathway, $org) = &getBioCartaPathwayNameFromHtml($page_ref);

   my @genes;

   my @ids;

   my $tables = &html2table($$page_ref);

   foreach my $row (@{$$tables[$table_no-1]})
   {
      my ($gene, $id) = ($$row[$gene_col-1], $$row[$id_col-1]);
      push(@genes, $gene);
      push(@ids, $id);
   }

   return ($pathway, $org, \@genes, \@ids);
}

sub getBioCartaPathwayNameFromHtml(\$)
{
   my ($page_ref) = @_;

   my $pathway  = undef;
   my $organism = undef;

   if($$page_ref =~ /Pathway\s+Protein\s+List.+<I>([^<]*)<\/I>\s*-\s*([^<]+)/i)
   {
      $organism = $1;
      $pathway  = $2;

      $organism =~ s/^\s+//;
      $organism =~ s/\s+$//;
      $pathway  =~ s/^\s+//;
      $pathway  =~ s/\s+$//;

      if($organism !~ /\S/ and $pathway =~ /^pathway$/i)
      {
         ($pathway, $organism) = (undef, undef);
      }
   }
   return ($pathway, $organism);
}

1
