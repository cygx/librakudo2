#include <moar/api.h>
#include <string.h>

#include "nqpbc.h"
#include "nqpprelude.h"

void libnqp_init(MVMInstance *vm)
{
    MVM_vm_run_bytecode(vm, libnqp_prelude, sizeof libnqp_prelude);
    MVM_vm_run_bytecode(vm, libnqp_bc_ModuleLoader, sizeof libnqp_bc_ModuleLoader);
}

int libnqp_main(int argc, char *argv[])
{
#ifndef _WIN32
    signal(SIGPIPE, SIG_IGN);
#endif

    MVMInstance *vm = MVM_vm_create_instance();
    MVM_vm_set_exec_name(vm, argv[0]);
    MVM_vm_set_prog_name(vm, "nqp");
    MVM_vm_set_clargs(vm, argc, argv);
    libnqp_init(vm);
    MVM_vm_run_bytecode(vm, libnqp_bc_nqp, sizeof libnqp_bc_nqp);
    MVM_vm_exit(vm);
}
