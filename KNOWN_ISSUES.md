# Known Issues - Morph Compiler v3.1.0

**Version:** 3.1.0-control-flow
**Date:** 2026-01-23
**Binary:** bin/morph (48,826 bytes)

This document tracks known limitations, bugs, and workarounds for the current Morph compiler.

---

## 🐛 Active Bugs

### 1. JE Forward Reference Not Working

**Severity:** Medium
**Status:** Known, Workaround Available

**Description:**
Conditional jump (JE) with forward references does not jump correctly. The label is added to symbol table and fixup is attempted, but offset calculation or application fails.

**Affected:**
- `je label` where label is defined AFTER the jump

**Not Affected:**
- `je label` where label is defined BEFORE the jump (backward ref) ✅
- `jmp label` forward/backward refs ✅
- `call label` forward/backward refs ✅

**Test Case:**
```fox
VZOELFOX
mov rax 5
mov rbx 5
cmp rax rbx
je equal        # ← FAILS (forward ref)
mov rdi 99
mov rax 60
syscall
equal:
mov rdi 42
mov rax 60
syscall
```
**Result:** Exit code 99 (should be 42)

**Workaround:**
Define labels before using them:
```fox
VZOELFOX
equal:
mov rdi 42
mov rax 60
syscall
start:
mov rax 5
mov rbx 5
cmp rax rbx
je equal        # ← WORKS (backward ref)
mov rdi 99
mov rax 60
syscall
```
**Result:** Exit code 42 ✅

**Root Cause:**
- String comparison in symbol table lookup works
- Fixup system applies correctly for JMP/CALL
- Likely issue with JE-specific offset calculation (6 bytes vs 5 bytes)
- Fixup entry may be created with wrong code offset

**Priority:** Medium - Parser can work around by ordering code appropriately

---

## ⚠️ Limitations (By Design)

### 1. No CALL Stack Frame Management

**Description:**
CALL instruction emits raw x86-64 `call` (0xE8) which pushes return address to stack. There is NO automatic stack frame setup (push rbp, mov rbp rsp, etc.).

**Impact:**
- Functions must manage their own stack if needed
- Local variables require manual stack allocation
- No automatic register preservation

**Example:**
```fox
func:
    # NO automatic: push rbp; mov rbp, rsp
    mov rax 42
    ret
    # NO automatic: leave
```

**Workaround:**
Manually manage stack in functions that need it:
```fox
func:
    push rbp
    mov rbp rsp
    # function body
    leave
    ret
```

---

### 2. No Store to Memory

**Description:**
Memory addressing only supports LOAD operations. Cannot store to memory.

**Supported:**
```fox
mov rax [rbx+8]     # Load ✅
```

**Not Supported:**
```fox
mov [rbx+8] rax     # Store ❌
```

**Workaround:**
Use registers for all data manipulation. Store operations planned for v3.2.

---

### 3. Limited Conditional Jumps

**Description:**
Only JE (jump if equal) is implemented.

**Supported:**
- `je label` - Jump if ZF=1 (equal)

**Not Supported:**
- `jne label` - Jump if not equal
- `jl label` - Jump if less
- `jg label` - Jump if greater
- `jle`, `jge`, etc.

**Workaround:**
Restructure logic to use JE only:
```fox
# Want: jne skip
# Workaround: je continue; jmp skip; continue:

cmp rax rbx
je continue
jmp skip
continue:
# code to skip
skip:
```

**Planned:** v3.2 will add JNE, JL, JG, JLE, JGE

---

### 4. No Comments in .fox Files

**Description:**
Parser does not support comments. Any non-instruction text causes errors.

**Not Supported:**
```fox
mov rax 42    # this is a comment ❌
; comment line ❌
// comment ❌
```

**Workaround:**
Use external documentation. Comments in .fox planned for v4.0.

---

### 5. No Arithmetic Beyond ADD

**Description:**
Only ADD instruction implemented for arithmetic.

**Supported:**
```fox
add rax rbx     # Addition ✅
```

**Not Supported:**
```fox
sub rax rbx     # Subtraction ❌
mul rax         # Multiplication ❌
div rbx         # Division ❌
```

**Workaround:**
For subtraction, use negative immediates (limited):
```fox
add rax -10     # Subtract 10 (if immediate encoding supports)
```

**Planned:** SUB, MUL, DIV in v3.2

---

### 6. No Bitwise Operations

**Description:**
No AND, OR, XOR, NOT, shifts, or rotates.

**Not Supported:**
```fox
and rax rbx     # Bitwise AND ❌
or rax rbx      # Bitwise OR ❌
xor rax rax     # XOR (common idiom) ❌
shl rax 2       # Shift left ❌
```

**Workaround:**
Use ADD for some bit manipulation (very limited).

**Planned:** Bitwise ops in v3.3

---

### 7. No Stack Operations Beyond CALL/RET

**Description:**
No PUSH/POP instructions.

**Not Supported:**
```fox
push rax        # ❌
pop rbx         # ❌
```

**Workaround:**
Manually adjust RSP and use MOV:
```fox
# push rax equivalent:
add rsp -8
mov [rsp] rax   # But store not supported! ❌

# BLOCKED until store-to-memory is implemented
```

**Planned:** PUSH/POP in v3.2 (requires store-to-memory first)

---

### 8. No 32-bit or 8/16-bit Operations

