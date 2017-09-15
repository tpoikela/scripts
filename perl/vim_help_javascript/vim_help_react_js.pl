#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: vim_help_react_js.pl
#
#        USAGE: ./vim_help_react_js.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Tuomas Poikela (tpoikela), tuomas.sakari.poikela@gmail.com
# ORGANIZATION: CERN
#      VERSION: 1.0
#      CREATED: 02/02/2017 11:17:16 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

my $git_react = 'https://github.com/facebook/react.git';

#system("git clone $git_react");

do_sparse_checkout();

sub do_sparse_checkout {
    if (not -d "react") {
        system("git clone --depth 1 $git_react");
        chdir("react") or die($!);
        system("git config core.sparseCheckout true");
        system('echo "docs/" >> .git/info/sparse-checkout');
        system('git checkout');
    }
    else {
        warn("Dir. node already exists. Skipping checkout.");
        chdir("react") or die($!);
    }
}
