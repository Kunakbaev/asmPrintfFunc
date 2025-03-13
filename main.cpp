#include <stdio.h>

extern "C" void myPrintfFunction(int a, const char* b);

int main() {
    printf("Hello world\n");

    myPrintfFunction(58, "hello");

    return 0;
}
