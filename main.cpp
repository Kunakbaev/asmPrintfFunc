#include <stdio.h>
#include <stdlib.h>

extern "C" void myPrintfFunction(const char* format, ...);

int main() {

    int number = 256;
    char chacha = '#';
    const char iAmString[] = "\"i am very long string\"";
    bool flag = true;
    myPrintfFunction("decimal number: %d, hex: %x, octal: %o, char: %c, string: %s, boolean: %b\n",
                        number, number, number, chacha, iAmString, flag);
    //myPrintfFunction("%d : 10, %x, s: %s after, %cd, boolean : %b\n", 10, 183, "sk!dsafd", '?', false);
    //myPrintfFunction("num : %d, bruh\n", 2882);
    //myPrintfFunction("number number");
    // myPrintfFunction("iamveryverylonglongstring : %c, number : %d", 'f', 1820);
    // myPrintfFunction(" biba boba i aboba");
    //myPrintfFunction("num : %d, string : %s, bruh : %b\n", 10, "hello world!", false);
    //myPrintfFunction("char: %c, int: %d, bool: %b, oct: %o, hex: %x, d : %d, d : %d", 'a', 10, true, 18, 289, 19, 2829);
    //myPrintfFunction("1) %d, 2) %d 3) %d 4) %d 5) %o 6) %o 7) %o 8) %d", 1, 2, 3, 4, 5, 6, 7, false);

    return 0;
}