**Description:**
All operations are 64-bit only (REX.W=1).

**Not Supported:**
```fox
mov eax ebx     # 32-bit ❌
mov al bl       # 8-bit ❌
mov ax bx       # 16-bit ❌
```

**Workaround:**
Use 64-bit registers and mask/truncate as needed (manual bitwise ops required, which also not supported!).

**Planned:** Multi-size operations in v4.0 (major revision)

---

### 9. Limited Immediate Sizes

**Description:**
Immediates are sign-extended imm32 (max 2^31-1).

**Supported:**
```fox
mov rax 42              # Small values ✅
mov rax 0xFF            # Hex values ✅
mov rax 2147483647      # Max imm32 ✅
```

**Not Supported:**
```fox
mov rax 0x8000000000000000   # Full 64-bit ❌ (overflow)
```

**Workaround:**
For large 64-bit values, build them in parts (requires bitwise ops, not yet implemented).

**Planned:** Full imm64 support in v4.0

---

## 📋 Test Results Summary

### ✅ Working (Tested)

| Test | Description | Status |
|------|-------------|--------|
| `test_imm_only.fox` | Immediate values | ✅ Exit 42 |
| `test_label_only.fox` | Label definition | ✅ Exit 42 |
| `test_jmp_simple.fox` | JMP forward ref (1-char label) | ✅ Exit 42 |
| `test_forward_simple.fox` | JMP forward ref (long label) | ✅ Exit 42 |
| `test_call_backward_debug.fox` | CALL backward ref | ✅ Exit 42 |
| `test_call_forward_simple.fox` | CALL forward ref | ✅ Exit 0 |
| `test_je_backward.fox` | JE backward ref | ✅ Exit 42 |
| `test_backward_cmp.fox` | CMP instruction | ✅ Exit 1 |

### ❌ Failing (Known Issues)

| Test | Description | Expected | Actual | Status |
|------|-------------|----------|--------|--------|
| `test_je_simple.fox` | JE forward ref (long label) | Exit 42 | Exit 99 | Bug #1 |
| `test_je_short.fox` | JE forward ref (1-char label) | Exit 42 | Exit 99 | Bug #1 |
| `test_call_imm.fox` | CALL with immediate in func | Exit 42 | Exit 255 | Unknown |

---

## 🔧 Workaround Strategies

### For Parser Implementation

**Recommended Code Structure:**
```fox
VZOELFOX

# 1. Define all functions first (backward refs for CALL)
tokenize:
    # tokenizer code
    ret

parse:
    # parser code
    ret

codegen:
    # codegen code
    ret

# 2. Define helper functions
helper1:
    ret

# 3. Main calls everything (backward refs work perfectly)
main:
    call tokenize
    call parse
    call codegen
    mov rax 60
    syscall

# 4. For JE, define labels BEFORE jump
loop_start:
    # loop body
    cmp rax rbx
    je loop_start    # Backward ref ✅
```

**Key Principles:**
- ✅ Define functions before calling them
- ✅ Define labels before conditional jumps
- ✅ Use backward references for all control flow
- ❌ Avoid forward references with JE

---

## 📊 Binary Information

**File:** `bin/morph`
**Size:** 48,826 bytes (48KB)
**Format:** ELF64 executable
**Platform:** Linux x86-64
**Dependencies:** None (statically linked)

**Compilation:**
```bash
cd /root/vzlfx
./build_v3.sh
# Output: morph_v3 (48KB)
```

---

## 🗓️ Planned Fixes

### v3.2 (Next Minor Release)
- [ ] Fix JE forward reference bug
- [ ] Add store-to-memory (mov [mem], reg)
- [ ] Add SUB, MUL, DIV arithmetic
- [ ] Add JNE, JL, JG conditional jumps
- [ ] Add PUSH/POP stack operations

### v3.3
- [ ] Add bitwise operations (AND, OR, XOR, NOT, SHL, SHR)
- [ ] Add LEA (load effective address)
- [ ] Optimize fixup system performance

### v4.0 (Major Revision)
- [ ] Multi-size operations (8/16/32/64-bit)
- [ ] Full imm64 support
- [ ] Comment support in .fox files
- [ ] Better error messages with line numbers
- [ ] Optimization passes

---

## 📞 Reporting Issues

If you find a bug not listed here:

1. Create minimal test case (.fox file)
2. Document expected vs actual behavior
3. Report to: https://github.com/VzoelFox/ABImorph/issues

**Before Reporting:**
- Check this document for known issues
- Test with backward references (workaround)
- Verify you're using v3.1.0 binary

---

## ✅ Current Capabilities Summary

**What Works Well:**
- Basic arithmetic (ADD)
- Register-to-register moves
- Immediate values
- Memory loads
- Labels and symbol table
- JMP (forward/backward)
- CALL (forward/backward)
- JE (backward only)
- CMP instruction
- SYSCALL, RET, NOP

**What's Limited:**
- JE forward refs (Bug #1)
- No store-to-memory
- No SUB/MUL/DIV
- No bitwise ops
- No PUSH/POP
- No JNE/JL/JG

**Overall Assessment:**
Sufficient for building parsers and simple compilers with proper code organization (backward refs). Production-ready for bootstrap phase.

---

**Last Updated:** 2026-01-23
**Maintainer:** VzoelFox
**License:** MIT

---
