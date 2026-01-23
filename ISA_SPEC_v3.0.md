# Morph ISA Specification v3.0

**Version:** 3.0.0-control-flow
**Date:** 2026-01-23
**Status:** RELEASED

---

## Philosophy: Code Honesty

**Every ISA instruction maps 1:1 to x86-64 machine code.**

No abstractions, no magic. Just direct assembly primitives.

---

## Instruction Set

### Data Movement

**MOV reg, reg** - Register to register
```fox
mov rax rbx    → 48 89 d8  (REX.W + 0x89 + ModR/M)
mov r8 r9      → 4d 89 c8  (REX.WRB + 0x89 + ModR/M)
```

**MOV reg, imm** - Immediate to register
```fox
mov rax 42     → 48 c7 c0 2a 00 00 00  (REX.W + MOV r64, imm32)
mov rdi 0xFF   → 48 c7 c7 ff 00 00 00
```

**MOV reg, [mem]** - Load from memory
```fox
mov rax [rbx]      → 48 8b 03        (direct)
mov rax [rbx+8]    → 48 8b 43 08     (disp8)
mov r8 [r9+16]     → 4d 8b 41 10     (extended regs)
```

### Arithmetic

**ADD reg, reg** - Add registers
```fox
add rax rbx    → 48 01 d8  (REX.W + 0x01 + ModR/M)
add r8 r9      → 4d 01 c8
```

**CMP reg, reg** - Compare registers (sets FLAGS)
```fox
cmp rax rbx    → 48 39 d8  (REX.W + 0x39 + ModR/M)
cmp r8 r9      → 4d 39 c8
```

### Control Flow

**JMP label** - Unconditional jump
```fox
jmp target     → e9 [rel32]  (relative offset calculated)
```
- Forward references supported via fixup system
- Backward references calculated immediately

**JE label** - Jump if equal (ZF=1)
```fox
je target      → 0f 84 [rel32]
```
- Checks zero flag from previous CMP
- Forward/backward references supported

**CALL label** - Function call (NOT YET IMPLEMENTED)
```fox
call function  → e8 [rel32]  (planned for v3.1)
```

### System

**SYSCALL** - System call
```fox
syscall        → 0f 05
```

**RET** - Return from function
```fox
ret            → c3
```

**NOP** - No operation
```fox
nop            → 90
```

---

## Operand Types

### Registers (64-bit)

**General Purpose:**
- `rax`, `rbx`, `rcx`, `rdx` (basic)
- `rsi`, `rdi`, `rsp`, `rbp` (basic)
- `r8`, `r9`, `r10`, `r11` (extended)
- `r12`, `r13`, `r14`, `r15` (extended)

**Encoding:**
- Basic regs (rax-rbp): Register number 0-7
- Extended regs (r8-r15): Register number 8-15, require REX.R/REX.B

### Immediates

**Decimal:**
```fox
mov rax 42
mov rdi 255
```

**Hexadecimal:**
```fox
mov rax 0xFF
mov rbx 0x1000
```

**Auto-sizing:**
- Small values (-128 to 127): imm8
- Medium values: imm32 (sign-extended to 64-bit)

### Memory Addressing

**Direct:**
```fox
mov rax [rbx]       # [reg]
```

**Displacement:**
```fox
mov rax [rbx+8]     # [reg + disp8]
mov rax [rbx+1000]  # [reg + disp32]
```

**Extended registers:**
```fox
mov r8 [r9+16]      # Requires REX.RB encoding
```

---

## Labels

**Definition:**
```fox
label_name:
    mov rax 42
```

**Usage:**
```fox
jmp label_name
je label_name
```

**Forward References:**
- Supported via fixup system
- Label can be used before definition
- Compiler patches offset after label is defined

**Symbol Table:**
- 256 label entries max
- 32 bytes per entry
- Stores: name_ptr, name_len, address, resolved flag

**Fixup System:**
- 256 fixup entries max
- Tracks forward reference locations
- Applied after compilation completes
- Supports: rel8, rel32, abs64

---

## File Format

**Header:**
```
VZOELFOX
```

**Body:**
```fox
label:
    instruction operand1 operand2
    instruction operand
    ...
```

**Example:**
```fox
VZOELFOX
main:
    mov rax 10
    mov rbx 20
    add rax rbx
    mov rdi rax
    mov rax 60
    syscall
```

---

## REX Prefix Encoding

**Format:** `0100WRXB` (0x40-0x4F)

