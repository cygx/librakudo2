#ifdef _WIN32
#define DLLIMPORT __declspec(dllimport)
#else
#define DLLIMPORT
#endif

typedef struct MVMInstance MVMInstance;

DLLIMPORT void libnqp_init(MVMInstance *vm);
DLLIMPORT int  libnqp_main(int argc, char *argv[]);
