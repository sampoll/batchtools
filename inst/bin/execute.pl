#!/usr/bin/perl

use warnings;
use strict;

my $nargs = scalar @ARGV;
unless ($nargs >= 1)  {
  print "error: null command\n";
  exit 1;
}
my $cmd = $ARGV[0];

# Task Current States and approximate batchtools state:
# New          queued
# Pending      queued
# Assigned     queued
# Accepted     queued
# Preparing    queued
# Starting     running
# Running      running
# Complete     suceeded
# Shutdown     suceeded
# Failed       failed
# Rejected     failed

# start-job <cname> <ccmd> <job-uri-path> <job-logfile-path> <registry-src> <registry-dst> 
if ($cmd eq "start-job")  {
  if ( scalar @ARGV < 7 )  {
    printf "Error: usage is start-job <reg-src> <reg-dst> <job-uri-path> <job-log-path>\n";
    exit 1;
  }
  my ($cname, $ccmd, $joburi, $joblog, $regsrc, $regdst) = @ARGV[1..6];

  my $cmd = "docker service create -d --replicas 1 --restart-condition none";
  $cmd .= sprintf(" -e JC=\"%s\" -e JL=\"%s\"", $joburi, $joblog);
  $cmd .= sprintf(" --mount type=bind,source=%s,destination=%s", $regsrc, $regdst);
  $cmd .= " $cname \"$ccmd\"";
  my $res = `$cmd`;
  print("$res");

}

# kill-job < service-name > 
elsif ($cmd eq "kill-job")  {
  if (scalar @ARGV < 2)  {
    printf "Error: usage is kill-job < svc-name >\n";
    exit 1;
  }
  my $svc = $ARGV[1];
  my $cmd = sprintf("docker service rm %s\n", $svc);
  my $res = `$cmd`;
  print("$res");
}

# list-jobs 
elsif ($cmd eq "list-jobs")  {

  my @results = ();
  my @services = split(/\n/, `docker service ls`);
  shift @services;   # remove header line
  for my $s (@services)  {
    chomp($s);
    my ($svcid,undef) = split(/[\s]+/, $s);
    my @taskout = split(/\n/, `docker service ps $svcid`);
    my $taskdata = $taskout[1];  # discard header
    my ($taskid, undef, undef, undef, undef, $state) = split(/[\s]+/, $taskdata);
    my $str = $svcid . ':' . $taskid . ':' . $state;
    push(@results, $str);
  }
  printf "%s\n", join(' ', @results);
}

# rm-completed
elsif ($cmd eq "rm-completed")  {

  my @results = ();
  my @services = split(/\n/, `docker service ls`);
  shift @services;   # remove header line
  for my $s (@services)  {
    chomp($s);
    my ($svcid,undef) = split(/[\s]+/, $s);
    my @taskout = split(/\n/, `docker service ps $svcid`);
    my $taskdata = $taskout[1];  # discard header
    my ($taskid, undef, undef, undef, undef, $state) = split(/[\s]+/, $taskdata);
    if ($state eq "Completed")  {
       my $res = `docker service rm $svcid`;
    }
  }
}

# rm-all
elsif ($cmd eq "rm-all")  {
  my @results = ();
  my @services = split(/\n/, `docker service ls`);
  shift @services;   # remove header line
  for my $s (@services)  {
    chomp($s);
    my ($svcid,undef) = split(/[\s]+/, $s);
    my $res = `docker service rm $svcid`;
  }
}
0;


