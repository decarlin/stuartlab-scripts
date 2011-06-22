#!/usr/bin/perl

my $json = <<EOF;
[{"_metadata":{"type":"info","action":"gif","filename":"heatmap.gif","width":"400","height":"400"}}]
[{"_metadata":{"type":"rows"},"_elements":["ATP5E","ATP5C1","TRAK1"]}]
[{"_metadata":{"name":"kinesin-associated mitochondrial adaptor activity","id":"154128","type":"set"},"_name":"human:GO:0019895","_delim":"^","_active":1,"_elements":{"TRAK1":""}}]
[{"_metadata":{"name":"mitochondrial proton-transporting ATP synthase complex, catalytic core F(1)","id":"142716","type":"set"},"_name":"human:GO:0000275","_delim":"^","_active":1,"_elements":{"ATP5E":"","ATP5C1":"","ATP5B":"","ATP5D":""}}]
EOF

#my $json = <<EOF;
#[{"_metadata":{"type":"info","action":"base64gif","filename":"heatmap.txt","width":"400","height":"400"}}]
#[{"_metadata":{"type":"rows"},"_elements":["ATP5E","ATP5C1","TRAK1"]}]
#[{"_metadata":{"name":"kinesin-associated mitochondrial adaptor activity","id":"154128","type":"set"},"_name":"human:GO:0019895","_delim":"^","_active":1,"_elements":{"TRAK1":""}}]
#[{"_metadata":{"name":"mitochondrial proton-transporting ATP synthase complex, catalytic core F(1)","id":"142716","type":"set"},"_name":"human:GO:0000275","_delim":"^","_active":1,"_elements":{"ATP5E":"","ATP5C1":"","ATP5B":"","ATP5D":""}}]
#EOF
#
my $command = "java -jar heatmap.jar 1 >> heatmap_errfile.txt 2>&1";
open COMMAND, "|-", "$command";
print COMMAND $json;
close COMMAND;
