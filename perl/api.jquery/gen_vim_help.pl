#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: gen_vim_help.pl
#
#        USAGE: ./gen_vim_help.pl  
#
#  DESCRIPTION: A script to convert jQuery docs into vim-help format.
#
#      OPTIONS: -debug
# REQUIREMENTS: XML::Simple
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Tuomas Poikela (tpoikela), tuomas.sakari.poikela@gmail.com
# ORGANIZATION: CERN
#      VERSION: 1.0
#      CREATED: 26/06/16 19:11:58
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Text::Wrap;
use Data::Dumper;
use XML::Simple;
use Getopt::Long;

my %opt;
GetOptions(
    "d|debug" => \$opt{debug},
    <+opt2+> => \$opt{<+val2+>},
);

my $LINE_LENGTH = 75;
$Text::Wrap::columns = 78;

my %top;
my %links;
my %methods;
my %selectors;
my %properties;



my @files = get_xml_source_files();

my $help = {};
$help->{intro} = "jQuery documentation for vim  *jquery-help*\n\n";
$help->{toc} = "Table of Contents\n\n";
$help->{method} = "";
$help->{selector} = "";
$help->{property} = "";

my @sections = qw(intro toc method property selector);

foreach my $f (@files) {
    my $xml = XML::Simple->new();
    my $doc = $xml->XMLin($f);

    debug_print($doc, $f);

    my $name = get_entry_name($doc, $f);
    my $type = get_type($doc);
    my $signature = get_signature($doc);
    my $desc = get_desc($doc);
    my $examples = get_examples($doc);

    add($type, get_line("-") . "\n" );
    add($type,  $name . "\n$type\n$signature\n\n" . $desc . "\n\n" . $examples);
}

print_post_amble();

#---------------------------------------------------------------------------
# HELPER FUNCTIONS
#---------------------------------------------------------------------------

# Grabs the source files using wget unless the folder is in current folder
sub get_xml_source_files {
    my $src_docs_url = "https://github.com/jquery/api.jquery.com/archive/master.zip";
    if (not -e "master.zip") {
        my $ok = system("wget $src_docs_url");
        if ($ok != 0) {
            die("Failed to get the source docs from $src_docs_url.");
        }
    }
    if (not -d "api.jquery.com-master") {
        if (-e "master.zip") {
            system("unzip master.zip");
        }
        else {
            die("master.zip doesn't exist for unzipping. Cannot continue...");
        }
    }
    my $src_folder = "api.jquery.com-master/entries";
    my @files = glob("$src_folder/*.xml");
}

sub debug_print {
    my ($doc, $f) = @_;
    if (defined $opt{debug}) {
        my @keys = keys(%{$doc});
        print "#### FILE: $f ####\n";
        print "Possible keys are: @keys\n";
        print Dumper($doc);
    }
}

sub add {
    my ($tag, $str) = @_;
    $help->{$tag} .= $str;
}

