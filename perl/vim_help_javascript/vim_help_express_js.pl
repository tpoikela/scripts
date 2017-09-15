#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: vim_help_express_js.pl
#
#        USAGE: ./vim_help_express_js.pl  
#
#  DESCRIPTION: k
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Tuomas Poikela (tpoikela), tuomas.sakari.poikela@gmail.com
# ORGANIZATION: CERN
#      VERSION: 1.0
#      CREATED: 02/02/2017 09:52:37 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use File::Slurp;
use Cwd;

my $cwd = getcwd();
print "CWD: $cwd\n";

my $vim_help_bin = "vim-markdown-helpfile/bin/vim-helpfile";
my $vim_md_bin = "$cwd/$vim_help_bin";

my $repo_dir = "expressjs.com";
my $git_express = 'https://github.com/expressjs/expressjs.com.git';

my $api_md = "expressjs.com/en/api.md";

my $inc_dir = "expressjs.com/_includes/api/en/4x/";

# Example of file entry
#  {% include api/{{ page.lang }}/4x/express.md %}

do_sparse_checkout();

my @md_files = get_main_md_files();

create_one_md_file(\@md_files);

create_vim_help();

#---------------------------------------------------------------------------
# HELPER FUNCTIOS
#---------------------------------------------------------------------------

sub do_sparse_checkout {
    if (not -d $repo_dir) {
        system("git clone $git_express");
        #chdir($repo_dir) or die($!);
        #system("bundle install");
        #system("git config core.sparseCheckout true");
        #system('echo "en/" >> .git/info/sparse-checkout');
        #system('git checkout');
    }
    else {
        warn("Dir. $repo_dir already exists. Skipping checkout.");
    }
}

sub get_main_md_files {
    my @md_files = ();
    open(my $IFILE, "<", $api_md) or die $!;
    while (<$IFILE>) {
        my $line = $_;
        if ($line =~ m/(\w+).md\s+\%\}/) {
            print STDERR "Found md file $1\n";
            push(@md_files, "$1.md");
        }
    }
    return @md_files;
}

sub create_one_md_file {
    my ($files) = @_;
    if (-e "bundle.md") {
        warn("bundle.md exists. Skipping cat *.md");
        return;
    }

    my @md_files = @{$files};

	my $inc_re = qr/(\{\% include (\S+) \%\})/;

    my $res = "";
	# Process each file with includes
	foreach my $f (@md_files) {
		my $text = read_file("$inc_dir/$f");
		while ($text =~ m/$inc_re/g) {
			my $line = $1;
            my $file = $2;
            print STDERR "L: $1, F: $2\n";

            my $full_file = "expressjs.com/_includes/$2";
            my $inc_file = read_file($full_file);
            $text =~ s/$line/$inc_file/;
		}
        $res .= $text . "\n";
	}
    print $res;
}

sub create_vim_help {
    if (-e "bundle.md") {
        system("$vim_md_bin --name express-js bundle.md > $cwd/doc/vim-help-express-js.txt");
    }
    else {
        die("bundle.md doesn't exist.");
    }
}

