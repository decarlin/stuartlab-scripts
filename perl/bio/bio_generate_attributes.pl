#! /usr/bin/perl

#-------------------------------------------------------------------------------------------------------------------
# input:
#    BGA_source_type - "db" if the source file is in the database, "file" for a file (first line is the description)
#
#-------------------------------------------------------------------------------------------------------------------

use strict;

#---------
# Includes
#---------
require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_sql_table_dsc.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_dsc.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_sql_table_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/bio_str.pl";
require "$ENV{MYPERLDIR}/lib/bio_assert.pl";

#---------
# Settings
#---------
my %settings = load_settings($ARGV[0]);

my $mql = $settings{"BGA_mql"};
my $source_type = $settings{"BGA_source_type"};
my $source_table_name = $settings{"BGA_source_table_name"};
my $source_database_name = $settings{"BGA_source_database_name"};
my $source_file_name = $settings{"BGA_source_file_name"};
my $source_start_data_column = $settings{"BGA_source_start_data_column"} - 1;
my $source_end_data_column = $settings{"BGA_source_end_data_column"} - 1;
my $num_data_columns = $source_end_data_column - $source_start_data_column + 1;
my $source_start_data_row = $settings{"BGA_source_start_data_row"} - 1;
my $source_end_data_row = $settings{"BGA_source_end_data_row"} - 1;
my $num_data_rows = $source_end_data_row - $source_start_data_row + 1;
my $source_name_location_in_row = $settings{"BGA_source_name_location_in_row"} - 1;
my $rules_file = $settings{"BGA_rules_file"};
my $output_file = $settings{"BGA_output_file"};
my $dictionary_file = $settings{"BGA_dictionary_file"};

#--------
# Globals
#--------
my @data_attr_set;
my @data_values;

my %dictionary;

open(OUTPUT_FILE, ">$output_file");
open(RULES, "<$rules_file") or die "could not open the rules file: $rules_file";
open(OUTPUT_TSC_FILE, ">$output_file.tsc");

#---------------------------------------------------------------------------
# variables_rules is a 2-dimensional array, one array for each variable rule, each has the following structure:
#   entry 0: variable name
#   entry 1: operator_type (either avg, +, -)
#   entry 2: number of operands
#   entry 3: operand 1 type
#   entry 4: operand 1
#   entry 5: operand 2 type
#   entry 6: operand 2...
#---------------------------------------------------------------------------
my @variables_rules;
my %variable_names_to_ids;
my $num_variables = 0;

my @variable_output_names;
my %variable_outputs_to_names;
my $num_outputs = 0;
my @output_results;

my $VAR_NAME_ENTRY = 0;
my $VAR_OPERATOR_ENTRY = 1;
my $VAR_NUM_OPERANDS_ENTRY = 2;
my $VAR_OPERANDS_START_ENTRY = 3;

my $VAR_OPERATOR_PLUS = 0;
my $VAR_OPERATOR_MINUS = 1;
my $VAR_OPERATOR_MUL = 2;
my $VAR_OPERATOR_DIVISION = 3;
my $VAR_OPERATOR_AVERAGE = 4;
my $VAR_OPERATOR_MAX = 5;
my $VAR_OPERATOR_MIN = 6;
my $VAR_OPERATOR_OR = 7;
my $VAR_OPERATOR_AND = 8;
my $VAR_OPERATOR_NOT = 9;
my $VAR_OPERATOR_GREATER = 10;
my $VAR_OPERATOR_GREATER_EQUAL = 11;
my $VAR_OPERATOR_LESS = 12;
my $VAR_OPERATOR_LESS_EQUAL = 13;
my $VAR_OPERATOR_EQUAL = 14;
my $VAR_OPERATOR_NOT_EQUAL = 15;
my $VAR_OPERATOR_ASSIGNMENT = 16;
my $VAR_OPERATOR_NUMBER = 17;

my $VAR_OPERAND_TYPE_DATA_ENTRY = 0;
my $VAR_OPERAND_TYPE_VAR = 1;
my $VAR_OPERAND_TYPE_NUMBER = 2;

my $MISSING_VALUE = -999;

my $FALSE = 0;
my $TRUE = 1;

my $verbose = 0;

