use inc::Module::Install;

name('Module-Refresh');
author('Jesse Vincent <jesse@bestpractical.com>');
license('perl');
version('0.01');
build_requires ('Test::More' => 0);
&WriteAll;
