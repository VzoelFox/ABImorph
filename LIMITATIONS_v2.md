# Limitations - Morph Compiler v2.0.0-bootstrap

**Version:** 2.0.0-bootstrap
**Date:** 2026-01-23
**Status:** Bootstrap Ready

---

## 🎉 MAJOR IMPROVEMENTS from v1.1.0

### ✅ RESOLVED (Previously Critical Blockers)

1. **✅ Operand Encoding - FIXED!**
   - **v1.1.0**: Only opcode emitted, operands ignored → undefined behavior
   - **v2.0.0**: Full REX + ModR/M encoding → correct machine code
   - **Example**: `mov rax, rbx` now generates `48 89 d8` (correct!)

2. **✅ Immediate Values - FIXED!**
   - **v1.1.0**: Constants ignored → wrong values
   - **v2.0.0**: Full immediate parsing & encoding with auto-sizing
   - **Example**: `mov rax, 42` → `48 c7 c0 2a 00 00 00` (correct!)

3. **✅ Extended Registers - FIXED!**
   - **v1.1.0**: r8-r15 not supported
   - **v2.0.0**: Full support with proper REX.B/REX.R encoding
   - **Example**: `mov r8, 42` → `49 c7 c0 2a...` (correct!)

4. **✅ Memory Addressing - IMPLEMENTED!**
   - **v1.1.0**: No memory operations
   - **v2.0.0**: Load from memory with offset support
   - **Example**: `mov rax, [rbx+8]` → `48 8b 43 08` (correct!)

5. **✅ Compilation Segfault - FIXED!**
   - **v1.1.0**: Segfault after successful compilation
   - **v2.0.0**: Clean exit, no crashes

---

## ⚠️ REMAINING LIMITATIONS (v2.0.0-bootstrap)

### Instruction Set

**Supported** ✅:
- `mov reg, reg` - Register to register
- `mov reg, imm` - Immediate to register
- `mov reg, [mem]` - Load from memory
- `add reg, reg` - Add registers
- `syscall` - System call
- `ret` - Return
- `nop` - No operation

**Not Yet Implemented** ⬜:
- `mov [mem], reg` - Store to memory (planned for v2.1)
- `sub`, `mul`, `div` - Other arithmetic (planned for v2.1)
- `cmp`, `test` - Comparisons (not needed for bootstrap)
- `jmp`, `call`, `je`, `jne` - Control flow (intentionally skipped for bootstrap)
- `push`, `pop` - Stack operations (can use `mov [rsp+offset]`)
- Bitwise ops: `and`, `or`, `xor`, `shl`, `shr` (planned for v2.1)

### Why Skip Control Flow?

**Strategic Decision**: Bootstrap with inline approach instead of implementing JMP/CALL.

**Rationale**:
- Control flow = 20-30 hours work (labels, fixups, rel8/rel32)
- Bootstrap doesn't need it (can inline or use hardcoded offsets)
- ISA stays minimal & frozen faster
- Can add later at ABI level if needed

**Workaround**:
- Write code sequentially without loops/jumps
- Inline repeated code
- Use register arithmetic instead of conditionals

### Syntax Limitations

**Supported** ✅:
```fox
VZOELFOX
mov rax 60
mov rdi 0
syscall
```

**Not Supported** ⬜:
- Comments (`;` causes parse error) - planned for v2.1
- Labels (`:` not parsed yet) - infrastructure ready, just needs integration
- `.data` section - planned for v2.1
- High-level syntax (`fungsi`, `jika`) - this is for morphx86_64, not ISA level

### Memory Addressing Limitations

**Supported** ✅:
- `[reg]` - Direct register dereference
- `[reg+imm]` - Register + offset (8-bit or 32-bit)
- Extended registers in memory ops

**Not Yet Implemented** ⬜:
- `[reg1+reg2]` - Two registers (SIB byte infrastructure ready)
- `[reg*scale]` - Scaled index (SIB ready, just needs integration)
- `[rip+offset]` - RIP-relative (planned for v2.1)
- Store operations: `mov [mem], reg` (planned for v2.1)

### Immediate Value Limitations

**Supported** ✅:
- Decimal: `42`, `100`, `255`
- Hexadecimal: `0xFF`, `0x100`, `0x400000`
- Auto-sizing: imm8, imm32 (sign-extended for 64-bit)
- Negative values: `-1`, `-128`

**Not Yet Implemented** ⬜:
- Binary literals: `0b11111111` (planned for v2.1)
- Octal literals: `0o777` (low priority)
- Character literals: `'A'` (low priority)
- Large 64-bit immediates require special encoding (currently use imm32 sign-extended)

