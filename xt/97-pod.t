use strict;
use warnings;
use Test::More;
use Test::Pod 1.00;

my @files = ( 'scripts/pure-perl-make', all_pod_files( ('lib') ) );

all_pod_files_ok(@files);