#------------------------------------------------------------------------------
# DEBUG
#------------------------------------------------------------------------------
sub DEBUG
{
  #print $_[0];
}

#------------------------------------------------------------------------------
# LoadDataMatrix
#------------------------------------------------------------------------------
sub LoadDataMatrix
{
  if ($source_type eq "db")
  {   
    @data_attr_set = get_sql_table_dsc($mql, $source_table_name, $source_database_name, $verbose);
    @data_values = load_sql_table_to_memory($mql, $source_table_name, $source_database_name, $verbose);
  }
  elsif ($source_type eq "file")
  {
    @data_attr_set = get_file_dsc($source_file_name, $verbose);
    @data_values = load_file_to_memory($source_file_name, $verbose);
  }
}

#---------------------------------------------------------------------------
# LoadDictionary
#---------------------------------------------------------------------------
sub LoadDictionary
{
  open(DICTIONARY, "<$dictionary_file");
  while (<DICTIONARY>)
  {
    chop;
    my @dictionary_data = split(/\t/);

    $dictionary{$dictionary_data[0]} = $dictionary_data[1] . " - " . $dictionary_data[2];

    #print "dictionary{$dictionary_data[0]}" . "=\t" . $dictionary{$dictionary_data[0]} . "\n";
  }
}

#---------------------------------------------------------------------------
# LoadDictionary
#---------------------------------------------------------------------------
sub ConvertFromDictionary
{
  my $convert_name = $_[0];

  if (length($dictionary{$convert_name}) > 0)
  {
    return $dictionary{$convert_name};
  }
  else
  {
    return $convert_name;
  }
}

#------------------------------------------------------------------------------
# GetDataValue
#------------------------------------------------------------------------------
sub GetDataValue
{
  my $row = $_[0] + $source_start_data_row;
  my $column = $_[1] + $source_start_data_column;

  assert($row <= $source_end_data_row && $column <= $source_end_data_column, "row <= source_end_data_row && column <= source_end_data_column -- Accessing non-existant row");

  if ($data_values[$row][$column] =~ /\S/)
  {
    return $data_values[$row][$column];
  }
  else
  {
    return $MISSING_VALUE;
  }
}

#---------------------------------------------------------------------------
# GetRowName
#---------------------------------------------------------------------------
sub GetRowName
{
  my ($row) = @_;

  my $real_row = $_[0] + $source_start_data_row;

  my $name = $data_values[$real_row][$source_name_location_in_row];

  return "$name\t";
}

#---------------------------------------------------------------------------
# GetRowDesc
#---------------------------------------------------------------------------
sub GetRowDesc
{
  my ($row, $additional_dsc) = @_;

  my $real_row = $_[0] + $source_start_data_row;

  my $name = $data_values[$real_row][$source_name_location_in_row];
  my $dsc = ConvertFromDictionary($name);

  return "$name\t$dsc $additional_dsc\t";
  #return "$name\t$dsc\t";
}

#---------------------------------------------------------------------------
# GetRowData
#---------------------------------------------------------------------------
sub GetRowData
{
  my ($row) = @_;

  my $str = "";

  for (my $column = 0; $column < $num_data_columns; $column++)
  {
    my $data_value = GetDataValue($row, $column);

    if ($data_value != $MISSING_VALUE)
    {
      $str .= "$data_value\t";
    }
    else
    {
      $str .= "\t";
    }
  }

  return $str;
}

#---------------------------------------------------------------------------
# AddOperand
#---------------------------------------------------------------------------
sub AddOperand
{
  my $operand_name = $_[0];
  my $start_entry = $_[1];

  if ($variable_names_to_ids{$operand_name} ne "")
  {
    my $var_index = $variable_names_to_ids{$operand_name};

    $variables_rules[$num_variables][$start_entry] = $VAR_OPERAND_TYPE_VAR;
    $variables_rules[$num_variables][$start_entry + 1] = $var_index;

    DEBUG("   add operand var=$operand_name var_index=$var_index\n");
  }
  elsif ($operand_name =~ /Exp([0-9]+)/)
  {
    $variables_rules[$num_variables][$start_entry] = $VAR_OPERAND_TYPE_DATA_ENTRY;
    $variables_rules[$num_variables][$start_entry + 1] = $1 - 1;

    DEBUG("   add operand data entry=$variables_rules[$num_variables][$start_entry + 1]\n");
  }
  else
  {
    $variables_rules[$num_variables][$start_entry] = $VAR_OPERAND_TYPE_NUMBER;
    $variables_rules[$num_variables][$start_entry + 1] = $operand_name;

    DEBUG("   add operand number=$operand_name\n");
  }
}

