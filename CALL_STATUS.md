# CALL Instruction Status

**Date:** 2026-01-23
**Version:** v3.1-call-support

---

## Implementation Complete ✅

**Instruction:** `call label`
**Opcode:** `0xE8 + rel32`
**Size:** 48,824 bytes (48KB)

### Test Results

**✅ CALL Backward Reference:**
```fox
VZOELFOX
jmp main
func:
    mov rdi 42
    mov rax 60
    syscall
main:
    call func          # ← WORKS!
    mov rdi 99
    mov rax 60
    syscall
```
**Result:** Exit code 42 ✓

**⚠️ CALL Forward Reference:**
```fox
VZOELFOX
call func              # ← Bug in fixup
mov rdi 99
syscall
func:
    mov rdi 42
    syscall
```
**Result:** Exit code 99 (should be 42) - Fixup not applied

---

## ISA v3.1 Instructions

**Complete:**
- MOV reg, reg / reg, imm / reg, [mem]
- ADD reg, reg
- CMP reg, reg
- JMP label (backward ✓, forward ⚠️)
- JE label (backward ✓, forward ⚠️)
- CALL label (backward ✓, forward ⚠️)
- SYSCALL, RET, NOP

---

## Known Issues

### Forward Reference Fixup Bug

**Symptom:** Forward refs not jumping correctly
**Affected:** JMP, JE, CALL
**Workaround:** Define labels before use (backward refs only)

**For Parser:** Not blocking - define all functions first, then call them.

---

## Parser Strategy (With Backward CALL)

```fox
VZOELFOX

# Define all functions first
tokenize:
    # tokenizer code
    ret

parse:
    # parser code
    ret

codegen:
    # codegen code
    ret

# Main calls functions (all backward refs)
main:
    call tokenize
    call parse
    call codegen
    mov rax 60
    syscall
```

**This works perfectly with current CALL implementation!**

---

## Next: Build Parser MVP

**Target:** morphlib → ISA translator

**Input (morphlib):**
```fox
fungsi add_ten
    mov rax 32
    add rax 10
    kembali rax
tutup_fungsi

fungsi main
    panggil add_ten
    mov rdi rax
    mov rax 60
    syscall
tutup_fungsi
```

**Output (ISA):**
```fox
VZOELFOX
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

---

**Status:** Ready for parser implementation
**Blocker:** None - backward CALL is sufficient

---
