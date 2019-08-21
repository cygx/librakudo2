use v5.14;
use warnings;

use subs qw(slurp spurt);

my $N = 20;

die "Usage:\n  bc.pl <name> [<libdirs> ...}\n" if @ARGV < 2;
my ($name, @dirs) = @ARGV;
my $source = "${name}bc.c";
my $header = "${name}bc.h";

my @modules = sort map { glob s{[/\\]?$}{/}r . '*.moarvm' } @dirs;

my @source;
my @header;
for (@modules) {
    my ($ident) = /([^\/\\]+)\.moarvm$/;
    $ident =~ s/\./_/;
    $ident = "lib${name}_bc_${ident}";

    my $bc = slurp $_;
    my $size = length $bc;

    push @source, "const unsigned char ${ident}[$size] = {";
    push @header, "extern const unsigned char ${ident}\[$size];";
    for (my $pos = 0; $pos < length($bc); $pos += $N) {
        push @source, join '',
            map { sprintf '%3u,', ord } split(//, substr($bc, $pos, $N));
    }

    push @source, '};'
}
push @source, '';
push @header, '';

spurt $source, join("\n", @source);
spurt $header, join("\n", @header);
exit;

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