#---------------------------------------------------------------------------
# AddBinaryOperands
#---------------------------------------------------------------------------
sub AddUnaryAssignment
{
  my $var_assignment = $_[0];
  my $operator = $_[1];

  DEBUG("Adding unary assignment var=$var_assignment\n");

  $variables_rules[$num_variables][$VAR_OPERATOR_ENTRY] = $operator;
  $variables_rules[$num_variables][$VAR_NUM_OPERANDS_ENTRY] = 1;

  AddOperand($var_assignment, $VAR_OPERANDS_START_ENTRY);
}

#---------------------------------------------------------------------------
# AddBinaryOperands
#---------------------------------------------------------------------------
sub AddBinaryAssignment
{
  my $var_assignment = $_[0];
  my $operator = $_[1];
  my $operator_str = $_[2];

  $variables_rules[$num_variables][$VAR_OPERATOR_ENTRY] = $operator;
  $variables_rules[$num_variables][$VAR_NUM_OPERANDS_ENTRY] = 2;

  $var_assignment =~ /(.*)[\s]$operator_str[\s](.*)/;
  my $a = $1;
  my $b = $2;

  DEBUG("Adding binary assignment var=$variables_rules[$num_variables][$VAR_NAME_ENTRY] operator=$operator_str a=$a b=$b\n");

  AddOperand($a, $VAR_OPERANDS_START_ENTRY);
  AddOperand($b, $VAR_OPERANDS_START_ENTRY + 2);
}

#---------------------------------------------------------------------------
# AddFunctionAssignment
#---------------------------------------------------------------------------
sub AddFunctionAssignment
{
  my $var_assignment = $_[0];
  my $operator = $_[1];
  my $operator_str = $_[2];

  DEBUG("Adding function assignment var=$var_assignment $operator=$operator_str\n");

  $variables_rules[$num_variables][$VAR_OPERATOR_ENTRY] = $operator;

  $var_assignment =~ /$operator_str[\s]*[\(](.*)[\s]*[\)]/;
  my @operands = split(/\,/, $1);

  DEBUG("   operands=@operands\n");

  my $num_operands = @operands;

  $variables_rules[$num_variables][$VAR_NUM_OPERANDS_ENTRY] = $num_operands;

  for (my $i = 0; $i < $num_operands; $i++)
  {
    AddOperand($operands[$i], $VAR_OPERANDS_START_ENTRY + (2 * $i));
  }
}

