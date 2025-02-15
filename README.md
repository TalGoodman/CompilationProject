# README

This project uses Flex & Bison to create a compiler. The project utilizes GLib for various data structures, including hash tables (`GHashTable`), lists (`GList`), and strings (`GString`). Below is a detailed explanation of the components and how to build the project.

## Components

1. **Hash Table**: The project uses `GHashTable` to store symbols and their types (int/float).
2. **Lists**: `GList` is used to manage lists of symbols and lines of generated code.
3. **Strings**: `GString` is used for string manipulation.

## Key Functions

- **Symbol Table**: The symbol table is implemented using `GHashTable` to store variable names and their types.
- **Buffer Management**: The buffer for generated code is managed using `GList` to store lines and elements.
- **Jump and Conditional Statements**: The project includes functions to handle jump (`JUMP`) and conditional jump (`JMPZ`) statements, fixing their addresses in the generated code.

## Files

1. `project.lex`
2. `project.y`
3. `outputlist.c`
4. `outputlist.h`

Files 3 and 4 contain the main functions for buffer management and code generation. They use GLib for handling dynamic data structures.

## Installation and Compilation

### Prerequisites

1. Install GLib development package:
   ```sh
   sudo apt install libglib2.0-dev
   ```

### Compilation Steps

1. Generate the parser:
   ```sh
   bison -d project.y -o cpl.tab.c
   ```

2. Generate the lexer:
   ```sh
   flex project.lex
   ```

3. Compile the project:
   ```sh
   gcc -o cpl.exe cpl.tab.c outputlist.c lex.yy.c -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -lglib-2.0
   ```

Ensure that the GLib library paths are correctly set in your environment.

## Usage

Run the compiled executable with the input file:
```sh
./cpl.exe <input-file-name>
```

This will generate the output file with the compiled code.
