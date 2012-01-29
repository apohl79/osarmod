#!/usr/bin/perl

use strict;

my $maxrows = 15;
my $topdir = `pwd`;
my $in = $ARGV[0];
shift @ARGV;
my @devs = @ARGV;
my $in_log = undef;
if (defined $in) {
  $in_log = read_log($in);
}

git_dir();

sub git_dir {
  my $D;
  opendir($D, ".");
  my @dd = readdir($D);
  closedir($D);
  if (is_git_dir(@dd)) {
    git_log();
  }
  foreach my $d (@dd) {
    next if $d eq "." or $d eq ".." or $d eq ".git" or $d eq ".repo";
    if (-d $d && ! -l $d) {
      chdir($d);
      git_dir();
      chdir("..");
    }
  }
}

sub is_git_dir {
  foreach my $d (@_) {
    next if $d eq "." or $d eq "..";
    if ($d eq ".git") {
      return 1;
    }
  }
  return 0;
}

sub git_log {
  my $pwd = `pwd`;
  my $log = `git log --oneline --no-color -n1`;
  chomp $pwd;
  chomp $log;
  if (defined $in_log) {
    if ($log ne $in_log->{$pwd}) {
      my $nlog = `git log --oneline --no-color`;
      my $opwd = substr($pwd, length($topdir), length($pwd));
      my $show = 1;
      if (scalar(@devs) > 0 && index($opwd, "device/") == 0) {
	$show = 0;
	foreach my $dev (@devs) {
	  if (index($opwd, $dev) > -1) {
	    $show = 1;
	    last;
	  }
	}
      }
      if ($show) {
	print "*** $opwd\n";
	my $c = 0;
	foreach my $l (split /\n/, $nlog) {
	  if ($l ne $in_log->{$pwd} && $c++ < $maxrows) {
	    print "$l\n";
	  } else {
	    last;
	  }
	}
	print "\n";
      }
    }
  } else {
    print "$pwd:$log\n";
  }
}

sub read_log {
  my $file = shift;
  my %ret;
  open F, "<$file";
  foreach my $l (<F>) {
    chomp $l;
    my ($file, $log) = split /:/, $l, 2;
    chomp $log;
    #print "$file:$log\n";
    $ret{$file} = $log;
  }
  close F;
  return \%ret;
}
