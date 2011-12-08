#include <sys/types.h>
#include <unistd.h>

int main(int argc,char * argv[]) {
    return lseek(atoi(argv[1]),0L,0);
}
