#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: gen_vim_help.pl
#
#        USAGE: ./gen_vim_help.pl  
#
#  DESCRIPTION: G
#
#      OPTIONS: ---
# REQUIREMENTS: ---
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

use XML::LibXML;
use XML::Simple;

use Getopt::Long;

my %opt;
GetOptions(
    "d|debug" => \$opt{debug},
    <+opt2+> => \$opt{<+val2+>},
);

my $LINE_LENGTH = 75;
$Text::Wrap::columns = 78;

my %methods;
my %selectors;
my %properties;

my $HOME = $ENV{HOME};
#my $src = $HOME . "/Downloads/jqapi/docs/entries";
my $src = $HOME . "/Downloads/api.jquery.com-master/entries";

my @files = glob("$src/*.xml");

my $help = {};
$help->{intro} = "jQuery documentation for vim  *jquery-help*\n\n";
$help->{toc} = "Table of Contents\n\n";
$help->{method} = "";
$help->{selector} = "";
$help->{property} = "";

my @sections = qw(intro toc method property selector);

foreach my $f (@files) {
    #my $doc = XML::LibXML->load_xml(location => $f);
    my $xml = XML::Simple->new();
    my $doc = $xml->XMLin($f);

    debug_print($doc, $f);

    my $name = get_entry_name($doc, $f);
    my $type = get_type($doc);
    my $desc = get_desc($doc);
    my $examples = get_examples($doc);

    add($type, get_line("-") . "\n" );
    add($type,  $name . "\n\n" . $desc . "\n\n" . $examples);
}

print_post_amble();

#---------------------------------------------------------------------------
# HELPER FUNCTIONS
#---------------------------------------------------------------------------

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

    if (is_method($href)) {
        $name .= "()" unless $name =~ /\(/;
        my $res =  "`$name`" . " *jquery-$name*";
        $methods{$name} = "$name";
        return $res;
    }
    elsif (is_selector($href)) {
        my $res =  "`$name`" . " *jquery-$name*";
        $selectors{$name} = $name;
        return $res;
    }
    elsif (is_property($href)) {
        my $res =  "`$name`" . " *jquery-$name*";
        $properties{$name} = $name;
    }
    else {
        print STDERR "File: $f\nUNSUPPORTED type: " . $href->{type};
        print STDERR Dumper($href);
    }
}

sub dig_up_entry {
    my ($doc) = @_;
    my $href = $doc->{entry};
    my @names = keys(%{$href});
    my $name = $names[0];
    $href = $doc->{entry}->{$name};
    $href->{name} = $name;
    return $href;
}

sub get_type {
    my ($doc) = @_;
    return $doc->{type} if exists $doc->{type};
    my $href = dig_up_entry($doc);
    return $href->{type} if exists $href->{type};
    return "UNKNOWN";

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
            $res .= wrap('', '', $ex->{desc}) . "\n";
            $res .= $ex->{code} . "\n\n";
        }
        return $res;
    }
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
    print "vim ft=help noreadonly modifiable";
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
