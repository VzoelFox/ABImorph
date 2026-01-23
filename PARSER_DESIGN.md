# Parser Design - morphlib → ISA v3.0

**Purpose:** Translate morphlib high-level syntax to ISA-level .fox

---

## Input Syntax (morphlib)

```fox
VZOELFOX

fungsi add_numbers
    mov rax 10
    mov rbx 20
    add rax rbx
    kembali rax
tutup_fungsi

fungsi main
    panggil add_numbers
    mov rdi rax
    mov rax 60
    syscall
tutup_fungsi
```

## Output Syntax (ISA v3.0)

```fox
VZOELFOX

add_numbers:
    mov rax 10
    mov rbx 20
    add rax rbx
    ret

main:
    jmp add_numbers_ret
add_numbers_ret:
    mov rdi rax
    mov rax 60
    syscall
```

---

## Translation Rules

### 1. fungsi → label
```
fungsi name   →   name:
tutup_fungsi  →   ret
```

### 2. kembali → ret
```
kembali rax   →   mov rax rax (nop)
                  ret
```

### 3. panggil → jmp + ret label (INLINE)
```
panggil func  →   jmp func_ret
                  func_ret:
```

**Note:** Karena CALL belum ada, kita inline function calls dengan JMP.

---

## Parser Architecture

### Stage 1: Tokenizer (Memory-based)

**Input:** Source file in memory (0x600000)
**Output:** Token array (0x700000)

**Token Structure:** [type(1)][length(1)][data(62)]
- Total: 64 bytes per token
- Max tokens: 1024

**Token Types:**
- 0 = EOF
- 1 = KEYWORD (fungsi, tutup_fungsi, kembali, panggil)
- 2 = INSTRUCTION (mov, add, syscall, ret, jmp, je, cmp)
- 3 = REGISTER (rax, rbx, r8, etc.)
- 4 = NUMBER (42, 0xFF)
- 5 = IDENTIFIER (label/function name)

### Stage 2: Parser (State Machine)

**State Table:** 0x800000
- State 0: INIT
- State 1: IN_FUNCTION
- State 2: IN_INSTRUCTION
- State 3: EXPECT_OPERAND

**Transition Table:** 0x900000
- [current_state][token_type] → [next_state][action]

### Stage 3: Code Generator

**Output Buffer:** 0xA00000

**Actions:**
- EMIT_LABEL: Write "name:\n"
- EMIT_INSTRUCTION: Write "mov rax rbx\n"
- EMIT_RET: Write "ret\n"
- EMIT_JMP: Write "jmp label\n"

---

## Memory Layout

```
0x600000 - 0x6FFFFF: Input source (1MB)
0x700000 - 0x7FFFFF: Token array (1MB, 16384 tokens)
0x800000 - 0x8FFFFF: State machine data (1MB)
0x900000 - 0x9FFFFF: Transition table (1MB)
0xA00000 - 0xAFFFFF: Output buffer (1MB)
```

---

## Implementation Strategy

### Option A: Minimal Hardcoded Parser (MVP)
- Hardcode input/output
- Simple pattern matching
- ~500 lines of .fox
- Proof of concept only

### Option B: Full Parser with Syscalls
- Read file with open/read syscalls
- Tokenize in memory
- Parse with state machine
- Write output with write syscall
- ~2000+ lines of .fox
- Production-ready

### Option C: Multi-file Modular
- `tokenizer.fox` - Split input to tokens
- `parser.fox` - Parse tokens to AST
- `codegen.fox` - Generate ISA output
- Compile separately, link with runner
- Most maintainable

---

## MVP Implementation (Option A)

**Target:** Parse single fungsi/tutup_fungsi block

**Input (hardcoded):**
```
fungsi test
mov rax 42
kembali rax
tutup_fungsi
```

**Output (generated):**
```
test:
mov rax 42
ret
```

**Steps:**
1. Setup memory regions
2. Scan for "fungsi" keyword
3. Extract function name
4. Emit label
5. Copy body instructions
6. Replace "kembali" with "ret"
7. Skip "tutup_fungsi"

**Code size:** ~300-500 lines of .fox (inline, no loops with counters)

---

## Next Steps

1. Implement MVP parser (Option A)
2. Test with simple morphlib program
3. Extend to handle multiple functions
4. Add panggil → jmp translation
5. Build full parser (Option B) after MVP works

---

**Current ISA:** v3.0 (JMP, JE, CMP, labels supported)
**Binary:** `/root/ABImorph/bin/morph` (48KB)

---