#---------------------------------------------------------------------------
# AddVarAssignment
#---------------------------------------------------------------------------
sub AddVarAssignment
{
  my $var_assignment = $_[0];

  if ($var_assignment =~ /[\s]\+[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_PLUS, "+");
  }
  elsif ($var_assignment =~ /[\s]\-[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_MINUS, "-");
  }
  elsif ($var_assignment =~ /[\s]\*[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_MUL, "*");
  }
  elsif ($var_assignment =~ /[\s]\/[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_DIVISION, "/");
  }
  elsif ($var_assignment =~ /AVG[\(]/)
  {
    AddFunctionAssignment($var_assignment, $VAR_OPERATOR_AVERAGE, "AVG");
  }
  elsif ($var_assignment =~ /MAX[\(]/)
  {
    AddFunctionAssignment($var_assignment, $VAR_OPERATOR_MAX, "MAX");
  }
  elsif ($var_assignment =~ /MIN[\(]/)
  {
    AddFunctionAssignment($var_assignment, $VAR_OPERATOR_MIN, "MIN");
  }
  elsif ($var_assignment =~ /NOT[\(]/)
  {
    AddFunctionAssignment($var_assignment, $VAR_OPERATOR_NOT, "NOT");
  }
  elsif ($var_assignment =~ /OR[\(]/)
  {
    AddFunctionAssignment($var_assignment, $VAR_OPERATOR_OR, "OR");
  }
  elsif ($var_assignment =~ /AND[\(]/)
  {
    AddFunctionAssignment($var_assignment, $VAR_OPERATOR_AND, "AND");
  }
  elsif ($var_assignment =~ /[\s]>=[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_GREATER_EQUAL, ">=");
  }
  elsif ($var_assignment =~ /[\s]>[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_GREATER, ">");
  }
  elsif ($var_assignment =~ /[\s]<=[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_LESS_EQUAL, "<=");
  }
  elsif ($var_assignment =~ /[\s]<[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_LESS, "<");
  }
  elsif ($var_assignment =~ /[\s]==[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_EQUAL, "==");
  }
  elsif ($var_assignment =~ /[\s]!=[\s]/)
  {
    AddBinaryAssignment($var_assignment, $VAR_OPERATOR_NOT_EQUAL, "!=");
  }
  elsif ($var_assignment =~ /Exp/)
  {
    AddUnaryAssignment($var_assignment, $VAR_OPERATOR_ASSIGNMENT);
  }
  elsif ($var_assignment =~ /[0-9]+/)
  {
    AddUnaryAssignment($var_assignment, $VAR_OPERATOR_NUMBER);
  }
}

#---------------------------------------------------------------------------
# AddNewVar
#---------------------------------------------------------------------------
sub AddNewVar
{
  my $var_name = $_[0];
  my $var_assignment = $_[1];

  assert($variable_names_to_ids{$var_name} eq "", "variable_names_to_ids{$var_name} eq \"\" -- Variable $var_name was not found");

  $variable_names_to_ids{$var_name} = $num_variables;

  $variables_rules[$num_variables][$VAR_NAME_ENTRY] = $var_name;

  AddVarAssignment($var_assignment);

  $num_variables++;
}

#---------------------------------------------------------------------------
# LoadVars
#---------------------------------------------------------------------------
sub LoadVars
{
  my $done = 0;

  while ($done == 0)
  {
    my $line = <RULES>;
    chop $line;

    if ($line =~ /=/ && !($line =~ /\#/))
    {
      $line =~ /(.*)[\s\t]+[\=][\s\t]+(.*)/;
      my $var_name = $1;
      my $var_assignment = $2;

      DEBUG("LoadVars: var_name=$var_name var_assignment=$var_assignment\n");

      AddNewVar($var_name, $var_assignment);
    }
    elsif ($line eq "\}")
    {
      $done = 1;
    }
  }
}

#---------------------------------------------------------------------------
# LoadOutputs
#---------------------------------------------------------------------------
sub LoadOutputs
{
  my $done = 0;

  while ($done == 0)
  {
    my $line = <RULES>;
    chop $line;

    if ($line =~ /=/ && !($line =~ /\#/))
    {
      $line =~ /(.*)[\s\t]+[\=][\s\t]+(.*)/;
      my $var_name = $1;
      my $var_output_name = $2;

      DEBUG("LoadOutputs: var_name=$var_name var_output_name=$var_output_name\n");

      assert($variable_names_to_ids{$var_name} ne "", "variable_names_to_ids{$var_name} ne \"\" -- Variable $var_name was not found");

      $variable_output_names[$num_outputs] = $var_name;
      $variable_outputs_to_names{$var_name} = $var_output_name;
      $num_outputs++;
    }
    elsif ($line eq "\}")
    {
      $done = 1;
    }
  }
}

#---------------------------------------------------------------------------
# LoadRules
#---------------------------------------------------------------------------
sub LoadRules
{
  while(<RULES>)
  {
    chop;

    my $str = trim_leading_spaces($_);

    if ($str eq "Vars")
    {
      LoadVars;
    }
    elsif ($str eq "Outputs")
    {
      LoadOutputs;
    }
  }
}

#---------------------------------------------------------------------------
# CalculatePlusVariableInst
#---------------------------------------------------------------------------
sub CalculateOperandVariableInst ($$\@$)
{
  my ($row, $var, $vec, $operand_start_idx) = @_;
  my @variable_insts = @$vec;
  my $result;

  if ($variables_rules[$var][$operand_start_idx] == $VAR_OPERAND_TYPE_VAR)
  {
    my $var_index = $variables_rules[$var][$operand_start_idx + 1];
    $result = $variable_insts[$var_index];
  }
  elsif ($variables_rules[$var][$operand_start_idx] == $VAR_OPERAND_TYPE_DATA_ENTRY)
  {
    my $data_column = $variables_rules[$var][$operand_start_idx + 1];

    $result = GetDataValue($row, $data_column);
  }
  elsif ($variables_rules[$var][$operand_start_idx] == $VAR_OPERAND_TYPE_NUMBER)
  {
    $result = $variables_rules[$var][$operand_start_idx + 1];
  }

  return $result;
}

#---------------------------------------------------------------------------
# CalculatePlusVariableInst
#---------------------------------------------------------------------------
sub CalculatePlusVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  return $a + $b;
}

#---------------------------------------------------------------------------
# CalculateMinusVariableInst
#---------------------------------------------------------------------------
sub CalculateMinusVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  return $a - $b;
}

#---------------------------------------------------------------------------
# CalculateMulVariableInst
#---------------------------------------------------------------------------
sub CalculateMulVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  return $a * $b;
}

#---------------------------------------------------------------------------
# CalculateDivisionVariableInst
#---------------------------------------------------------------------------
sub CalculateDivisionVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  return $a / $b;
}

#---------------------------------------------------------------------------
# CalculateAverageVariableInst
#---------------------------------------------------------------------------
sub CalculateAverageVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $sum = 0;
  my $num = 0;
  my $total_num = $variables_rules[$var][$VAR_NUM_OPERANDS_ENTRY];

  for (my $i = 0; $i < $total_num; $i++)
  {
    my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2 * $i);

    if ($a != $MISSING_VALUE)
    {
      $sum += $a;
      $num++;
    }
  }

  if ($num > 0) { return $sum / $num; }
  else { return $MISSING_VALUE; }
}

#---------------------------------------------------------------------------
# CalculateMaxVariableInst
#---------------------------------------------------------------------------
sub CalculateMaxVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $max = $MISSING_VALUE;
  my $total_num = $variables_rules[$var][$VAR_NUM_OPERANDS_ENTRY];

  for (my $i = 0; $i < $total_num; $i++)
  {
    my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2 * $i);

    if ($a != $MISSING_VALUE && ($a > $max || $max == $MISSING_VALUE))
    {
      $max = $a;
    }
  }
  
  return $max;
}

#---------------------------------------------------------------------------
# CalculateMinVariableInst
#---------------------------------------------------------------------------
sub CalculateMinVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $min = $MISSING_VALUE;
  my $total_num = $variables_rules[$var][$VAR_NUM_OPERANDS_ENTRY];

  for (my $i = 0; $i < $total_num; $i++)
  {
    my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2 * $i);

    if ($a != $MISSING_VALUE && ($a < $min || $min == $MISSING_VALUE))
    {
      $min = $a;
    }
  }

  return $min;
}

