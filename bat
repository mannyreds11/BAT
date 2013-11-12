# bat (batch file compiler)
# Author: Manuel Rojas

#!/usr/bin/perl --

use strict;
use Getopt::Long;


my %OPCODE; # opcodes $OPCODE{'LDI'} is '12'
my %OPNUMBER;  # $OPNUMBER{'12'} is "LDI"
my %OPSTRING; # eg $OPSTRING{'12'} is Perl code for operation 12

my %PROGRAM;  # the program to execute

my $opnumber;
my $operand;
my $STOPRUN = 'false';


# read the OpDefs file to determine operators and their definitions
sub ReadOpDefs {
  my $OpFile=$_[0];
  open(OPDEFS,"<".$OpFile) || die "can't open OpDefs file $OpFile\n";

  my $line;
  my $opnumber;
  my $op;
  while ($line = <OPDEFS> ) {
    chomp($line);
    if (
	($line !~ m/^#/ )
	 &&
	($line !~ m/^[ ]*$/)

	) { # it is not a comment or a blank line
	  if ($line =~ /^	/) { # starts with a tab
	    $OPSTRING{$opnumber} = $OPSTRING{$opnumber} . $line;
	  } else {
	    ($op,$opnumber) = split(':',$line);
	    $OPCODE{$op} = $opnumber;
	    $OPNUMBER{$opnumber} = $op;
	    $OPSTRING{$opnumber} = "";
	  }

      }
	 
  }

  close(OPDEFS);
}




## this is to initialize the memory and registers of the virtual machine

my %mem;  # the memory cells for the virtual machine


## load a program from a file
sub loadprog {
  my $progfile = $_[0]; # load from this file


  # now load it -- assume the memory locations are all present and in
  # correct order
  
  open (PROGFILE,"<" . $progfile) || die "can't open program file $progfile\n";
  my $i;
  my $j;
  my $subscript;
  my $line;
  
  foreach $i ('0' .. '9') {
    foreach $j ('0' .. '9') {
      $subscript = $i.$j;
      $line = <PROGFILE>;
      chomp($line);
      $mem{$subscript} = $line;

    }
  }  close(PROGFILE);
  
}




#############################################################
# here is the assembler

sub batas{
  my $inputfile = $_[0];

my $outputfile = $inputfile.".bat";

my $linecounter = 0;

my %LABELS;

my @PROGRAM;
my $line;
open(PROG,"<" . $inputfile . ".B") || die "can't open program $inputfile.B\n" ;

while ($line = <PROG> ) {
  chomp($line);
  if ($line =~ /^;/) { # ignore comment lines
  } else {
    # tear off comments
    $line =~ s/;.*$//;
    if ($line =~ /^[a-zA-Z][a-zA-Z0-9]*/) { # this is a label, so store it
      my ($label, $opcode, $rest) = split(' ',$line);
      # don't forget to remove the original label

      $line = $OPCODE{$opcode} . " " . $rest;
      $LABELS{$label} = $linecounter;
      # labels need to be left padded to 2 places
      while (length($LABELS{$label}) < 2) {
	$LABELS{$label} = "0" . $LABELS{$label};
      }
      
    } else { # not a label line
      my ( $opcode, $rest) = split(' ',$line);
      $line = $OPCODE{$opcode} . " " . $rest;
    }
    
    $PROGRAM[$linecounter] = $line;
    #  printf("%s\n",$line);
    
    $linecounter++;
  }
}

close(PROG);

# here I know what the labels are, and I can fill them in

my $i = 0;
my $j;

while ($i < @PROGRAM) {
  # run through each label, and substitute
  foreach $j (keys %LABELS) {
    $PROGRAM[$i] =~ s/$j/$LABELS{$j}/g;
    $PROGRAM[$i] =~ s/$j /$LABELS{$j}/g;
  }

  # and compress the line
  $PROGRAM[$i] =~ s/[ \t]//g;
  $i++;
  
}

## output section

open(OUTFILE,">".$outputfile) || die "can't open output file $outputfile\n";

$i = 0;
my $j;
while ($i < @PROGRAM ) {
  # pad trailing zeros
  while (length($PROGRAM[$i]) < 4) {
    $PROGRAM[$i] = $PROGRAM[$i] . "0";
  }
  printf(OUTFILE "%s\n",$PROGRAM[$i]);
  $i++;
}

# finally, fill the rest of the cells with NOP

while ($i < 100) {
  printf(OUTFILE "0000\n");
  $i++;
}

close(OUTFILE);

}



#############################################################

my $operationsfile = "BatOpDefs";
my $showuseage = 0;

GetOptions(
	   "OpsFile=s" =>\$operationsfile,
	   "help" =>\$showuseage
);

if ($showuseage == 1) {
  printf("batas [--OpsFile OpDefs] file.B\n");
  printf("Options:\n");
  printf("\t--OpsFile  filename  -  read Operations Defs from filename\n");
  printf("\t--help               -  this message\n");
  exit(0);
}




my $inputfile = $ARGV[0];
# this file should have an ".B" extension
my ($basename,$ext)  = split('\.',$inputfile);

if ($ext != 'B') {
  printf("input file %s should have '*.B' name instead\n", $inputfile);
  exit(0);
}

ReadOpDefs($operationsfile);

loadprog($inputfile);
batas($basename);




exit(0);




