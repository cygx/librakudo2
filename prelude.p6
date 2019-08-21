use MONKEY-SEE-NO-EVAL;
use MoarASM:from<NQP>;
use nqp:from<NQP>;

unit sub MAIN($name, *@libdirs);

sub STR { EVAL :lang<nqp>, 'return local(str)' }
sub INT { EVAL :lang<nqp>, 'return local(int)' }
sub OBJ { EVAL :lang<nqp>, 'return local(Mu)' }

my @modules = @libdirs.map(*.IO.dir(test => /\.moarvm$/).Slip).sort(*.basename);

my $cu := MoarASM::CompUnit.new;
$cu.add-frame: {
# declare locals

    my \S0 = STR;
    my \I0 = INT;
    my \R0 = OBJ;
    my \R1 = OBJ;

    my \LANG = STR;
    my \NULL = OBJ;
    my \BOOTInt = OBJ;
    my \BOOTHash = OBJ;

    my \byte = OBJ;
    my \ByteArray = OBJ;

    my $info := OBJ;

    op.const_s:     LANG, $name;
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

# populate cache

    op.create:      R0, BOOTHash;

for @modules {
    op.create:      R1, ByteArray;
    op.const_i64:   I0, .s;
    op.setelemspos: R1, I0;
    op.const_s:     S0, .basename;
    op.bindkey_o:   R0, S0, R1;
    op.null:        R1;
}

    op.const_s:     S0, 'bytecode_cache';
    op.bindhllsym:  LANG, S0, R0;

    op.return;
}

$cu.assemble.dump("{$name}pre.moarvm");

Nil;