#---------------------------------------------------------------------------
# CalculateOrVariableInst
#---------------------------------------------------------------------------
sub CalculateOrVariableInst ($$\@)
{
  my ($row, $var,$vec) = @_;
  my @variable_insts = @$vec;

  my $result = $FALSE;
  my $total_num = $variables_rules[$var][$VAR_NUM_OPERANDS_ENTRY];

  for (my $i = 0; $i < $total_num; $i++)
  {
    my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2 * $i);

    if ($a == $TRUE)
    {
		$result = $TRUE;
    }
  }

  return $result;

  #my ($row, $var, $vec) = @_;
  #my @variable_insts = @$vec;

  #my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  #my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  #if ($a == $TRUE || $b == $TRUE) { return $TRUE; }
  #else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateAndVariableInst
#---------------------------------------------------------------------------
sub CalculateAndVariableInst ($$\@)
{
  my ($row, $var,$vec) = @_;
  my @variable_insts = @$vec;

  my $result = $TRUE;
  my $total_num = $variables_rules[$var][$VAR_NUM_OPERANDS_ENTRY];

  for (my $i = 0; $i < $total_num; $i++)
  {
    my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2 * $i);

    if ($a == $FALSE)
    {
		$result = $FALSE;
    }
  }

  return $result;

  #my ($row, $var, $vec) = @_;
  #my @variable_insts = @$vec;

  #my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  #my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  #if ($a == $TRUE && $b == $TRUE) { return $TRUE; }
  #else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateNotVariableInst
