use MONKEY-SEE-NO-EVAL;
use MoarASM:from<NQP>;
use nqp:from<NQP>;
use nqp;

unit sub MAIN(IO() $index);

my $name = ~($index ~~ /^ <(.*)> "bc.index" $/);
my @modules = $index.slurp.lines.rotor(3);

sub STR { EVAL :lang<nqp>, 'return local(str)' }
sub INT { EVAL :lang<nqp>, 'return local(int)' }
sub OBJ { EVAL :lang<nqp>, 'return local(Mu)' }

my $cu := MoarASM::CompUnit.new;
$cu.add-frame: {
# declare locals

    my \S0 = STR;
    my \I0 = INT;
    my \I1 = INT;
    my \R0 = OBJ;
    my \R1 = OBJ;

    my \LANG = STR;
    my \ZERO = INT;
    my \NULL = OBJ;
    my \NULLPTR = OBJ;
    my \BOOTInt = OBJ;
    my \BOOTHash = OBJ;

    my \byte = OBJ;
    my \ByteArray = OBJ;
    my \Pointer = OBJ;

    my $info := OBJ;

    op.const_s:     LANG, $name;
    op.const_i64:   ZERO, 0;
    op.null:        NULL;
    op.bootint:     BOOTInt;
    op.boothash:    BOOTHash;

# create byte type

    op.create:      R0, BOOTHash;
    op.const_i64:   I0, 8;
    op.box_i:       R1, I0, BOOTInt;
    op.const_s:     S0, 'bits';
    op.bindkey_o:   R0, S0, R1;
    op.const_i64:   I0, 1;
    op.box_i:       R1, I0, BOOTInt;
    op.const_s:     S0, 'unsigned';
    op.bindkey_o:   R0, S0, R1;
    op.null:        R1;

    op.create:      $info, BOOTHash;
    op.const_s:     S0, 'integer';
    op.bindkey_o:   $info, S0, R0;
    op.null:        R0;

    op.const_s:     S0, 'P6int';
    op.newtype:     byte, NULL, S0;
    op.composetype: byte, byte, $info;
    op.null:        $info;

# create ByteArray type

    op.create:      R0, BOOTHash;
    op.const_s:     S0, 'type';
    op.bindkey_o:   R0, S0, byte;

    op.create:      $info, BOOTHash;
    op.const_s:     S0, 'array';
    op.bindkey_o:   $info, S0, R0;
    op.null:        R0;

    op.const_s:     S0, 'VMArray';
    op.newtype:     ByteArray, NULL, S0;
    op.composetype: ByteArray, ByteArray, $info;
    op.null:        $info;

# create Pointer type

    op.const_s:     S0, 'CPointer';
    op.newtype:     Pointer, NULL, S0;
    op.composetype: Pointer, Pointer, NULL;

# init NULLPTR

    op.box_i:       NULLPTR, ZERO, Pointer;

# populate cache

    op.create:      R0, BOOTHash;

for @modules -> ($path, $ident, Int() $size) {
    op.create:      R1, ByteArray;
    op.const_i64:   I0, $size;
    op.const_s:     S0, $ident;
    op.findsym:     I1, NULLPTR, S0;
    op.memread:     R1, ZERO, I0, I1;
    op.const_s:     S0, $path;
    op.bindkey_o:   R0, S0, R1;
    op.null:        R1;
}

    op.const_s:     S0, 'bytecode_cache';
    op.bindhllsym:  LANG, S0, R0;

    op.return;
}

my $bc := $cu.assemble.bytecode;
my int $len = nqp::elems($bc);

my $fh = open "{$name}prelude.h", :w;
LEAVE $fh.close;

$fh.put: "static const unsigned char lib{$name}_prelude[] = \{";
loop (my int $i = 0; $i < $len; $i = $i + 1) {
    $fh.print: nqp::atpos_i($bc, $i).fmt('%3u,');
    $fh.print: "\n" if ($i + 1) %% 20;
}
$fh.put: "\n};";
