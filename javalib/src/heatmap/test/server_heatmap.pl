#!/usr/bin/perl

use IO::Socket;

my $json = <<EOF;
[{"_metadata":{"type":"info","action":"base64gif","filename":"heatmap.txt","width":"400","height":"400"}}]
[{"_metadata":{"type":"rows"},"_elements":["ATP5E","ATP5C1","TRAK1"]}]
[{"_metadata":{"name":"kinesin-associated mitochondrial adaptor activity","id":"154128","type":"set"},"_name":"human:GO:0019895","_delim":"^","_active":1,"_elements":{"TRAK1":""}}]
[{"_metadata":{"name":"mitochondrial proton-transporting ATP synthase complex, catalytic core F(1)","id":"142716","type":"set"},"_name":"human:GO:0000275","_delim":"^","_active":1,"_elements":{"ATP5E":"","ATP5C1":"","ATP5B":"","ATP5D":""}}]
EOF

my $sock	= new IO::Socket::INET( 
  
        PeerAddr	=> "localhost",
  
        PeerPort	=> 7777, 
  
        Proto	=> 'tcp') || die "Error creating socket: $! 
"; 
  

  
print $sock $json;
print $sock "EOF\n";
  
while($line = <$sock>) { 
  
  print $line; 
  
} 
