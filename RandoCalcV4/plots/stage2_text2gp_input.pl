#!/usr/bin/perl

use strict;
use warnings;

# use DateTime::Format::Strptime;
use Time::Piece;

my @cdist = (      0,     119,     203,       292,      353,      378);
my @ctime = ( 0.0000, 7.96667, 13.48333, 19.43333, 23.51667, 25.25000);


my @cdist2 = (       435,      482,      514,      604,      697);
my @ctime2 = (  29.06667, 32.16667, 34.30000, 40.31667, 48.06667);
 
my @cdist3 = (      731,     782,      842,      867,       928);
my @ctime3 = (  50.78333, 55.1666, 59.81667, 61.75000, 66.41667);
 
 
# Include an over-run entry at 12kph
my @cdist4 = (       1017,     1099,     1176,     1219,   1279);
my @ctime4 = (   73.35000, 80.11667, 86.53333, 90.00000, 95.000);
 
push(@cdist, @cdist2);
push(@cdist, @cdist3);
push(@cdist, @cdist4);

push(@ctime, @ctime2);
push(@ctime, @ctime3);
push(@ctime, @ctime4);
 


# PBP Times.
my $brest = 613.0;
my $kph_1 = $brest / 40.333333;
my $kph_2 = ( 1230.0 - $brest) / ( 90 - 40.33333333 );


sub distance_to_hours {
  my $km =  $_[0];  

  my $index = 0; 
  
  while ( $km > $cdist[$index+1] ) {
    $index += 1;
    
    # print "%d\n" , $index;
     
  }

  my $basehours = $ctime[$index];
  $km = $km - $cdist[$index];
  
  my $km_delta = $cdist[$index+1] - $cdist[$index];
  my $hr_delta = $ctime[$index+1] - $ctime[$index];
  my $kph      = $km_delta / $hr_delta;
  # printf "%f %f %f kph = %f | ", $km, $km_delta, $hr_delta, $kph; 

  my $leftovers = $km / $kph;

  my $total = $basehours + $leftovers;
  if ($total > 90 ) {
    $total = 90.0
  }

  return $total;
  
}



#
#sub distance_to_hours {
#  my $km =  $_[0];  
#  my $expected;

#  if ( $km < $brest ) {
#    $expected = $km / $kph_1;
#  } else {
#    $expected = 40.33333 + ( $km - $brest ) / $kph_2;
#  }
#  return $expected;
#}


# Sample
#my $time = Time::Piece->strptime(
#      "2023-08-20T16:35:00Z", "%FT%TZ");

# my $parser = DateTime::Format::Strptime->new(
# pattern => '%B %d, %Y %I:%M %p %Z',
# on_error => 'croak',
# );


print "# Hours km close time\n";

my $basetime = -1;  # Detect things...

while(<>) {
  my @parts = split(' ', $_);
  my $ts = Time::Piece->strptime($parts[0], "%FT%TZ");
  if ( $basetime == -1 ) { $basetime = $ts; } 
  my $offset = $ts->epoch - $basetime->epoch;
  $offset = $offset / 3600.0; # Make it hours.

  # Scale the distance to true PBP.  Otherwise you get goofiness at the end.
  # my $scaled = $parts[1] * 1219000.0 / 1230031.2; # rbs
  my $scaled = $parts[1] * 1219000.0 / 1237969.7; # bkf
  my $km = $scaled / 1000.0;
  

  my $expected = distance_to_hours($km);

  printf "%f %s %f\n" , $offset , $km, $expected; 
}


# my $dt = $parser->parse_datetime('October 28, 2011 9:00 PM PDT');

# print "$dt\n";