sub get_entry_name {
    my ($doc, $f) = @_;
    my $name = "";
    my $href = $doc;
    $name = $href->{name} if exists $href->{name};
    $name = $href->{title} if exists $href->{title};

    if (length($name) == 0) {
        $href = dig_up_entry($doc);
        $name = $href->{name};
    }

    print STDERR "No name/title for file $f.\n" if length($name) == 0;

    my $res = "";
    if (is_method($href)) {
        $name .= "()" unless $name =~ /\(/;
        $res =  "`$name`" . " *jquery-$name* " . get_link($name);
        $methods{$name} = "$name";
    }
    elsif (is_selector($href)) {
        $res =  "`$name`" . " *jquery-$name* ". get_link($name);
        $selectors{$name} = $name;
    }
    elsif (is_property($href)) {
        $res =  "`$name`" . " *jquery-$name*". get_link($name);
        $properties{$name} = $name;
    }
    else {
        print STDERR "File: $f\nUNSUPPORTED type: " . $href->{type};
        print STDERR Dumper($href);
    }
    $top{curr} = $name;
    return $res;
}

sub get_link {
    my ($name) = @_;
    $name =~ s/^\.//g;
    $name =~ s/[()]+//g;
    $links{$name} = $name;
    return "*$name*";
}

sub dig_up_entry {
    my ($doc) = @_;
    if (exists $doc->{entry}) {
        my $href = $doc->{entry};
        my @names = keys(%{$href});
        my $name = $names[0];
        $href = $doc->{entry}->{$name};
        $href->{name} = $name;
        return $href;
    }
    return $doc;
}

sub get_type {
    my ($doc) = @_;
    return $doc->{type} if exists $doc->{type};
    my $href = dig_up_entry($doc);
    return $href->{type} if exists $href->{type};
    return "UNKNOWN";

}

sub get_signature {
    my ($doc) = @_;
    my $href = dig_up_entry($doc);
    my $res = "";
    if (exists $href->{signature}) {
        my $signature = $href->{signature};
        my @signs = get_array_or_one_hash($signature);

        foreach my $s (@signs) {
            my $name = get_from_sign($s, "name");
            my $type = get_from_sign($s, "type");
            my $desc = get_from_sign($s, "desc");
            $type = "string" unless length($type);
            $res .= "\tArgument: type $type, name $name\n";
            if (length($desc) > 0) {
                $res .= wrap("\t", "\t", $desc) . "\n";
            }
            print STDERR "$top{curr} Added arg |$name|\n";
        }
    }
    return $res;
}

sub get_from_sign {
    my ($sign, $tag) = @_;
    my $href = $sign->{argument};
    return $href->{$tag} if exists $href->{$tag};
    return "";

}

sub get_line {
    my ($sym) = @_;
    return $sym x $LINE_LENGTH;
}

sub get_examples {
    my ($doc) = @_;
    if (exists $doc->{example}) {
        my @examples = get_array_or_one_hash($doc->{example});
        my $res = "EXAMPLE |jquery-" . $doc->{name} . "|\n\n";
        foreach my $ex (@examples) {
            my $code = $ex->{code};
            $res .= format_code_desc($ex->{desc});
            #$res .= wrap("\t", "\t", $ex->{code}) . "<\n";
            $code = reformat_code($code);
            $res .=  $code . "\n<\n";
        }
        return $res;
    }
}

sub format_code_desc {
    my ($desc) = @_;
    if (ref($desc) eq 'HASH') {
        my $res = "";
        # Need to intertwine content/code
        my @content = coerce_into_array($desc->{content});
        my @code = coerce_into_array($desc->{code});
        @code = map {$_ = "`$_`"} @code;
        my $len = int(@code);
        for (my $i = 0; $i < $len; ++$i) {
            $res .= $content[$i];
            $res .= $code[$i];
        }
        return wrap("", "", $res);

    }
    else {
        wrap('', '', $desc) . " >\n";
    }
}

sub coerce_into_array {
    my ($code) = @_;
    if (ref($code) eq 'ARRAY') {
        return @{$code};
    }
    else {
        return qw($code);
    }
}

sub reformat_code {
    my ($code) = @_;
    my @code = split("\n", $code);
    @code = map {$_ = "\t" . $_} @code;
    return join("\n", @code);
}

sub get_desc {
    my ($doc) = @_;
    my $desc = $doc->{desc};
    my $text = "";
    if (ref($desc) eq 'HASH') {
        $text =  join('', @{$desc->{content}});

    }
    else {
        if (exists $doc->{desc}) {
            $text = $doc->{desc};
        }
        else {
            my $href = dig_up_entry($doc);
            $text =  $href->{desc} if exists $href->{desc};
        }
    }
    return wrap('', '', $text);
}

sub is_method {
    my ($doc) = @_;
    return $doc->{type} eq 'method';
}


sub is_selector {
    my ($doc) = @_;
    return $doc->{type} eq 'selector';
}

sub is_property {
    my ($doc) = @_;
    return $doc->{type} eq 'property';
}

sub print_post_amble {
    foreach my $sec (@sections) {
        print get_line("=") . "\n\n";
        print $help->{$sec};
    }
    print "vim set ft=help noreadonly modifiable";
}

sub get_array_or_one_hash {
    my ($data) = @_;
    my @res;
    if (ref($data) eq 'ARRAY') {
        return @{$data};
    }
    else {
        push(@res, $data);
    }
    return @res;
}
