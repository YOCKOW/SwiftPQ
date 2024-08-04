#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my $argc = @ARGV;
if ($argc < 2) {
  die "Missing required argument(s).\n";
}

my $inputPath = $ARGV[0];
my $format = $ARGV[1];

if (! -f $inputPath) {
  die "Missing input file.\n";
}

my $pgTypeArrayDesc = "";
my $inputFH;
open($inputFH, "< $inputPath") or die "Failed to open input file.";
while (my $inputLine = <$inputFH>) {
  if ($inputLine !~ /^#/ && $inputLine !~ /^$/) {
    $pgTypeArrayDesc .= $inputLine;
  }
}
close $inputFH;
my $pgTypes = eval $pgTypeArrayDesc;
@$pgTypes = sort { int($a->{'oid'}) <=> int($b->{'oid'}) } @$pgTypes;
my $numberOfTypes = scalar(@$pgTypes);

sub __escape {
  my $string = shift;
  $string =~ s/\\/\\\\/g;
  $string =~ s/"/\\"/g;
  return $string;
}
sub __escapeAndQuote {
  my $string = shift;
  return "\"" . &__escape($string) . "\"";
}

if ($format eq "--json") {
  # JSON doesn't allow trailing commas😞

  sub ____infoToJSON {
    my $info = shift;
    my @keys = sort keys %$info;
    my $numberOfKeys = @keys;
    my $result = "{";
    for (my $ii = 0; $ii < $numberOfKeys; $ii++) {
      my $key = $keys[$ii];
      my $value = $info->{$key};
      $result .= &__escapeAndQuote($key) . ":" . &__escapeAndQuote($value);
      if ($ii < $numberOfKeys - 1) {
        $result .= ","
      }
    }
    $result .= "}";
    return $result;
  }

  print "{";

  # Oid to info
  print "\"oidToInfo\":{";
  for (my $ii = 0; $ii < $numberOfTypes; $ii++) {
    my $pgTypeInfo = $pgTypes->[$ii];
    print &__escapeAndQuote($pgTypeInfo->{'oid'});
    print ":";
    print &____infoToJSON($pgTypeInfo);
    if ($ii < $numberOfTypes - 1) {
      print ",";
    }
  }
  print "},";

  # Name to info
  print "\"nameToInfo\":{";
  for (my $ii = 0; $ii < $numberOfTypes; $ii++) {
    my $pgTypeInfo = $pgTypes->[$ii];
    print &__escapeAndQuote($pgTypeInfo->{'typname'});
    print ":";
    print &____infoToJSON($pgTypeInfo);
    if ($ii < $numberOfTypes - 1) {
      print ",";
    }
  }
  print "}";

  print "}\n";
} elsif ($format eq "--swift") {
  # Not pretty...

  sub ____infoToDictLiteral {
    my $info = shift;
    my @keys = sort keys %$info;
    my $result = "[\n";
    foreach my $key (@keys) {
      my $value = $info->{$key};
      $result .= &__escapeAndQuote($key) . ":" . &__escapeAndQuote($value) . ",\n";
    }
    $result .= "]";
    return $result;
  }

  print "let pgTypeMap: [String:[String:[String:String]]] = [\n";

  # Oid to info
  print "\"oidToInfo\":[\n";
  foreach my $info (@$pgTypes) {
    print &__escapeAndQuote($info->{'oid'}) . ":" . &____infoToDictLiteral($info) . ",\n";
  }
  print "],\n";

  # Name to info
  print "\"nameToInfo\":[\n";
  foreach my $info (@$pgTypes) {
    print &__escapeAndQuote($info->{'typname'}) . ":" . &____infoToDictLiteral($info) . ",\n";
  }
  print "],\n";

  print "]\n";
} else {
  die "Unsupported format: $format";
}
