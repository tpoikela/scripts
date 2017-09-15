#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: vim_help_enzyme_js.pl
#
#        USAGE: ./vim_help_enzyme_js.pl  
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
#      CREATED: 09/14/2017 11:18:08 AM
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

my $enzyme_help_file = 'vim-help-enzyme-js.txt';
my $git_enzyme = 'https://github.com/airbnb/enzyme.git';

my $bundle = "enzyme_js_bundle.md";

do_sparse_checkout();

create_one_md_file();

create_vim_help();

#---------------------------------------------------------------------------
# HELPER FUNCTIOS
#---------------------------------------------------------------------------

sub do_sparse_checkout {
    if (not -d "enzyme") {
        print "Doing a sparse checkout now.\n";
        system("git clone --depth 1 $git_enzyme");
        chdir("enzyme") or die($!);
        system("git config core.sparseCheckout true");
        system('echo "docs/" >> .git/info/sparse-checkout');
        system('git checkout master');
    }
    else {
        warn("Dir. enzyme already exists. Skipping checkout.");
        chdir("enzyme") or die($!);
    }
}

# This bundles all MD files into one big file
sub create_one_md_file {
    my @globs = qw(
        docs/api/*.md
        docs/api/ShallowWrapper/*.md
        docs/api/ReactWrapper/*.md
        docs/guides/*.md
        docs/future/*.md
    );

    my @md_files = ();
    foreach my $g (@globs) {
        push(@md_files, glob($g));
    }

    #open(my $IFILE, "<", "doc/api/all.md") or die($!);
    #while (<$IFILE>) {
    #    my $line = $_;
    #    if ($line =~ m/\@include\s+(\w+)$/) {
    #        push(@md_files, "doc/api/$1.md");
    #    }
    #}
    if (int(@md_files) == 0) {
        die("Cannot find any .md files.");
    }
    print "cat @md_files > $bundle\n";
    system("cat @md_files > $bundle");

}

sub create_vim_help {
    if (-e $bundle) {
        print "Creating final Enzyme docs at $cwd/doc/$enzyme_help_file\n";
        system("$vim_md_bin --name enzyme-js $bundle > $cwd/doc/$enzyme_help_file");
    }
    else {
        die("$bundle doesn't exist.");
    }
}