**Bits:**
- W=1: 64-bit operand size
- R=1: Extension of ModR/M reg field
- X=1: Extension of SIB index field (unused)
- B=1: Extension of ModR/M r/m field or SIB base field

**Examples:**
```
0x48 = 0100 1000 → W=1, R=0, X=0, B=0 (basic 64-bit)
0x49 = 0100 1001 → W=1, R=0, X=0, B=1 (dest is r8-r15)
0x4C = 0100 1100 → W=1, R=1, X=0, B=0 (src is r8-r15)
0x4D = 0100 1101 → W=1, R=1, X=0, B=1 (both extended)
```

---

## ModR/M Byte Encoding

**Format:** `[mod(2)][reg(3)][r/m(3)]`

**mod field:**
- 00: [reg] (direct)
- 01: [reg + disp8]
- 10: [reg + disp32]
- 11: register-to-register

**reg field:**
- Source register for most instructions
- 3 bits (0-7), extended by REX.R

**r/m field:**
- Destination register or memory base
- 3 bits (0-7), extended by REX.B

**Examples:**
```
mov rax, rbx:
  mod=11 (reg-to-reg), reg=3 (rbx), r/m=0 (rax)
  ModR/M = 11 011 000 = 0xD8

mov rax, [rbx+8]:
  mod=01 (disp8), reg=0 (rax), r/m=3 (rbx)
  ModR/M = 01 000 011 = 0x43
```

---

## Not Implemented (Future)

### v3.1 Planned:
- `mov [mem], reg` - Store to memory
- `call label` - Function calls with stack frame
- `sub`, `mul`, `div` - More arithmetic
- `and`, `or`, `xor` - Bitwise operations
- `shl`, `shr` - Shifts

### v3.2+ Planned:
- `jne`, `jl`, `jg`, `jle`, `jge` - More conditional jumps
- `push`, `pop` - Stack operations
- `lea` - Load effective address
- Comments (`;`) in .fox files

---

## Limitations

### Current (v3.0):
- **No CALL yet** - Inline functions or wait for v3.1
- **No store to memory** - Can only load
- **No stack ops** - Use memory addressing instead
- **Limited arithmetic** - Only ADD and CMP
- **No comments** - .fox files must be pure instructions

### By Design:
- **No macros** - Keep ISA minimal
- **No type system** - This is assembly
- **No safety** - You can segfault
- **No stdlib** - Use syscalls directly

---

## Version History

**v3.0.0-control-flow (2026-01-23):**
- ✅ Added: JMP, JE, CMP instructions
- ✅ Added: Label support with forward references
- ✅ Added: Symbol table (256 entries)
- ✅ Added: Fixup system for forward refs
- Binary size: 48KB

**v2.0.0-bootstrap (2026-01-23):**
- ✅ Full operand encoding (REX + ModR/M)
- ✅ Immediate values with auto-sizing
- ✅ Memory addressing (load only)
- ✅ Extended registers (r8-r15)
- Binary size: 32KB

**v1.1.0-final:**
- ⚠️ Broken operand encoding
- ⚠️ Segfaults after compilation
- ❌ Unusable

---

## Example Programs

### Hello Exit Code
```fox
VZOELFOX
mov rax 60
mov rdi 42
syscall
```

### Addition
```fox
VZOELFOX
mov rax 10
mov rbx 20
add rax rbx
mov rdi rax
mov rax 60
syscall
```

### Conditional Jump
```fox
VZOELFOX
mov rax 5
mov rbx 5
cmp rax rbx
je equal
mov rdi 99
mov rax 60
syscall
equal:
mov rdi 42
mov rax 60
syscall
```

### Loop (Inline with Jump)
```fox
VZOELFOX
mov r8 0
loop_start:
add r8 1
mov r9 r8
cmp r9 10
je done
jmp loop_start
done:
mov rdi r8
mov rax 60
syscall
```

---

## Compiler Information

**Binary:** `/root/ABImorph/bin/morph`
**Size:** 48,649 bytes (48KB)
**Platform:** Linux x86-64
**Dependencies:** None (statically linked)

**Usage:**
```bash
# JIT mode (execute immediately)
./bin/morph program.fox

# Compile mode (save binary)
./bin/morph -o output program.fox
./output
```

---

## Code Honesty Guarantee

**Every instruction in this ISA:**
1. Maps directly to x86-64 machine code
2. Has no hidden behavior
3. Does exactly what assembly does
4. Is fully transparent

**No magic, no abstractions, no surprises.**

---

**ISA Frozen:** Yes (until v4.0 major revision)
**License:** MIT
**Maintainer:** VzoelFox

---
