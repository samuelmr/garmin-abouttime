#!/usr/bin/env bash
# Checks that sizes.jungle maps every screen size (device family) of the
# watch-face capable devices in the Connect IQ SDK, and suggests lines for
# the missing ones. Also lists mappings that no watch-face device uses.
#
# Usage: ./check-sizes.sh [sizes.jungle]
# Exits with 1 if something should be changed.
set -euo pipefail

JUNGLE_FILE="${1:-sizes.jungle}"
DEVICES_DIR="${CIQ_HOME:+${CIQ_HOME}../../Devices}"
: "${DEVICES_DIR:=$HOME/Library/Application Support/Garmin/ConnectIQ/Devices}"

if [[ ! -f "$JUNGLE_FILE" ]]; then
  echo "Error: jungle file not found: $JUNGLE_FILE" >&2
  exit 1
fi
if [[ ! -d "$DEVICES_DIR" ]]; then
  echo "Error: SDK devices folder not found: $DEVICES_DIR" >&2
  exit 1
fi

perl -MJSON::PP -e '
use strict; use warnings;
my ($jungle, $devdir) = @ARGV;

# sizes.jungle: qualifier -> size folder ("base" when only base.resourcePath)
my (%map, @order);
open my $fh, "<", $jungle or die "$jungle: $!\n";
while (<$fh>) {
  next if /^\s*#/;
  next unless /^\s*([\w-]+)\.resourcePath\s*=\s*(.*?)\s*$/;
  my ($q, $v) = ($1, $2);
  next if $q eq "base";
  my $folder = $v =~ m{resources-\$\(lang\)/([\w-]+)} ? $1 : "base";
  push @order, $q unless exists $map{$q};
  $map{$q} = $folder;
}
close $fh;

# SDK devices
my (%family, %wf_family, %wf_device);
opendir my $dh, $devdir or die "$devdir: $!\n";
for my $id (sort grep { !/^\./ } readdir $dh) {
  my $file = "$devdir/$id/compiler.json";
  next unless -f $file;
  my $j = eval {
    local $/; open my $f, "<", $file or die; JSON::PP->new->decode(scalar <$f>)
  } or next;
  my $fam = $j->{deviceFamily} or next;
  my $wf = grep { (ref $_ ? $_->{type} : $_) eq "watchFace" } @{ $j->{appTypes} || [] };
  push @{ $family{$fam} }, $id;
  if ($wf) { push @{ $wf_family{$fam} }, $id; $wf_device{$id} = 1; }
}
closedir $dh;

sub dims { my ($s, $w, $h) = $_[0] =~ /^(\w+)-(\d+)x(\d+)$/ or return; ($s, $w, $h) }

# Suggest the folder of the closest mapped screen: same shape first,
# then by the shorter side.
sub suggest {
  my ($s, $w, $h) = dims($_[0]) or return "base";
  my $short = $w < $h ? $w : $h;
  my ($best, $bestScore);
  for my $q (keys %map) {
    my ($qs, $qw, $qh) = dims($q) or next;
    next unless $wf_family{$q};
    my $score = abs($short - ($qw < $qh ? $qw : $qh)) + ($qs eq $s ? 0 : 10000);
    ($best, $bestScore) = ($q, $score) if !defined $bestScore || $score < $bestScore;
  }
  return defined $best ? $map{$best} : "base";
}

my $problems = 0;

my @missing = grep { !exists $map{$_} } sort keys %wf_family;
if (@missing) {
  $problems++;
  print "Screen sizes of watch-face devices missing from $jungle:\n";
  for my $fam (@missing) {
    print "  $fam: @{ $wf_family{$fam} }\n";
  }
  print "\nSuggested lines (folder of the closest mapped size, check in the simulator):\n";
  for my $fam (@missing) {
    my $f = suggest($fam);
    print "  $fam.resourcePath = \$(base.resourcePath)",
      ($f eq "base" ? "" : ";resources-\$(lang)/$f"), "\n";
  }
}

my @unused = grep { !$wf_family{$_} && !$wf_device{$_} } @order;
if (@unused) {
  print "\n" if $problems++;
  print "Mappings in $jungle that no watch-face device uses:\n";
  for my $q (@unused) {
    my $why = $family{$q} ? "only @{ $family{$q} }, which cannot run watch faces"
                          : "no such screen size or device in the SDK";
    print "  $q ($why)\n";
  }
}

if ($problems) { exit 1 }
printf "%s covers all %d screen sizes of watch-face devices in the SDK.\n",
  $jungle, scalar keys %wf_family;
' "$JUNGLE_FILE" "$DEVICES_DIR"
