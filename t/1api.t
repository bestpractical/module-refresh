#!/usr/bin/perl -w

use strict;

use Test::More qw/no_plan/;

use lib qw{/tmp};

`echo "package Foo::Bar; sub foo { 'bar'}\n1;" > /tmp/FooBar.pm`;

use_ok('Module::Refresh');

my $r = Module::Refresh->new();

use_ok('FooBar', "Required our dummy module");

is(Foo::Bar->foo, 'bar', "We got the right result");

`echo "package Foo::Bar; sub foo { 'baz'}\n1;" > /tmp/FooBar.pm`;
is(Foo::Bar->foo, 'bar', "We got the right result, still");

$r->refresh_updated;
sleep (2); # we only have second-level granularity

is(Foo::Bar->foo, 'baz', "We got the right new result,");

delete $INC{'FooBar.pm'};
require "FooBar.pm";

is(Foo::Bar->foo, 'baz', "We got the right new result,");

