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

use Cwd;
my $cwd = getcwd();

my $git_react = 'https://github.com/facebook/react.git';
my $react_help_file = 'vim-help-react-js.txt';
my $bundle = "react_js_bundle.md";

my $vim_help_bin = "vim-markdown-helpfile/bin/vim-helpfile";
my $vim_md_bin = "$cwd/$vim_help_bin";

do_sparse_checkout('react', $git_react, 'docs/');

create_one_md_file();

create_vim_help_file();

#---------------------------------------------------------------------------
# HELPER FUNCTIONS
#---------------------------------------------------------------------------

sub do_sparse_checkout {
    my ($dir, $repo, $doc_dir) = @_;
    if (not -d $dir) {
        system("git clone --depth 1 $repo");
        chdir($dir) or die($!);
        system("git config core.sparseCheckout true");
        system("echo '$doc_dir' >> .git/info/sparse-checkout");
        system('git checkout');
    }
    else {
        warn("Dir. $dir already exists. Skipping checkout.");
        chdir($dir) or die($!);
    }
}

sub create_one_md_file {
    my @globs = qw(
        react/docs/tutorial/tutorial.md
        react/docs/docs/*.md
        react/docs/warnings/*.md
    );
    my @md_files = ();
    foreach my $g (@globs) {
        push(@md_files, glob($g));
    }

    if (int(@md_files) == 0) {
        die("Cannot find any .md files.");
    }
    print "cat @md_files > $bundle\n";
    system("cat @md_files > $bundle");
}

sub create_vim_help_file {
    if (-e $bundle) {
        print "Creating final React docs at $cwd/doc/$react_help_file\n";
        system("$vim_md_bin --name react-js $bundle > $cwd/doc/$react_help_file");
    }
    else {
        die("$bundle doesn't exist.");
    }
}
