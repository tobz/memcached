#!/usr/bin/perl

use strict;
use Test::More tests => 10;
use FindBin qw($Bin);
use lib "$Bin/lib";
use MemcachedTest;


my $server = new_memcached('-m 128');
my $sock = $server->sock;


# set foo with no expiration time
print $sock "set foo 0 0 6\r\nfooval\r\n";
is(scalar <$sock>, "STORED\r\n", "stored foo");
mem_get_is($sock, "foo", "fooval");

# metaget should show no exptime
print $sock "metaget foo\r\n";
is(scalar <$sock>, "META foo age: unknown; exptime: 0; from: unknown\r\n", "metaget foo");
is(scalar <$sock>, "END\r\n", "metaget foo");

# set bar with an actual exptime
my $target_exptime = 3600;
print $sock "set bar 0 ${target_exptime} 6\r\nbarval\r\n";
is(scalar <$sock>, "STORED\r\n", "stored bar");
mem_get_is($sock, "bar", "barval");

# metaget should show exptime within a few seconds of the original TTL
print $sock "metaget bar\r\n";
my @retvals = split(/ /, scalar <$sock>);
is($retvals[0], "META", "response is the metadata");
is($retvals[1], "bar", "response is for bar");
my $exptime = $retvals[5];
$exptime =~ s/;$//;
ok($exptime =~ /^\d+$/, "exptime is an integer");
ok(int($exptime) > ($target_exptime - 5), "exptime is within the expected range");
