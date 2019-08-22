use v5.14;
use warnings;

use subs qw(subdirs slurp spurt);

my $N = 20;

die "Usage:\n  bc.pl <name> [<libdirs> ...}\n" if @ARGV < 2;
my ($name, @roots) = @ARGV;
my $index  = "${name}bc.index";
my $source = "${name}bc.c";
my $header = "${name}bc.h";

my @dirs;
subdirs \@dirs, map { s{[/\\]?$}{/.}r } @roots;

my @modules = sort map { glob "$_/*.moarvm" } @dirs;

my @source;
my @header;
my @entries;
my @index;
for (@modules) {
    my ($base) = /\/\.\/(.+?)\.moarvm$/;
    my $ident = $base =~ s{[./]}{_}rg;
    $ident = "lib${name}_bc_${ident}";

    my $bc = slurp $_;
    my $size = length $bc;

    push @index, "$base.moarvm", $size;
    push @entries, "    { \"$base.moarvm\", $ident, sizeof $ident },";
    push @source, "const unsigned char ${ident}[$size] = {";
    push @header, "extern const unsigned char ${ident}\[$size];";
    for (my $pos = 0; $pos < length($bc); $pos += $N) {
        push @source, join '',
            map { sprintf '%3u,', ord } split(//, substr($bc, $pos, $N));
    }

    push @source, '};'
}
push @source, '';
push @header,
    '',
    "struct lib${name}_entry {",
    '    const char *name;',
    '    const unsigned char *bc;',
    '    unsigned size;',
    '};',
    '',
    "static const struct lib${name}_entry lib${name}_index[] = {", @entries, '};',
    '';
push @index, '';

spurt $index, join("\n", @index);
spurt $source, join("\n", @source);
spurt $header, join("\n", @header);
exit;

sub subdirs {
    my ($acc, @dirs) = @_;
    for (@dirs) {
        s{[/\\]?$}{};
        push @$acc, $_;
        subdirs($acc, glob "$_/*/");
    }
}

sub slurp {
    my ($file) = @_;
    open my $fh, '< :raw :bytes', $file or die "$file: $!";
    sysread $fh, my $contents, -s $file or die "$file: $!";
    close $fh;
    $contents;
}

sub spurt {
    my ($file, $contents) = @_;
    open my $fh, '> :raw :bytes', $file or die "$file: $!";
    syswrite $fh, $contents or die "$file: $!";
    close $fh;    
}
