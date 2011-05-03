use strict;

require "$ENV{HOME}/develop/perl/lib/libfile.pl";
require "$ENV{HOME}/develop/perl/lib/liblist.pl";

sub attribDirectives
{
   my @directives = (
                        '#attributes'
                      , '#include'
                      , '#template'
                      , '#if'
                      , '#end'
                      , '#for'
                      , '#foreach'
                      , '#while'
                      , '#range'
                      , '#length'
                    );
   return \@directives;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub bindAttribs # ($text, \%attribs, $recursive,$max_depth,$case,$pwd,\%assigns)
{
  my ($text,$attribs,$recursive,$max_depth,$case,$pwd,$assigns) = @_;

  # Perform a change of variables if the user requested it.
  # if(defined($attribs) and defined($assigns))
  #   { $text = &assignAttribs($text,$attribs,$assigns,$case); }

  # Make a copy of the attributes so don't corrupt caller's hash.
  my %attribs = defined($attribs) ? %{$attribs} : {};
  my %assigns = defined($assigns) ? %{$assigns} : {};

  if(not(defined($pwd)) or length($pwd)==0) { $pwd = `pwd`; chomp($pwd); }

  my ($block,$block_pwd,$nesting,$type,@info) = ('',$pwd,0,'unknown',());

  my @lines = split("\n",$text);
  $text = '';
  while(@lines)
  {
    my $line = shift @lines;

    # Remove C++ style comments.
    $line =~ s/\/\/.+$//;

    $line = &assignAttribs($line,$attribs,\%assigns,$case);
    $line = &setAttribsRecursively($line,$attribs,$recursive,$max_depth,$case);
    $line = &expandSpecial($line,$attribs,$case);
    $line = &expandRanges($line,$attribs,$case);

    if(($line =~ /#include\s+"([^"]+)"(.*)$/i or
        $line =~ /#template\s+"([^"]+)"(.*)$/i))
    {
      my ($file,$line_assignments) = (&resolvePath($1,$pwd),$2);
      if($nesting == 0)
      {
        if(-f $file)
        { 
          $type      = 'include';
          @info      = (\%assigns,$line_assignments);
          $block     = &getFileText($file);
          $block_pwd = &getPathPrefix($file);
          $line      = '';
        }
        else
          { print STDERR "WARNING: included template file '$file' not found.\n"; } 
      }
    }

    # #attributes block
    elsif(($line =~ /^\s*#attributes\s*$/i or
           $line =~ /^\s*#assignments\s*$/i))
    {
      if($nesting == 0)
      { 
        $type  = 'attributes';
        @info  = ($attribs);
        $line  = '';
        $block = '';
      }
      $nesting++;
    }

    # Get attributes from a file.
    elsif(($line =~ /#attributes\s+"([^"]+)"/i or
           $line =~ /#assignments\s+"([^"]+)"/i))
    {
      my $file = &resolvePath($1,$pwd);
      if(-f $file)
      { 
        unshift(@lines,("#attributes",
                        split("\n",&getFileText($file)),
                        "#end"));
      }
      else
        { print STDERR "WARNING: included attribute file '$file' not found.\n"; } 
      $line = '';
    }

    # Extract if conditional
    elsif($line =~ /#if\s*\((.+)\)\s*$/i)
    {
      if($nesting == 0)
      {
        $type  = 'if';
        @info  = ($1);
        $line  = '';
        $block = '';
      }
      $nesting++;
    }

    # Extract for loop
    elsif($line =~ /#for\s*\(([^;]+);([^;]+);(.+)\)\s*$/i)
    {
      if($nesting == 0)
      {
        $type  = 'for';
        @info  = ($1,$2,$3);
        $line  = '';
        $block = '';
      }
      $nesting++;
    }

    # Extract foreach directive
    elsif($line =~ /#foreach\s+([^=]+)\s*=(\(.+\))\s*$/i)
    {
      if($nesting == 0)
      {
        $type  = 'foreach';
        @info  = ($1,$2);
        $line  = '';
        $block = '';
      }
      $nesting++;
    }

    # Pop out of the nest
    elsif($line =~ /^\s*#end/i)
    {
      $nesting -= $nesting==0 ? 0 : 1;
      $line = $nesting>0 ? '#end' : '';
    }

    if($nesting > 0)
    {
      $block .= length($line)>0 ? ($line . "\n") : '';
    }

    if($nesting == 0 and length($block)>0)
    {
      $block = &expandBlock($block,$type,$case,\@info);
      $block = &bindAttribs($block,\%attribs,$recursive,$max_depth,$case,$block_pwd,\%assigns);
      $block = &removeUnboundBlocks($block);

      %attribs   = defined($attribs) ? %{$attribs} : {};
      %assigns   = defined($assigns) ? %{$assigns} : {};

      $text .= length($block)>0 ? ($block . "\n") : '';
      $block = '';
      $type = '';
      $block_pwd = $pwd;
    }
    elsif($nesting==0 and length($line)>0)
    {
    #   $line = &assignAttribs($line,$attribs,$assigns,$case);
    #   $line = &setAttribsRecursively($line,$attribs,$recursive,$max_depth,$case);
      $text .= length($line)>0 ? ($line . "\n") : '';
    }
  }
  return $text;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub expandBlock # ($text,$type,$case,\@info)
{
  my ($text,$type,$case,$info) = @_;

  if($type eq 'include')
  {
    my($assigns,$line_assignments) = @{$info};
    my $assignments = &readAttribLines(join("\n",split(" ",$line_assignments)), 1);
    &replaceAttribs($assigns,$assignments);
  }
  elsif($type eq 'attributes')
  {
    my $attribs = $$info[0];
    my $assignments = &readAttribLines($text, 1);
    &addAttribs($attribs,$assignments);
    $text = '';
  }
  elsif($type eq 'if')
  {
    $text = &expandIf($text,$$info[0],$case);
  }
  elsif($type eq 'for')
  {
    $text = &expandForLoop($text,$$info[0],$$info[1],$$info[2],$case);
  }
  elsif($type eq 'foreach')
  {
    $text = &expandForEachLoop($text,$$info[0],$$info[1],$case);
  }

  return $text;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub setAttribsRecursively # ($text,$attribs,$recursive,$max_depth,$case)
{
  my ($text,$attribs,$recursive,$max_depth,$case) = @_;
  my $done = 0;
  my $depth = 0;
  while(not($done))
  {
    $depth++;
    my $num_replacements = 0;
    my $replaces = 0;

    # Bind the user's attributes
    ($text,$replaces) = &setAttribs($text,$attribs,$case);
    $num_replacements += $replaces;

    if(not($recursive) or ($num_replacements == 0))
      { $done = 1; }
    elsif($text =~ /\$\([^)]+\)/ and ($max_depth==-1 or $depth < $max_depth))
      { $done = 0; }
    else
      { $done = 1; }
  }
  return $text;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub assignAttribs # ($text,$attribs,$assignments,$case)
{
  my ($text,$attribs,$assignments,$case) = @_;
  if(defined($assignments))
  {
    foreach my $attrib (keys(%{$assignments}))
    {
      my $val = $$assignments{$attrib};

      # If this is a change of variable names:
      if($val =~ /\$\(([^\)]+)\)/)
      {
        my $alias = $1;
        if($alias ne $attrib)
          { delete($$attribs{$attrib}); }
        $val    = '$(' . $alias  . ')';
        if($case)
          { $text =~ s/\$\($attrib\)/$val/ge; }
        else
          { $text =~ s/\$\($attrib\)/$val/gie; }
      }
      else
      {
        if(&isDefinedValue($val))
          { $$attribs{$attrib} = $val; }
        else
          { delete($$attribs{$attrib}); }
      }
    }
  }
  return $text;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub postProcessTemplate # ($text)
{
  my $text = shift;
  my $return = "\n";

  $text = &processValues($text);

  # $text =~ s/#[^\n]+$return/$return/ge;
  my @keywords = @{&attribDirectives()};
  my $done = 0;
  while(not($done))
  {
     $done = 1;
     foreach my $keyword (@keywords)
     {
        my $replacements = s/$keyword[^\n]+$return/$return/ge;

        if($replacements > 0)
        {
           $done = 0;
        }
     }
  }
  while($text =~ s/$return\s*$return/$return/ge) {}
  return $text;
}

##------------------------------------------------------------------------
## removeUnboundBlocks
##
## Searches for #(...)# blocks and removes them if they contain any
## unbound variables.  If no unbound variables are in the block, the
## block is retained (w/o the pound-signs and curly braces).
##------------------------------------------------------------------------
sub removeUnboundBlocks # ($text)
{
  my $text = shift;

  if($text =~ /#\[/)
  {
    my @tokens = split(/ /,$text);
    $text = '';

    my $nesting = 0;
    my $block = '';
    my $i=0;
    foreach my $token (@tokens)
    {
      my $append = 1;
      if($token =~ /^\s*#\[/)
      {
        $nesting++;
        $token =~ s/^(\s*)#\[/\1/;

        if(not($token =~ /\]#\s*$/))
        {
          $block .= length($block)>0 ? (' ' . $token) : $token;
          $append = 0;
        }
      }

      if($token =~ /\]#\s*$/)
      {
        $nesting--;

        if($nesting == 0)
        {
          $token =~ s/\]#(\s*)$/\1/;
          $block .= length($block)>0 ? (' ' . $token) : $token;
          $block = &removeUnboundBlocks($block);

          if(not(&hasUnboundAttributes($block)))
          {
            $text .= length($text)>0 ? (' ' . $block) : $block;
          }
          elsif($block =~ /\n/)
          {
            $text .= "\n";
          }

          $block = '';
        }
        else
        {
          $text .= length($text)>0 ? (' ' . $token) : $token;
        }
      }
      elsif($nesting > 0 and $append)
      {
        $block .= length($block)>0 ? (' ' . $token) : $token;
      }
      elsif($append)
      {
        $text .= length($text)>0 ? (' ' . $token) : $token;
      }
    }
  }
  return $text;
}

##------------------------------------------------------------------------
## If the condition contains unresolved variables evaluates to false.
## Otherwise the condition is evaluated.  If evaluates to true the
## block is returned, otherwise it isn't.
##------------------------------------------------------------------------
sub expandIf # ($block,$condition,$case)
{
  my ($block,$condition,$case) = @_;
  my $expanded = undef;

  # Check for unresolved variables in the conditional.
  if(not($condition =~ /\$\([^\)]+\)/))
  {
    if($condition =~ /^\s*#exists\s*\(([^\)]*)\)\s*$/)
    {
      if(length($1)>0)
        { $expanded = $block; }
    }
    elsif(eval($condition))
      { $expanded = $block; }
  }

  return $expanded;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub expandForLoop # ($block,$init,$condition,$update,$case)
{
  my ($block,$init,$condition,$update,$case) = @_;
  my $expanded = '';

  my $attrib = '';
  if($init =~ /^(\w+)/)
  {
    $attrib = $1;

    my $i;
    if($case)
    {
      $init      =~ s/\b$attrib\b/\$i/g;
      $condition =~ s/\b$attrib\b/\$i/g;
      $update    =~ s/\b$attrib\b/\$i/g;
    }
    else
    {
      $init      =~ s/\b$attrib\b/\$i/ig;
      $condition =~ s/\b$attrib\b/\$i/ig;
      $update    =~ s/\b$attrib\b/\$i/ig;
    }

    for(eval($init); eval($condition); eval($update))
    {
      my $substituted = $block;
      $substituted =~ s/\$\($attrib\)/$i/ge;
      $expanded .= $substituted;
    }
  }
  return $expanded;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub expandForEachLoop # ($block,$variable_list,$values_list,$case)
{
  my ($block,$variable_list,$value_lists,$case) = @_;
  my $expanded = '';

  my @vars = split(':',$variable_list);
  my @value_lists = split(':',$value_lists);
  my @substituted;
  for(my $i=0; $i<=$#vars; $i++)
  {
    if($value_lists[$i] =~ /^\s*\((.+)\)/)
    {
      my @vals = split(',',$1);
      for(my $j=0; $j<=$#vals; $j++)
      { 
        $substituted[$j] = defined($substituted[$j]) ? $substituted[$j] : $block;
        $substituted[$j] =~ s/\$\($vars[$i]\)/$vals[$j]/ge;
      }
    }
  }

  foreach $block (@substituted)
  {
    $expanded .= $block;
  }

  # my @variables = split(':',$variable_list);
  # my @value_lists = split(',',$value_lists);
  # foreach my $value_list (@value_lists)
  # {
  #   my $substituted = $block;
  #   my @values = split(':',$value_list);
  #   for(my $i=0; $i<=$#variables; $i++)
  #   {
  #     my $value = $values[$i];
  #     my $variable = $variables[$i];
  #     $substituted =~ s/\$\($variable\)/$value/ge;
  #   }
  #   $expanded .= $substituted;
  # }
  return $expanded;
}

sub getParams # ($text)
{
  my ($text) = @_;
  my @tokens = split('',$text);
  
  # find opening paren
  my $nesting = 0;
  my $params = '';
  my $found_params = 0;
  my $before = '';
  my $after  = '';
  while(@tokens)
  {
    my $token = shift @tokens;
    if($token eq '(')
    {
      $nesting++;
    }
    elsif($token eq ')')
    {
      $nesting -= $nesting > 0 ? 1 : 0;
    }

    if($nesting > 0 and $found_params)
    {
      $params .= $token;
    }
    elsif($nesting == 0 and $found_params)
    {
      $after = join('',@tokens);
      return ($params,$before,$after);
    }
    elsif($nesting > 0 and not($found_params))
    {
      $found_params = 1;
      $before .= $token;
    }
    else
    {
      $before .= $token;
    }
  }
  return $params;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub expandSpecial # ($text,\%attribs,$case)
{
  my ($text,$attribs,$case) = @_;
  my $done = 0;
  while(not($done))
  {
    if($text =~ /#length\s*(\(.+)\)/i)
    {
      my ($list,$before,$after) = &getParams($1);
      $list = &setAttribsRecursively($list,$attribs,1,-1,$case);
      my $length = scalar(split(',',$list));
      my $replace = $length . $after;
      $text =~ s/#length\s*\(.+\)/$replace\)/i;
    }
    else
    {
      $done = 1;
    }
  }
  return $text;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub expandRanges # ($text,\%attribs,$case)
{
  my ($text,$attribs,$case) = @_;

  my %unbound = &getUnboundAttributes($text,1);
  my $done = 0;
  while(not($done))
  {
    my ($orig,$beg,$end,$inc,$delim) = (undef,1,undef,1,',');

    if($text =~ /(#range\s*\(([^,]+),([^,]+),([^,]+),([^\)]+)\))/i)
    {
      ($orig,$beg,$end,$inc,$delim) = ($1,$2,$3,$4,$5);
      $delim = ($delim =~ /^\s*\$\(/) ? ($delim . ')') : $delim;
    }
    # No increment supplied
    elsif($text =~ /#range\s*\(([^,]+),([^,]+),([^\)]+)\)/i)
    {
      ($beg,$end,$delim) = ($1,$2,$3);
      $delim = ($delim =~ /^\s*\$\(/) ? ($delim . ')') : $delim;
    }
    # No delimiter supplied (default to comma)
    elsif($text =~ /#range\s*\(([^,]+),([^\)]+)\)/i)
    {
      ($beg,$end) = ($1,$2);
      $end = ($end =~ /^\s*\$\(/) ? ($end . ')') : $end;
    }
    elsif($text =~ /#range\s*\(([^\)]+)\)/i)
    {
      $end = $1;
      $end = ($end =~ /^\s*\$\(/) ? ($end . ')') : $end;
    }
    if(defined($beg) and defined($end))
    {
      my $range = '';
      if(exists($unbound{$beg}) or
         exists($unbound{$end}) or
         exists($unbound{$inc}) or
         exists($unbound{$delim}))
      {
        $range = '';
      }
      else
      {
        for(my $i=$beg; $i<=$end; $i+=$inc)
        {
          $range .= (length($range)==0) ? "$i" : ($delim . "$i");
        }
      }
      $text =~ s/#range\s*\([^\)]+\)/$range/ie;
    }
    else
    {
      $done = 1;
    }
  }
  return $text;
}

##------------------------------------------------------------------------
## Even if an attribute exists in the target, still overwrites it.
##------------------------------------------------------------------------
sub replaceAttribs # (\%to, \%from)
{
  my $to   = shift;
  my $from = shift;

  foreach my $attrib (keys(%{$from}))
  { 
    my $val = $$from{$attrib};
    $$to{$attrib} = $val;
  }
  
  return $to;
}

##------------------------------------------------------------------------
## Only adds new attributes to the target hash.  Old ones are *not*
## overwritten.
##------------------------------------------------------------------------
sub addAttribs # (\%to, \%from)
{
  my $to   = shift;
  my $from = shift;

  foreach my $attrib (keys(%{$from}))
  { 
    if(not(exists($$to{$attrib})))
    {
      my $val = $$from{$attrib};
      $$to{$attrib} = $val;
    }
  }

  return $to;
}

##------------------------------------------------------------------------
## 
##------------------------------------------------------------------------
sub printAttributes # ($fout, \%attrib2val)
{
  my $fout       = shift;
  my $attrib2val = shift;

  foreach my $attrib (keys(%{$attrib2val}))
  {
    my $val = $$attrib2val{$attrib};
    print $fout "'$attrib' -> '$val'\n";
  }
}

##------------------------------------------------------------------------
## 
##------------------------------------------------------------------------
sub getUnboundAttributes # ($text,$keep_dollar)
{
  my ($text,$keep_dollar) = @_;
  $keep_dollar = defined($keep_dollar) ? $keep_dollar : 0;
  my $return = "\n";
  my %unbounded;
  while($text =~ s/\$\(([^\)]+)\)//)
  {
    my $attrib = $keep_dollar ? ('$(' . $1 . ')') : $1;
    $unbounded{$attrib}=1;
  }
  return %unbounded;
}

sub hasUnboundAttributes # ($text)
{
  my $text = shift;
  return ($text =~ /\$\([^\)]+\)/);
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub processValues # ($text)
{
  my ($text) = @_;

  while($text =~ /#system\s*\((.+)\)/i)
  {
    my $result = `$1`;
    chop($result);
    # $text =~ s/#system\s*\(.+\)/$result/i;
    $text =~ s/#system\s*\([^\)]+\)/$result/ie;
  }
  return $text;
}

##------------------------------------------------------------------------
## \%a2v readAttibLines($text, $int read_blocks=0)
##------------------------------------------------------------------------
sub readAttribLines
{
  my ($text, $read_blocks) = @_;
  $read_blocks = defined($read_blocks) ? $read_blocks : 0;

  my @lines = split("\n",$text);

  my %attrib2val;

  my @lines = split("\n",$text);

  my $in_block = 0;
  foreach my $line (@lines)
  {
    # Remove comments
    # $line =~ s/^\s*#.+$//;

    # If the line contains 'attribute = value' grab it:
    if((not($read_blocks) or $in_block) and $line =~ /([^=]+)\s*=\s*(.+)/)
    {
      my ($attrib,$val) = ($1,$2);
      $attrib =~ s/^\s+//;
      $attrib =~ s/\s+$//;
      $attrib2val{$attrib} = $val;
    }

    if($line =~ /^\s#attributes/)
    {
       $in_block = 1;
    }

    elsif($in_block and $line =~ /^\s#end/)
    {
       $in_block = 0;
    }
  }
  return \%attrib2val;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub readAttribText # ($text)
{
  my $text = @_;
  my @lines = split("\n",$text);

  my %attrib2val;

  my @lines = split("\n",$text);
  foreach my $line (@lines)
  {
    # Remove comments
    # $line =~ s/#.+$//;

    my $done=0;
    while(not($done))
    {
      if($line =~ /((\S+)\s*=\s*"([^"]+)")/ or
         $line =~ /((\S+)\s*=\s*(\S+))/)
      {
        my ($match,$attrib,$val) = ($1,$2,$3);
        $line =~ s/\S+\s*=\s*"[^"]+"//;
      }
      else
      {
        $done = 1;
      }
    }
  }
  return \%attrib2val;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub setAttribs # ($text,\%attrib2val,$case)
{
  my ($text,$attrib2val,$case) = @_;
  my $num_replacements = 0;
  foreach my $attrib (keys(%{$attrib2val}))
  {
    my $val = $$attrib2val{$attrib};
    if(&isDefinedValue($val))
    {
      $num_replacements += $case ? ($text =~ s/\$\($attrib\)/$val/ge) :
                                             ($text =~ s/\$\($attrib\)/$val/ige);
    }
  }
  return ($text,$num_replacements);
}

##------------------------------------------------------------------------
## Returns true if the value equals #undef
##------------------------------------------------------------------------
sub isDefinedValue # ($value)
{
  my $value = shift;
  if(not(defined($value)) or $value =~ /\s*#undef/)
  {
    return 0;
  }
  return 1;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub upperCaseAttribs # (\%attribs)
{
  my $attribs = shift;
  foreach my $attrib (keys(%{$attribs}))
  {
    my $val = $$attribs{$attrib};
    delete($$attribs{$attrib});
    $attrib =~ tr/a-z/A-Z/;
    $$attribs{$attrib} = $val;
  }
}


##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub setAllAttribs # ($text,$value)
{
  my ($text,$value) = @_;
  my %unbound_attributes = &getUnboundAttributes($text);
  foreach my $attrib (keys(%unbound_attributes))
  {
    $text =~ s/\$\($attrib\)/$value/g;
  }
  return $text;
}

##------------------------------------------------------------------------
## \%attrib attribRead ($string file, $string delim="\t",
##                      $int col1=0, $int col2=1, 
##                      $int bidirectional=0, $int multi=0,
##                      \%attrib aliases=undef)
##
## multi - store multiple values for each attribute? If 1 stores sets for
##         each, if 2 stores lists for each.
##
##------------------------------------------------------------------------
sub attribRead
{
   my ($file, $delim, $col1, $col2, $bidirectional, $multi, $aliases) = @_;
   $delim         = not(defined($delim)) ? "\t" : $delim;
   $col1          = not(defined($col1))   ? 0 : $col1;
   $col2          = not(defined($col2))   ? 1 : $col2;
   $bidirectional = not(defined($bidirectional)) ? 0 : $bidirectional;
   $multi         = not(defined($multi)) ?  0 : $multi;

   my %map;
   if(open(FILE, $file))
   {
      while(<FILE>)
      {
         my @tuple = split($delim);
         chomp($tuple[$#tuple]);

         my $attribute = $tuple[$col1];
         my $value     = $tuple[$col2];

         if(defined($aliases))
         {
            if(exists($$aliases{$attribute}))
            {
               $attribute = $$aliases{$attribute};
            }
            else
            {
               $attribute = undef;
            }
         }

         if(defined($attribute) and defined($value))
         {
            if($multi)
            {
               if(not(exists($map{$attribute})))
               {
                  my @list;
                  my %set;
                  $map{$attribute} = $multi == 2 ? \@list : \%set;
               }
               if($multi == 2)
               {
                  push(@{$map{$attribute}}, $value);
               }
               else
               {
                  my $set = $map{$attribute};
                  $$set{$value} = 1;
               }

               if($bidirectional)
               {
                  if(not(exists($map{$value})))
                  {
                     my @list;
                     my %set;
                     $map{$value} = $multi == 2 ? \@list : \%set;
                  }
                  if($multi == 2)
                  {
                     push(@{$map{$value}}, $attribute);
                  }
                  else
                  {
                     my $set = $map{$value};
                     $$set{$attribute} = 1;
                  }
               }
            }
            else
            {
               $map{$attribute} = $value;
               if($bidirectional)
               {
                  $map{$value} = $attribute;
               }
            }
         }
      }
      close(FILE);
   }
   return \%map;
}

##---------------------------------------------------------------------------##
## void attribPrint (\%attrib, \*FILE fp=\*STDOUT)
##---------------------------------------------------------------------------##
sub attribPrint
{
   my ($attrib, $fp) = @_;
   $fp = not(defined($fp)) ? \*STDOUT : $fp;

   my $i = 0;
   foreach my $element (keys(%{$attrib}))
   {
      $i++;
      my $value = $$attrib{$element};
      print $fp "$element\t$value\n";
   }
}

##------------------------------------------------------------------------
## convertAttribs2Values
##------------------------------------------------------------------------
sub convertAttribs2Values # (\%attribs2vals, \@attribs);
{
   my ($attribs2vals, $attribs);
   my @values;

   foreach my $attrib (@{$attribs})
   {
      my $value = $$attribs2vals{$attrib};
      push(@values, $value);
   }
   return \@values;
}

# Depracated stuff is below:

# Get attribute-value attribiations from a file.  Returns an attribiative
# array mapping attribute names to their values as defined in the file.
# Default delimiter between attributes and values is <tab>, but this can
# be passed in as the second argument.
sub getAVArray
{
  my $file = shift;
  my $delim = "\t";
  if($#_>=0)
  {
    $delim = shift;
  }

  my $attribute;
  my $value;
  my %AttribValue;
  my $match;
  my $env;
  my $env_val;
  my $before;
  my $after;

  if(open(FILE,$file))
  {
    while(<FILE>)
    {
      chop;

      # Remove comments
      # s/\s*#.*$//;

      if(/\S/)
      {
        ($attribute,$value) = split($delim);

        # If the value has any environment variables in it, look them
        # up and replace them before storing:
        if($value =~ /^([^\$]*)(\$[{(]*[a-zA-Z0-9]+)(.*)$/)
        {
          $match = $2;
          $before = $1;
          $after = $3;
          $before =~ s/[{(]$//;
          $after =~ s/^[})]//;
          $env = $match;
          $env =~ s/[\${}]//g;
          if(exists($ENV{$env}))
          {
            $env_val = $ENV{$env};
            $value = $before . $env_val . $after;
          }
        }

        $AttribValue{$attribute} = $value;

      }
    }
    close(FILE);
  }
  return %AttribValue;
}

##-----------------------------------------------------------------------------
## void attribAdd(\%attrib a, \%attrib b)
##
## Adds the attributes in b to those in a.
##-----------------------------------------------------------------------------
sub attribAdd
{
   my ($a, $b) = @_;

   foreach my $attribute (%{$b})
   {
      my $value = $$b{$attribute};
      $$a{$attribute} = $value;
   }
}

##-----------------------------------------------------------------------------
## \%attrib = attribInvert(\%av, $int multi=0)
##-----------------------------------------------------------------------------
sub attribInvert
{
   my ($av, $multi) = @_;
   $multi = defined($multi) ? $multi : 0;

   my %inverted;
   foreach my $attrib (keys(%{$av}))
   {
      my $value = $$av{$attrib};

      if(not(exists($inverted{$value})))
      {
         $inverted{$value} = $multi ? [] : undef;
      }

      if($multi)
      {
         push(@{$inverted{$value}}, $attrib);
      }
      else
      {
         $inverted{$value} = $attrib;
      }
   }
   return \%inverted;
}

##-----------------------------------------------------------------------------
## \@list = attribGetAttribSortByNumericValue(\%attrib)
##-----------------------------------------------------------------------------
sub attribGetAttribSortByNumericValue
{
   my ($av) = @_;

   my @pairs;
   foreach my $attrib (keys(%{$av}))
   {
      push(@pairs, [$$av{$attrib}, $attrib]);
   }
   my @sorted_pairs = sort by_first_numeric @pairs;

   my @sorted_attribs;
   foreach my $pair (@pairs)
   {
      push(@sorted_attribs, $$pair[1]);
   }
   return \@sorted_attribs;
}

##-----------------------------------------------------------------------------
## $string attribGetAttribWithMinNumericValue (\%attrib)
##-----------------------------------------------------------------------------
sub attribGetAttribWithMinNumericValue
{
   my ($av) = @_;

   my $min_value  = undef;
   my $min_attrib = undef;
   foreach my $attrib (keys(%{$av}))
   {
      my $value = $$av{$attrib};

      if(not(defined($min_value)) or $value < $min_value)
      {
         $min_value  = $value;
         $min_attrib = $attrib;
      }
   }
   return $min_attrib;
}

# \%attrib attribPermute (\%attrib, $int num=scalar(keys(%attrib))), $replace=0)
sub attribPermute
{
   my ($av, $num, $replace) = @_;

   my @orig_attribs = keys(%{$av});

   my $num_attribs  = scalar(@orig_attribs);

   my $perm_attribs = &listPermute(\@orig_attribs, $num, $replace);

   my %new_attribs;

   for(my $i = 0; $i < scalar(@{$perm_attribs}); $i++)
   {
      my $attrib = $$perm_attribs[$i];
      my $value  = $$av{ $orig_attribs[$i % $num_attribs] };

      $new_attribs{$attrib} = $value;
   }
   return \%new_attribs;
}


## $int by_first_numeric ($a, $b)
##-----------------------------------------------------------------------------
sub by_first_numeric
{
   return $$a[0] <=> $$b[0];
}


1

