#!/usr/bin/perl -w

use strict;

use Test::More qw/no_plan/;

use lib qw{/tmp};

`echo "package Foo::Bar; sub foo { 'bar'}\n1;" > /tmp/FooBar.pm`;

use_ok('Module::Refresh');

my $r = Module::Refresh->new();

use_ok('FooBar', "Required our dummy module");

# is our non-file-based method available?

can_ok('Foo::Bar', 'not_in_foobarpm');


is(Foo::Bar->foo, 'bar', "We got the right result");

`echo "package Foo::Bar; sub foo { 'baz'}\n1;" > /tmp/FooBar.pm`;
is(Foo::Bar->foo, 'bar', "We got the right result, still");

$r->refresh_updated;
sleep (2); # we only have second-level granularity

is(Foo::Bar->foo, 'baz', "We got the right new result,");

# After a refresh, did we blow away our non-file-based comp?
can_ok('Foo::Bar', 'not_in_foobarpm');

delete $INC{'FooBar.pm'};

ok(!UNIVERSAL::can('Foo::Bar', 'foo'), "We cleaned out the 'foo' method'");

require "FooBar.pm";

is(Foo::Bar->foo, 'baz', "We got the right new result,");



package Foo::Bar;

sub not_in_foobarpm {
    return "woo";
}

1;


