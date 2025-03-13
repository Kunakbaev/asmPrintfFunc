CFLAGS		 		:= -D _DEBUG -lm -ggdb3 -std=c++17 -O0 -Wall -Wextra -Weffc++ -Waggressive-loop-optimizations -Wc++14-compat -Wmissing-declarations -Wcast-align -Wcast-qual -Wchar-subscripts -Wconditionally-supported -Wconversion -Wctor-dtor-privacy -Wempty-body -Wfloat-equal -Wformat-nonliteral -Wformat-security -Wformat-signedness -Wformat=2 -Winline -Wlogical-op -Wnon-virtual-dtor -Wopenmp-simd -Woverloaded-virtual -Wpacked -Wpointer-arith -Winit-self -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel -Wstrict-overflow=2 -Wsuggest-attribute=noreturn -Wsuggest-final-methods -Wsuggest-final-types -Wsuggest-override -Wswitch-default -Wswitch-enum -Wsync-nand -Wundef -Wunreachable-code -Wunused -Wuseless-cast -Wvariadic-macros -Wno-literal-suffix -Wno-missing-field-initializers -Wno-narrowing -Wno-old-style-cast -Wno-varargs -Wstack-protector -fcheck-new -fsized-deallocation -fstack-protector -fstrict-overflow -flto-odr-type-merging -fno-omit-frame-pointer -pie -fPIE -Werror=vla
CC					:= g++
ASM_COMPILER		:= nasm
ASM_ARGS			:= -f elf64
ASM_LINKER			:= ld

BUILD_DIR 			:= building
MAIN_SRC  			:= ./main.cpp
ASM_PRINTF_SRC  	:= ./asmPrintf.asm
TARGET_NAME			:= myAsmPrintf

ASM_OBJ_NAME		:= $(BUILD_DIR)/asmPrintf.o
MAIN_OBJ_NAME		:= $(BUILD_DIR)/main.o


compileMain: building compileAsm
	$(CC) -c $(MAIN_SRC) -o $(MAIN_OBJ_NAME) $(CFLAGS)

compileAsm: building
	$(ASM_COMPILER) -o $(ASM_OBJ_NAME) $(ASM_PRINTF_SRC) $(ASM_ARGS)

compile: compileAsm
	$(CC) -o $(BUILD_DIR)/$(TARGET_NAME) $(MAIN_SRC) $(ASM_OBJ_NAME)

run:
	$(BUILD_DIR)/$(TARGET_NAME)

compileAndRun: compile run

building:
	mkdir -p $(BUILD_DIR)

clean:
	rm -r $(BUILD_DIR)