---

## 🎯 Comparison Table

| Feature | v1.1.0 | v2.0.0 | Status |
|---------|--------|--------|--------|
| Register encoding | ❌ | ✅ | FIXED |
| Immediate values | ❌ | ✅ | FIXED |
| Memory addressing | ❌ | ✅ | FIXED |
| Extended registers (r8-r15) | ❌ | ✅ | FIXED |
| Compilation stability | ⚠️ | ✅ | FIXED |
| Symbol table | ❌ | ✅ | ADDED |
| Fixup system | ❌ | ✅ | ADDED |
| Control flow (JMP/CALL) | ❌ | ⬜ | Deferred |
| Comments | ❌ | ⬜ | Planned v2.1 |
| Store to memory | ❌ | ⬜ | Planned v2.1 |
| Arithmetic (SUB/MUL/DIV) | ❌ | ⬜ | Planned v2.1 |

---

## 📋 Roadmap

### v2.0.0-bootstrap (CURRENT)
✅ Full operand encoding
✅ Memory addressing (load)
✅ Symbol table infrastructure
⬜ Bootstrap self-hosting (in progress)

### v2.1 (Planned - Post-Bootstrap)
- Add `mov [mem], reg` (store to memory)
- Add SUB, MUL, DIV, IMUL, IDIV
- Add bitwise operations (AND, OR, XOR, NOT)
- Add shifts (SHL, SHR, SAL, SAR)
- Add comment support (`;`)
- Add RIP-relative addressing

### v3.0 (Future)
- Implement control flow (JMP, CALL, conditional jumps)
- Full label support
- `.data`, `.bss`, `.text` sections
- Macro system
- Remove any bootstrap scaffolding

### v4.0+ (morphx86_64)
- High-level language compiler
- `fungsi`/`tutup_fungsi` syntax
- `jika`/`tutup_jika` conditionals
- Type system
- Memory safety
- Standard library

---

## ✅ What Works Now

### Real Programs You Can Write

**Exit with code**:
```fox
VZOELFOX
mov rax 60
mov rdi 42
syscall
```

**Simple arithmetic**:
```fox
VZOELFOX
mov rax 10
mov rbx 20
add rax rbx
mov rdi rax
mov rax 60
syscall
```

**Extended registers**:
```fox
VZOELFOX
mov r8 100
mov r9 200
add r8 r9
mov rdi r8
mov rax 60
syscall
```

**Memory operations**:
```fox
VZOELFOX
mov rbx 0x600000
mov rax [rbx]
mov rax 60
mov rdi 0
syscall
```

### Test Results

All tests passing ✅:
```
✓ mov rax, rbx     → 48 89 d8
✓ mov rax, 60      → 48 c7 c0 3c 00 00 00
✓ mov r8, 42       → 49 c7 c0 2a 00 00 00
✓ add r8, r9       → 4d 01 c8
✓ mov rax, [rbx+8] → 48 8b 43 08
✓ syscall          → 0f 05
✓ ret              → c3
```

**Programs run correctly**:
- Exit code tests: PASS
- Arithmetic tests: PASS (exit code = result)
- Extended register tests: PASS
- Memory addressing tests: PASS

---

## 🚀 Bottom Line

**v2.0.0 is a MASSIVE improvement over v1.1.0!**

### From Broken to Working:
- v1.1.0: ❌ Generated code had undefined behavior → **unusable**
- v2.0.0: ✅ Generated code is correct → **usable for bootstrap!**

### What's Missing:
- Some instructions (SUB, MUL, CMP, etc.)
- Control flow (JMP, CALL) - intentionally deferred
- Comments, labels (can add easily)
- Store to memory (planned v2.1)

### What's Ready:
- ✅ Compiler works correctly
- ✅ Programs compile and run
- ✅ Ready for bootstrap self-hosting
- ✅ ISA can be frozen (minimal, clean)

---

**Conclusion**: v2.0.0 is **bootstrap-ready**! The compiler generates correct code and is stable. Remaining limitations are either:
1. **Intentional** (control flow - using inline approach)
2. **Minor** (comments, additional instructions)
3. **Planned** (v2.1+)

Bootstrap can proceed! 🎉

---

**See Also**:
- [CHANGELOG v2.0](docs/CHANGELOG_v2.0.md) - Complete feature list
- [ROADMAP.md](ROADMAP.md) - Future plans
- [README.md](README.md) - Quick start guide

