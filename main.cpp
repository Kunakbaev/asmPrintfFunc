#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

//                                                                        checks function call as printf would be
extern "C" void myPrintfFunction(const char* format, ...) __attribute__(( format (printf,1,2) ));

int main() {

    // printf("%x %b %o %d\n ", -1, -1, (uint64_t)-1, -1);
    // uint64_t x = -1;
    // printf("octal : %llo\n\n\n", x);

    //myPrintfFunction("biba i boba, num : %d\n", 10);

    myPrintfFunction("decimal : %d, octal : %o, hex : %x, oct: %o\n", 228, 192291, 3802, 19);
    myPrintfFunction("be : %e\n", 3802);

    int number = 256;
    char chacha = '#';
    const char iAmString[] = "\"i am very long string\"";
    bool flag = true;
    myPrintfFunction("decimal number: %d, hex: %x, octal: %o, char: %c, string: %s, binary: %b\n %d %s %x %d%%%c%b\n",
                        number, number, number, chacha, iAmString, flag,
                        -1, "loveskksksks", 3802, 100, 33, 126); // 57050
    //myPrintfFunction("%d : 10, %x, s: %s after, %cd, boolean : %b\n", 10, 183, "sk!dsafd", '?', false);
    //myPrintfFunction("num : %d, bruh\n", 2882);
    //myPrintfFunction("number number");
    // myPrintfFunction("iamveryverylonglongstring : %c, number : %d", 'f', 1820);
    //myPrintfFunction(" biba boba i aboba : %d\n", 10);
    //myPrintfFunction("num : %d, string : %s, bruh : %b\n", 10, "hello world!", false);
    //myPrintfFunction("char: %c, int: %d, bool: %b, oct: %o, hex: %x, d : %d, d : %d", 'a', 10, true, 18, 289, 19, 2829);
    myPrintfFunction("1) %d, 2) %d 3) %d 4) %d 5) %d 6) %d 7) %d 8) %d 9) %d 10) %d\n",
                        1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

    return 0;
}
