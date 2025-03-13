#include <stdio.h>

extern "C" void myPrintfFunction();

int main() {
    printf("Hello world\n");

    myPrintfFunction();

    return 0;
}
