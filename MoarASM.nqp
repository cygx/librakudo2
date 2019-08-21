class MoarASM::CompUnit {
    has $!mcu;
    has $!bytecode;
    has $!compunit;
    has $!mainline;

    method mast() { $!mcu }
    method bytecode() { $!bytecode }
    method compunit() { $!compunit }
    method mainline() { $!mainline }

    method BUILD() {
        my $string-heap := MoarVM::StringHeap.new;
        my $writer := MoarVM::BytecodeWriter.new(:$string-heap,
            callsites => MoarVM::Callsites.new(:$string-heap),
            annotations => MAST::Bytecode.new);
        $!mcu := MAST::CompUnit.new(:$writer);
        $writer.set-compunit($!mcu);
    }

    method add-frame($body?, :$name = '<anon>', :$main, :$load, :$deserialize) {
        my $frame := MAST::Frame.new(:$name,
            writer => $!mcu.writer,
            compunit => $!mcu);

        $!mcu.add_frame($frame);
        $!mcu.main_frame($frame) if nqp::defined($main);
        $!mcu.load_frame($frame) if nqp::defined($load);
        $!mcu.deserialize_frame($frame) if nqp::defined($deserialize);

        if nqp::defined($body) {
            my $*MAST_FRAME := $frame;
            $body();
        }

        $frame;
    }

    method assemble() {
        $!bytecode := nqp::getcomp('MAST').assemble($!mcu).bytecode;
        self;
    }

    method load() {
        $!compunit := nqp::buffertocu($!bytecode);
        $!mainline := nqp::compunitmainline($!compunit);
        self;
    }

    method dump($file) {
        my $fh := nqp::open($file, 'w');
        nqp::writefh($fh, $!bytecode);
        nqp::closefh($fh);
        self;
    }
}

my class op is export {
    for MAST::Ops.WHO<%generators> {
        my $key := nqp::iterkey_s($_);
        my $val := nqp::iterval($_);
        op.HOW.add_method(op, $key, method (*@args) {
            $val(|@args);
        });
    }
}

sub local($type) is export {
    MAST::Local.new(:index($*MAST_FRAME.add_local($type)));
}
