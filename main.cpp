#include <stdio.h>

extern "C" void myPrintfFunction(const char* format, int a, const char* b);

int main() {
    printf("Hello world\n");

    myPrintfFunction("%d%d%s", 29, "hello");

    return 0;
}