#---------------------------------------------------------------------------
sub CalculateNotVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);

  if ($a == $FALSE) { return $TRUE; }
  else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateGreaterVariableInst
#---------------------------------------------------------------------------
sub CalculateGreaterVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  if ($a > $b) { return $TRUE; }
  else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateGreaterEqualVariableInst
#---------------------------------------------------------------------------
sub CalculateGreaterEqualVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  if ($a >= $b) { return $TRUE; }
  else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateLessVariableInst
#---------------------------------------------------------------------------
sub CalculateLessVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  if ($a < $b) { return $TRUE; }
  else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateLessEqualVariableInst
#---------------------------------------------------------------------------
sub CalculateLessEqualVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  if ($a <= $b) { return $TRUE; }
  else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateEqualVariableInst
#---------------------------------------------------------------------------
sub CalculateEqualVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  if ($a == $b) { return $TRUE; }
  else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateNotEqualVariableInst
#---------------------------------------------------------------------------
sub CalculateNotEqualVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);
  my $b = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY + 2);

  if ($a != $b) { return $TRUE; }
  else { return $FALSE; }
}

#---------------------------------------------------------------------------
# CalculateAssignmentVariableInst
#---------------------------------------------------------------------------
sub CalculateAssignmentVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = CalculateOperandVariableInst($row, $var, @variable_insts, $VAR_OPERANDS_START_ENTRY);

  return $a;
}

#---------------------------------------------------------------------------
# CalculateNumberVariableInst
#---------------------------------------------------------------------------
sub CalculateNumberVariableInst ($$\@)
{
  my ($row, $var, $vec) = @_;
  my @variable_insts = @$vec;

  my $a = $variables_rules[$var][$VAR_OPERANDS_START_ENTRY + 1];

  return $a;
}

#---------------------------------------------------------------------------
# CalculateVariableInsts
#---------------------------------------------------------------------------
sub CalculateVariableInsts
{
  my $row = $_[0];
  my @variable_insts;

  for (my $var = 0; $var < $num_variables; $var++)
  {
    my $operator = $variables_rules[$var][$VAR_OPERATOR_ENTRY];

    if ($operator == $VAR_OPERATOR_PLUS) { $variable_insts[$var] = CalculatePlusVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_MINUS) { $variable_insts[$var] = CalculateMinusVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_MUL) { $variable_insts[$var] = CalculateMulVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_DIVISION) { $variable_insts[$var] = CalculateDivisionVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_AVERAGE) { $variable_insts[$var] = CalculateAverageVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_MAX) { $variable_insts[$var] = CalculateMaxVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_MIN) { $variable_insts[$var] = CalculateMinVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_OR) { $variable_insts[$var] = CalculateOrVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_AND) { $variable_insts[$var] = CalculateAndVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_NOT) { $variable_insts[$var] = CalculateNotVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_GREATER) { $variable_insts[$var] = CalculateGreaterVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_GREATER_EQUAL) { $variable_insts[$var] = CalculateGreaterEqualVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_LESS) { $variable_insts[$var] = CalculateLessVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_LESS_EQUAL) { $variable_insts[$var] = CalculateLessEqualVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_EQUAL) { $variable_insts[$var] = CalculateEqualVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_NOT_EQUAL) { $variable_insts[$var] = CalculateNotEqualVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_ASSIGNMENT) { $variable_insts[$var] = CalculateAssignmentVariableInst($row, $var, @variable_insts); }
    elsif ($operator == $VAR_OPERATOR_NUMBER) { $variable_insts[$var] = CalculateNumberVariableInst($row, $var, @variable_insts); }

    DEBUG("CalculateVariableInsts row=$row operator=$operator var_name=$variables_rules[$var][$VAR_NAME_ENTRY] value=$variable_insts[$var]\n");
  }

  return @variable_insts;
}

#---------------------------------------------------------------------------
# AddToOutputs
#---------------------------------------------------------------------------
sub AddToOutputs ($\@)
{
  my ($row, $vec) = @_;
  my @variable_insts = @$vec;

  for (my $i = 0; $i < $num_outputs; $i++)
  {
    my $var_name = $variable_output_names[$i];

    my $var_index = $variable_names_to_ids{$var_name};

    my $var_value = $variable_insts[$var_index];

    if ($var_value == $TRUE) { $output_results[$i][$row] = $TRUE; }
    else { $output_results[$i][$row] = $FALSE; }

    DEBUG("AddToOutputs row=$row output=$var_name value=$output_results[$i][$row]\n");
  }
}

