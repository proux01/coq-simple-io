#!/usr/bin/perl
use strict;
use warnings;
use autodie;
use File::Basename;

# Usage:
#   perl compat.pl -- plugin/compat.ml src/ExtractionQCCompat.v
#   perl compat.pl -- compat.ml
#   perl compat.pl -- ExtractionQCCompat.v
#
# Generate the given files depending on their basenames.
# That makes this script flexible to the exact location of those files.

my $coq_version = `coqc -print-version`;
$coq_version =~ s/([\d.]+).*/$1/;

if ($coq_version lt '8.11' || '8.15' le $coq_version) {
  print STDERR "Warning: This version of Coq is not supported: $coq_version";
  print STDERR "Currently supported versions of Coq: 8.13, 8.12, 8.11.\n"
}

sub writefile {
  my ($filename, $contents) = @_;
  open(my $file, '>', $filename);
  print $file "(* THIS FILE IS GENERATED BY compat.pl *)\n";
  print $file $contents;
  close $file;
}

# Generate file plugin/compat.ml
sub compat_ml {
  my $compat_ml;

  if ('8.15' le $coq_version) {
    $compat_ml .= "
let _CApp (x, y) = Constrexpr.CApp(x, y)
let _CAppExpl (x, y) = Constrexpr.CAppExpl((x, None), y)
let fromCApp1 x = x (* Compatibility projection from CApp's first field *)
";
  } else {
    $compat_ml .= "
let _CApp (x, y) = Constrexpr.CApp((None, x), y)
let _CAppExpl (x, y) = Constrexpr.CAppExpl((None, x, None), y)
let fromCApp1 (_, x) = x
";
  }

  return $compat_ml;
}

for my $filename (@ARGV) {
  my $bn = basename($filename);

  if ($bn eq 'compat.ml') {
    writefile($filename, compat_ml());
  } else {
    print STDERR "Warning: Unrecognized file name $filename\n";
  }
}