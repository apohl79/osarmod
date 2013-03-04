#!/usr/bin/perl

my $dir = $ARGV[0];
my $dir_archive = $dir."/archive";
my @changelogs;
my @changelogs_dev;
my @roms;
my @roms_dev;

opendir D, "$dir" or die "Can't open $dir";
foreach my $f (sort { -M "$dir/$b" <=> -M "$dir/$a" } readdir(D)) {
  next if $f =~ /incremental|latest|version|previous/;
  if ($f =~ /^CHANGELOG.*?(-dev\d+)?$/) {
    if ($1) {
      push @changelogs_dev, $f;
    } else {
      push @changelogs, $f;
    }
  } elsif ($f =~ /^ionix.*?(-dev\d+)?-signed/) {
    if ($1) {
      push @roms_dev, $f;
    } else {
      push @roms, $f;
    }
  }
}
closedir D;

move_to_archive(@changelogs);
move_to_archive(@changelogs_dev);
move_to_archive(@roms);
move_to_archive(@roms_dev);

sub move_to_archive {
  pop @_;
  pop @_;
  if (! -d $dir_archive) {
    mkdir $dir_archive;
  }
  foreach my $f (@_) {
    print "Moving $dir/$f to $dir_archive\n";
    rename "$dir/$f", "$dir_archive/$f";
  }
}