#---------------------------------------------------------------------------
# LoadRules
#---------------------------------------------------------------------------
sub ExecuteRules
{
  for (my $row = 0; $row < $num_data_rows; $row++)
  {
    my @variables_insts = CalculateVariableInsts($row);

    AddToOutputs($row, @variables_insts);

	 if ($row % 10 == 0) { print "Processing row $row...\n"; }
  }
}

#---------------------------------------------------------------------------
# PrintOutputs
#---------------------------------------------------------------------------
sub PrintOutputs
{
  for (my $i = 0; $i < $num_outputs; $i++)
  {
    my $var_name = $variable_output_names[$i];

    my $var_output_name = $variable_outputs_to_names{$var_name};

    print OUTPUT_FILE "$var_output_name\n";

    for (my $row = 0; $row < $num_data_rows; $row++)
    {
      if ($output_results[$i][$row] == $TRUE)
      {
        my $str = GetRowDesc($row, "");
        print OUTPUT_FILE "$str\n";
      }
    }

    print OUTPUT_FILE "\n";
  }
}

#---------------------------------------------------------------------------
# PrintTSC
#---------------------------------------------------------------------------
sub PrintRawData
{
  print OUTPUT_TSC_FILE "\n<TSCRawData>\n";

  print OUTPUT_TSC_FILE "UID\tNAME\tGWEIGHT\t";
  for (my $column = 0; $column < $num_data_columns; $column++)
  {
    print OUTPUT_TSC_FILE $data_attr_set[$source_start_data_column + $column] . "\t";
  }
  print OUTPUT_TSC_FILE "\n";

  for (my $i = 0; $i < $num_outputs; $i++)
  {
    my $var_name = $variable_output_names[$i];

    my $var_output_name = $variable_outputs_to_names{$var_name};

    for (my $row = 0; $row < $num_data_rows; $row++)
    {
      if ($output_results[$i][$row] == $TRUE)
      {
        my $str = GetRowDesc($row, $var_output_name);
        print OUTPUT_TSC_FILE ($i + 1) . "-${str}1\t";

        $str = GetRowData($row);
        print OUTPUT_TSC_FILE "$str\n";
      }
    }
  }

  print OUTPUT_TSC_FILE "</TSCRawData>\n"
}

#---------------------------------------------------------------------------
# print the cluster matrix
#---------------------------------------------------------------------------
sub PrintClusterMatrix
{
  print OUTPUT_TSC_FILE "\n<TSCClusterData NumClusters=\"$num_outputs\">\n";

  for (my $i = 0; $i < $num_outputs; $i++)
  {
    for (my $row = 0; $row < $num_data_rows; $row++)
    {
      if ($output_results[$i][$row] == $TRUE)
      {
        for (my $column = 0; $column < $num_data_columns; $column++)
        {
          print OUTPUT_TSC_FILE $i . "\t";
        }
        print OUTPUT_TSC_FILE "\n";
      }
    }
  }

  print OUTPUT_TSC_FILE "</TSCClusterData>\n";
}

