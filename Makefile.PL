use inc::Module::Install;

name('Module-Refresh');
author('Jesse Vincent <jesse@bestpractical.com>');
license('perl');
version_from('lib/Module/Refresh.pm');
abstract_from('lib/Module/Refresh.pm');
build_requires ('Test::More' => 0);
&WriteAll;
