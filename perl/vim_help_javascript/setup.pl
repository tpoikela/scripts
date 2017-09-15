#!/usr/bin/env perl
#===============================================================================
#
#         FILE: setup.pl
#
#        USAGE: ./setup.pl
#
#  DESCRIPTION: A setup script before building vim-help documentation.
#
#      OPTIONS: ---
# REQUIREMENTS: npm must be installed. git must be installed.
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Tuomas Poikela (tpoikela), tuomas.sakari.poikela@gmail.com
# ORGANIZATION: ----
#      VERSION: 1.0
#      CREATED: 02/02/2017 07:21:41 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

mkdir("doc") unless -d "doc";

my $vim_md = 'vim-markdown-helpfile';

my $cmd = 'git clone git://github.com/mklabs/vim-markdown-helpfile.git';
my $err = 0;

$err = system($cmd);

if ($err == 0) {
    chdir($vim_md) or die("Couldn't cd into $vim_md");
    print STDERR "Running now npm install for $vim_md.\n";
    $err = system("npm install");
}

if ($err) {
    print STDERR "Script failed with errors.\n";
}
else {
    print STDERR "Setup OK.\n";
}

