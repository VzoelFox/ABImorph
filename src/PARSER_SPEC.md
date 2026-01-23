# Parser Specification - morphlib → ISA v3.1.0

**Input:** morphlib syntax (.morphlib files)
**Output:** ISA v3.1.0 .fox files
**Implementation:** src/parser.fox

---

## Morphlib Syntax

### Function Definition
```morphlib
fungsi nama_fungsi
    mov rax 42
    kembali rax
tutup_fungsi
```

**Output:**
```fox
nama_fungsi:
    mov rax 42
    ret
```

### Function Call
```morphlib
panggil nama_fungsi
```

**Output:**
```fox
call nama_fungsi
```

### Conditional (Simple)
```morphlib
jika rax rbx sama
    mov rdi 1
tutup_jika
```

**Output:**
```fox
cmp rax rbx
je .L1
jmp .L2
.L1:
    mov rdi 1
.L2:
```

**Note:** JE requires backward refs, so we'll generate labels before conditions.

---

## Built-in Modules

### builtins memory (was: memory+daemo)

**Operations:**
- `memory.alokasi <size>` → Allocate memory via mmap
- `memory.baca <addr> <offset>` → Read from memory (mov reg, [mem])
- `memory.bebas <addr>` → Free memory via munmap

**Implementation:**
```morphlib
# User code
memory.alokasi 1024

# Translates to:
mov rdi 0           # addr = NULL
mov rsi 1024        # length
mov rdx 3           # PROT_READ | PROT_WRITE
mov r10 34          # MAP_PRIVATE | MAP_ANONYMOUS
mov r8 -1           # fd = -1
mov r9 0            # offset = 0
mov rax 9           # SYS_MMAP
syscall
# Result in rax
```

### builtins runtime (was: runtime+morphrountine)

**Operations:**
- `runtime.keluar <code>` → Exit with code
- `runtime.cetak <value>` → Print integer (via write syscall)
- `runtime.debug <reg>` → Debug register value

**Implementation:**
```morphlib
# User code
runtime.keluar 42

# Translates to:
mov rdi 42
mov rax 60          # SYS_EXIT
syscall
```

---

## Parser Architecture

### Memory Layout

```
0x600000 - Input buffer (1MB)
0x700000 - Token array (1MB, 16384 tokens × 64 bytes)
0x800000 - Symbol table (parser-level, 256 entries)
0x900000 - Output buffer (1MB)
0xA00000 - Scratch space (1MB)
```

### Token Structure (64 bytes)

```
[0-7]   Type (1=keyword, 2=ident, 3=number, 4=register)
[8-15]  Length
[16-23] Data pointer
[24-63] Reserved
```

### Parsing Phases

**Phase 1: Tokenize**
- Read input character by character
- Classify tokens (keyword, identifier, number, register)
- Store in token array

**Phase 2: Parse**
- Recognize morphlib patterns (fungsi, panggil, etc.)
- Build symbol table for functions
- Track nesting level

**Phase 3: Code Generation**
- Translate patterns to ISA instructions
- Generate labels for functions
- Emit .fox output

---

## MVP Implementation Strategy

### Stage 1: Single Function Parser (MVP)

**Input:**
```morphlib
VZOELFOX
fungsi test
mov rax 42
kembali rax
tutup_fungsi
```

**Output:**
```fox
VZOELFOX
test:
mov rax 42
ret
```

**Implementation:**
- Simple string matching ("fungsi" → emit label)
- Copy body instructions unchanged
- "kembali" → emit "ret"
- "tutup_fungsi" → skip

### Stage 2: Function Calls

**Input:**
```morphlib
fungsi add_ten
    mov rax 32
    add rax 10
    kembali rax
tutup_fungsi

fungsi main
    panggil add_ten
    mov rdi rax
    runtime.keluar rdi
tutup_fungsi
```

**Output:**
```fox
add_ten:
    mov rax 32
    add rax 10
    ret

main:
    call add_ten
    mov rdi rax
    mov rax 60
    syscall
```

### Stage 3: Built-ins

Expand "runtime.keluar", "memory.alokasi" to syscall sequences.

### Stage 4: Conditionals

Handle "jika ... tutup_jika" with label generation (backward refs only).

---

