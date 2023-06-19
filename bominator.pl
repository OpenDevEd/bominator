#!/usr/bin/perl
use warnings; use strict; use utf8;
use open IO => ':encoding(UTF-8)', ':std';
use feature qw{ say signatures }; no warnings qw{ experimental::signatures };
# use experimental 'smartmatch'; use experimental qw(declared_refs);
# use 5.34.0; use experimental qw{ try }; no warnings { experimental::try };
# use File::Slurper qw(read_text read_lines write_text);
my $home = $ENV{HOME};
chomp(my $date = `date +'%Y-%m-%d_%H.%M.%S'`);
my $hasargs = $#ARGV;
my $help = "";
my $string = "";
my $number = "";
use Getopt::Long;
my $bom_in = "";
my $cpl_in = "";
GetOptions (
    "bom=s" => \$bom_in,
    "cpl=s" => \$cpl_in,
    ) or die("Error in command line arguments\n");

if (!$bom_in && !$cpl_in) {

say "
$0

Reformat Kicad 7 bom/cpl files for jlcpcb (https://jlcpcb.com/).

Follow https://support.jlcpcb.com/article/194-how-to-generate-gerber-and-drill-files-in-kicad-6 to generate Gerber and Drill.

Export bom from Kicad. Suppose this is called project.csv

Export cpl using the settings provided here:
https://support.jlcpcb.com/article/84-how-to-generate-the-bom-and-centroid-file-from-kicad to generate
You don't need to make any changes. Export both top/bottom layers to one file.
Suppose this is called project-pos.csv

You can process these files like this:

$0 --bom project.csv --cpl project-pos.csv

Files ending in jlcpcb.csv will be generated.

Note: If you have set an LCSC value in the schematic, Kicad 7 doesn't seem to export this in the bom. 
Therefore, those items need to be set manually. Any tips on how to fix this (and whether it can be fixed
are appreciated).
";

exit;
};


# jlcpcb
my @jbom = ("Comment","Designator","Footprint","JLCPCB Part");
# e.g., 100uF	C1	CAP-SMD_L3.5-W2.8	C16133
my @jcpl = ("Designator","Mid X","Mid Y","Layer","Rotation");
# e.g., C1	95.0518mm	22.6822mm	Top	270

#Kicad
#Ref,Val,Package,PosX,PosY,Rot,Side
#"Id";"Designator";"Footprint";"Quantity";"Designation";"Supplier and ref";
#
#bom: lipo_disconnector.csv
#Id	Designator	Footprint	Quantity	Designation	Supplier and ref	
#
#cpl: lipo_disconnector-top-pos.csv
#Ref	Val	Package	PosX	PosY	Rot	Side

my %bom_map = (
    "Comment","Designation",
    "Designator","Designator",
    "Footprint","Footprint",
    "JLCPCB Part","LCSC"
    );

my %cpl_map = (
    "Designator","Ref",
    "Mid X","PosX",
    "Mid Y","PosY",
    "Layer","Side",
    "Rotation","Rot"
    );


if ($bom_in) {
    my @kbom = @{&getcsv($bom_in,";")};
    &makecsv("$bom_in-jlcpcb.csv",\@kbom,\@jbom,\%bom_map);
}


if ($cpl_in) {
    my @kcpl = @{&getcsv($cpl_in,",")};
    &makecsv("$cpl_in-jlcpcb.csv",\@kcpl,\@jcpl,\%cpl_map);
}

exit;

sub makecsv($file, $kbom,$jbom,$bom_map) {
    my @kbom = @{$kbom};
    my @jbom = @{$jbom};
    my %map = %{$bom_map};
    open F,">$file";
    say F join ",", @jbom;
    foreach (@kbom[1..$#kbom]) {
	my %entry = %{$_};
	my @out ;
	foreach (@jbom) {
	    my $x = $entry{ %map{$_} };;
	    # Mid X,Mid Y,Layer
	    if ($_ =~ m/Mid/) {
		$x .= "mm";
	    };
	    if ($_ =~ m/Layer/) {
		$x = ucfirst($x);
	    };
	    if ($_ =~ m/Rotation/) {
		$x = $x+180;
		$x = $x % 360;
	    };
	    push @out, $x;
	};
	say F join ",", @out;
    };
    close F;
};

sub showcsv(@csv) {
    foreach (@csv) {
	my %h = %{$_};
	say "-------------";
	foreach (keys %h) {
	    say "- $_ = $h{$_}";
	};
    };
};

sub getcsv($file, $separator) {
    my @arrayOfHashes;
    my @rows = @{ &readcsv($file, $separator) };
    my @header = @{shift @rows};
    say "$file";
    say join("\t", @header);
    {
	my %hash;
	for (my $i=0; $i < scalar @header; $i++) {
	    $hash{$i} = $header[$i];
	};
	push @arrayOfHashes, \%hash;
    };
    foreach (@rows) {
	my %hash;
	my @line = @{$_};
	#say "@line";
	for (my $i=0; $i < scalar @header; $i++) {
	    #say "\t$header[$i] = $line[$i]";
	    $hash{$header[$i]} = $line[$i];
	};
	push @arrayOfHashes, \%hash;
    };
    return \@arrayOfHashes;
};


sub readcsv($file, $separator) {
    use Text::CSV;
    my $csv = Text::CSV->new({ sep_char => $separator });
    my $sum = 0;
    my @rows;
    open(my $data, '<', $file) or die "Could not open '$file' $!\n";
    while (my $line = <$data>) {
	chomp $line;
	if ($csv->parse($line)) { 
	    my @fields = $csv->fields();
	    push @rows, \@fields;
	} else {
	    warn "Line could not be parsed: $line\n";
	}
    }
    return \@rows;
};