#---------------------------------------------------------------------------
# PrintTSC
#---------------------------------------------------------------------------
sub PrintHierarchy
{
  print OUTPUT_TSC_FILE "\n<TSCHierarchyClusterData NumClusters=\"" . (2 * $num_outputs - 1) . "\">\n";

  my $internal_cluster_num = 2 * $num_outputs - 2;
  my $leaf_num = $num_outputs - 1;
  for (my $i = 0; $i < $num_outputs; $i++)
  {
    for (my $indent = 0; $indent < $i; $indent++) { print OUTPUT_TSC_FILE "  "; }

    if ($i == 0)
    {
      print OUTPUT_TSC_FILE "<Root ClusterNum=\"$internal_cluster_num\" NumChildren=\"2\" ";
      print OUTPUT_TSC_FILE "SplitAttribute=\"OutputNum\" SplitValue=\"$internal_cluster_num\">\n";
		$internal_cluster_num--;
    }
    else
    {
		my $num_children;
		if ($leaf_num == 0)
		{
		  print OUTPUT_TSC_FILE "<Child ClusterNum=\"$leaf_num\" NumChildren=\"0\" ";
		  print OUTPUT_TSC_FILE "SplitAttribute=\"OutputNum\" SplitValue=\"$leaf_num\" ParentSplit=\"true\">\n";
		  $leaf_num--;
		}
		else
		{
		  print OUTPUT_TSC_FILE "<Child ClusterNum=\"$internal_cluster_num\" NumChildren=\"2\" ";
		  print OUTPUT_TSC_FILE "SplitAttribute=\"OutputNum\" SplitValue=\"$internal_cluster_num\" ParentSplit=\"true\">\n";
		  $internal_cluster_num--;
		}

    }

    if ($leaf_num > 0)
    {
      for (my $indent = 0; $indent < $i + 1; $indent++) { print OUTPUT_TSC_FILE "  "; }

      print OUTPUT_TSC_FILE "<Child ClusterNum=\"$leaf_num\" NumChildren=\"0\" ";
      print OUTPUT_TSC_FILE "SplitAttribute=\"OutputNum\" SplitValue=\"$leaf_num\" ParentSplit=\"false\">\n";

      for (my $indent = 0; $indent < $i + 1; $indent++) { print OUTPUT_TSC_FILE "  "; }
      print OUTPUT_TSC_FILE "</Child>\n";

		$leaf_num--;
    }
  }

  for (my $i = $num_outputs - 1; $i >= 0; $i--)
  {
    for (my $indent = 0; $indent < $i; $indent++) { print OUTPUT_TSC_FILE "  "; }

    if ($i == 0)
    {
      print OUTPUT_TSC_FILE "</Root>\n";
    }
    else
    {
      print OUTPUT_TSC_FILE "</Child>\n";
    }
  }

  print OUTPUT_TSC_FILE "</TSCHierarchyClusterData>\n";
}

#---------------------------------------------------------------------------
# PrintTSC
#---------------------------------------------------------------------------
sub PrintTSC
{
  print OUTPUT_TSC_FILE "<?xml version='1.0' encoding='utf-8'?>\n\n<TSC>\n";

  PrintRawData;

  PrintClusterMatrix;

  PrintHierarchy;

  print OUTPUT_TSC_FILE "\n</TSC>\n";
}

#---------------------------------------------------------------------------
# PrintOutputs
#---------------------------------------------------------------------------
sub PrintSQL
{
  open(OUTPUT_SQL_DSC_FILE, ">$output_file.sql");
  open(OUTPUT_SQL_DATA_FILE, ">$output_file.dat");

  my $table_name = "g_generated_attributes";
  print OUTPUT_SQL_DSC_FILE "drop table if exists $table_name;\n";
  print OUTPUT_SQL_DSC_FILE "create table $table_name(\n";
  print OUTPUT_SQL_DSC_FILE "gene_name char(50)";
  for (my $i = 0; $i < $num_outputs; $i++)
  {
    my $var_name = $variable_output_names[$i];

    my $var_output_name = $variable_outputs_to_names{$var_name};

    print OUTPUT_SQL_DSC_FILE ",\n$var_output_name int";
  }
  print OUTPUT_SQL_DSC_FILE "\n);\n";
  print OUTPUT_SQL_DSC_FILE "load data local infile \"$output_file.dat\" into table $table_name;\n";

  for (my $row = 0; $row < $num_data_rows; $row++)
  {
    my $row_name = GetRowName($row);

    print OUTPUT_SQL_DATA_FILE "$row_name";

	 for (my $i = 0; $i < $num_outputs; $i++)
    {
      if ($output_results[$i][$row] == $TRUE)
      {
        print OUTPUT_SQL_DATA_FILE "1\t";
      }
		else
      {
        print OUTPUT_SQL_DATA_FILE "0\t";
      }
    }

    print OUTPUT_SQL_DATA_FILE "\n";
  }
}

#---------------------------------------------------------------------------
# main
#---------------------------------------------------------------------------
LoadDictionary;

LoadDataMatrix;
LoadRules;
ExecuteRules;

PrintOutputs;
PrintTSC;
PrintSQL;
