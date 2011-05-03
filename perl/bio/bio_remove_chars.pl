#! /usr/bin/perl

#---------------------------------------------------------------------
# input:
#    ARGV[0] - file name to remove characters from
#    ARGV[1] - a string of characters to remove from the file
# output:
#    We remove the characters and write the results onto the SAME file
#---------------------------------------------------------------------

$len = length($ARGV[1]);

$file_name = $ARGV[0];

for ($i = 0; $i < $len; $i++)
{
  $char = substr($ARGV[1], $i, 1);

  if ($char eq ".") { system("sed 's/\.//g' $file_name > x"); }
  elsif ($char eq "*") { system("sed 's/\*//g' $file_name > x"); }
  elsif ($char eq "[") { system("sed 's/\[//g' $file_name > x"); }
  elsif ($char eq "]") { system("sed 's/\]//g' $file_name > x"); }
  elsif ($char eq "^") { system("sed 's/\^//g' $file_name > x"); }
  elsif ($char eq "\$") { system("sed 's/[\$]//g' $file_name > x"); }
  elsif ($char eq "\\") { system("sed 's/\\//g' $file_name > x"); }
  else { system("sed 's/$char//g' $file_name > x"); }
  
  system("mv x $file_name");
}
