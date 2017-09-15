#!/usr/bin/env perl
#===============================================================================
#
#         FILE: vim_help_node_js.pl
#
#        USAGE: ./vim_help_node_js.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: Uses system() call.
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Tuomas Poikela (tpoikela), tuomas.sakari.poikela@gmail.com
# ORGANIZATION: CERN
#      VERSION: 1.0
#      CREATED: 02/02/2017 07:21:41 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Cwd;

my $cwd = getcwd();
print "CWD: $cwd\n";

my $vim_help_bin = "vim-markdown-helpfile/bin/vim-helpfile";
my $vim_md_bin = "$cwd/$vim_help_bin";

my $git_node = 'https://github.com/nodejs/node.git';

my $bundle = "node_js_bundle.md";

do_sparse_checkout();

create_one_md_file();

create_vim_help();

#---------------------------------------------------------------------------
# HELPER FUNCTIOS
#---------------------------------------------------------------------------

sub do_sparse_checkout {
    if (not -d "node") {
        system("git clone --depth 1 $git_node");
        chdir("node") or die($!);
        system("git config core.sparseCheckout true");
        system('echo "doc/" >> .git/info/sparse-checkout');
        system('git checkout master');
    }
    else {
        warn("Dir. node already exists. Skipping checkout.");
        chdir("node") or die($!);
    }
}

sub create_one_md_file {
    if (-e "$bundle") {
        warn("$bundle exists. Skipping cat *.md");
        return;
    }

    my @md_files = ();
    open(my $IFILE, "<", "doc/api/all.md") or die($!);
    while (<$IFILE>) {
        my $line = $_;
        if ($line =~ m/\@include\s+(\w+)$/) {
            push(@md_files, "doc/api/$1.md");
        }
    }
    system("cat @md_files > $bundle");

}

sub create_vim_help {
    if (-e "$bundle") {
        print "Creating final Node docs at $cwd/doc/vim-help-node-js.txt\n";
        system("$vim_md_bin --name node-js $bundle > $cwd/doc/vim-help-node-js.txt");
    }
    else {
        die("$bundle doesn't exist.");
    }
}

