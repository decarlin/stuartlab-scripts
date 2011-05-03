#!/usr/bin/perl

sub get_time
{
  my $format = $_[0]; # can be empty

  @days = ("Sunday","Monday","Tuesday","Wednesday","Thursday", "Friday","Saturday");
  @shortdays = ("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
  @months = ("January","February","March","April","May","June","July","August","September","October","November","December");
  @shortmonths = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");

  ($sec,$min,$hr,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $longyr = $year + 1900;
  $fixmo = $mon + 1;
  if ($isdst == 1)
  {
	 $tz = "CDT";
  }
  else
  {
	 $tz = "CST";
  }

  # in case we only want the 2-digit year, like 00, we have to do it the hard way...
  $yr2 = substr($longyr,2,2);

  my $res;

  if (length($format) == 0 || $format eq "fulldate")
  {
	 # Wed, 03 Feb 99 12:23:55 CST
	 $res = sprintf("%3s, %02d %3s %02d %02d:%02d:%02d $tz\n",$shortdays[$wday], $mday, $shortmonths[$mon], $yr2, $hr, $min, $sec);
  }
  elsif ($format eq "date")
  {
	 # 02/03/1999
	 $res = sprintf("%02d/%02d/%04d\n", $fixmo, $mday, $longyr);
  }
  elsif ($format eq "fulldatelong")
  {
	 # Wed, 03 Oct 1999 12:23:55 CST
	 $res = sprintf("%3s, %02d %3s %04d %02d:%02d:%02d $tz\n",$shortdays[$wday], $mday, $shortmonths[$mon], $longyr, $hr, $min, $sec);
  }
  elsif ($format eq "longformat")
  {
	 # Wednesday, 03-Feb-99 08:49:37 CST
	 $res = sprintf("$days[$wday], %02d-%3s-%02d %02d:%02d:%02d $tz\n", $mday, $months[$mon], $yr2, $hr, $min, $sec);
  }
  elsif ($format eq "time")
  {
	 # Wed Feb  3 08:49:37 1999   
	 $res = sprintf("%3s %3s %2d %02d:%02d:%02d %04d\n", $shortdays[$wday], $shortmonths[$mon], $mday, $hr, $min, $sec, $longyr);
  }
  elsif ($format eq "date")
  {
	 # 03/Feb/1999 11:51:57 CST
	 $res = sprintf("%02d/%3s/%04d %02d:%02d:%02d $tz\n", $mday, $shortmonths[$mon], $longyr, $hr, $min, $sec);
  }
  elsif ($format eq "dummy")
  {
	 # Wednesday, February 2, 1999
	 $res = sprintf("$days[$wday], $months[$mon] $mday, $longyr\n");
  }

  return $res;
}

1
