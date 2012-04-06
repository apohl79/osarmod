#!/usr/bin/perl

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);

my $cgi = new CGI;
my $params=$cgi->Vars;

print $cgi->header();

my $type = $params->{osarmod_type};
my $ver1 = $params->{version1};
my $ver2 = $params->{version2};
my $showdev = 0;
if (!defined $ver2) {
  $ver2 = $ver1;
}
if (index("$ver1$ver2", "-dev") > -1) {
  $showdev = 1;
}

my $file1 = "CHANGELOG_".$type."_".$ver1;
my $file2 = "CHANGELOG_".$type."_".$ver2;

if (-d "../$type") {
  if (!-f "../$type/$file1") {
    print "ERROR: invalid version1";
    exit;
  }
  if (!-f "../$type/$file2") {
    print "ERROR: invalid version2";
    exit;
  }

  print "<font face=\"verdana\">";
  my $read = 0;
  opendir(D, "../$type");
  foreach my $f (sort {$b cmp $a} readdir(D)) {
    #print "$f<br>";
    if (index($f, "CHANGELOG_$type") > -1 && ($showdev || index($f, "-dev") == -1)) {
      if ($f eq $file2) {
	$read = 1;
      }
      if ($file1 ne $file2 && $f eq $file1) {
	last;
      }
      if ($read) {
	my $v = (split("_", $f))[2];
	my $git = 0;

	print "<big><b>Version $v -</b></big><p>";
	open(F, "< ../$type/$f");
	<F>; <F>;
	print "<b>ChangeLog:</b><p>";
	foreach my $l (<F>) {
	  if (index($l, "Git") > -1) {
	    print "<b>Git Changes:</b><p>";
	    $git = 1;
	  } elsif (index($l, "---") > -1) {
	    # skip
	  } elsif (index($l, "***") > -1) {
	    print "<i>$l -</i><br>";
	  } else {
	    if ($git) {
	      my ($hash, $desc) = split(" ", $l, 2);
	      print "<table border='0' cellspacing='0'><tr><td valign='bottom'><font color='#aaaaaa'><pre>$hash</pre></font></td><td>$desc</td></tr></table>";
	    } else {
	      print "$l<br>";
	    }
	  }
	}
	close(F);
	print "<p>";
      }
      if ($f eq $file1) {
	last;
      }
    }
  }
  closedir(D);
  print "</font>";
} else {
  print "ERROR: invalid osarmod_type $type";
  exit;
}