## Parser Implementation (src/parser.fox)

### Structure

```fox
VZOELFOX

# === Helper Functions (defined first for backward refs) ===

tokenize:
    # Tokenization logic
    ret

parse:
    # Parsing logic
    ret

codegen:
    # Code generation logic
    ret

emit_label:
    # Emit "name:"
    ret

emit_instruction:
    # Emit ISA instruction
    ret

# === Main Entry Point ===

main:
    # Setup memory regions
    call setup_memory

    # Read input file
    call read_input

    # Phase 1: Tokenize
    call tokenize

    # Phase 2: Parse
    call parse

    # Phase 3: Generate code
    call codegen

    # Write output
    call write_output

    # Exit
    mov rax 60
    mov rdi 0
    syscall
```

### Constraints (from ISA v3.1.0)

**Working:**
- ✅ CALL backward refs (define functions before main)
- ✅ JMP forward/backward refs
- ✅ JE backward refs only
- ✅ MOV, ADD, CMP
- ✅ Memory load (mov reg, [mem])

**Not Working:**
- ❌ JE forward refs (define labels before use)
- ❌ Store to memory (use registers only)
- ❌ SUB, MUL, DIV
- ❌ Bitwise ops

**Workaround Strategy:**
- Define all functions first
- Define conditional labels before JE
- Use register-based state machines
- No complex data structures (limited memory ops)

---

## Example Transformations

### Example 1: Simple Function

**Input:**
```morphlib
fungsi tambah_sepuluh
    mov rax 32
    add rax 10
    kembali rax
tutup_fungsi
```

**Output:**
```fox
tambah_sepuluh:
    mov rax 32
    add rax 10
    ret
```

### Example 2: Function with Call

**Input:**
```morphlib
fungsi helper
    mov rax 10
    kembali rax
tutup_fungsi

fungsi main
    panggil helper
    mov rdi rax
    kembali rdi
tutup_fungsi
```

**Output:**
```fox
helper:
    mov rax 10
    ret

main:
    call helper
    mov rdi rax
    ret
```

### Example 3: Built-in Runtime

**Input:**
```morphlib
fungsi main
    mov rax 42
    runtime.keluar rax
tutup_fungsi
```

**Output:**
```fox
main:
    mov rax 42
    mov rdi rax
    mov rax 60
    syscall
```

### Example 4: Built-in Memory

**Input:**
```morphlib
fungsi main
    memory.alokasi 4096
    mov rbx rax
    runtime.keluar 0
tutup_fungsi
```

**Output:**
```fox
main:
    mov rdi 0
    mov rsi 4096
    mov rdx 3
    mov r10 34
    mov r8 -1
    mov r9 0
    mov rax 9
    syscall
    mov rbx rax
    mov rdi 0
    mov rax 60
    syscall
```

---

## Limitations (MVP)

**Not Implementing (Yet):**
- Nested functions
- Local variables
- Complex conditionals (if/else/elif)
- Loops (while, for)
- String literals
- Arrays
- Type checking
- Error recovery

**Focus:**
- Single-pass parsing
- Simple pattern matching
- Direct translation
- Proof of concept

---

## Testing Strategy

### Test 1: Empty Program
```morphlib
VZOELFOX
```
**Expected:** `VZOELFOX` only

### Test 2: Single Function
```morphlib
VZOELFOX
fungsi test
mov rax 42
kembali rax
tutup_fungsi
```
**Expected:** Function with ret

### Test 3: Function Call
```morphlib
VZOELFOX
fungsi f
ret
tutup_fungsi

fungsi main
panggil f
tutup_fungsi
```
**Expected:** Two functions with call

### Test 4: Runtime Built-in
```morphlib
VZOELFOX
fungsi main
runtime.keluar 42
tutup_fungsi
```
**Expected:** Syscall expansion

---

## Next Steps

1. ✅ Write parser spec (this file)
2. ⬜ Implement tokenizer in parser.fox
3. ⬜ Implement parser state machine
4. ⬜ Implement code generator
5. ⬜ Test with simple morphlib programs
6. ⬜ Add built-in support (runtime, memory)
7. ⬜ Add conditional support (jika)

---

**Status:** Design Complete
**Next:** Implement src/parser.fox

---
