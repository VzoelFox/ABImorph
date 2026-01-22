# ABImorph v1.1.0 - Known Limitations

**Version:** 1.1.0
**Status:** Stable (with limitations)
**Target:** v2.0.0 will address these limitations

---

## ⚠️ CRITICAL LIMITATIONS

### 1. **NO OPERAND ENCODING**

**Impact:** HIGH - Severely limits usability

**Description:**
The current `morph` binary **does NOT encode register names, immediate values, or memory operands**. It only emits raw opcodes.

**What This Means:**

```fox
# ❌ DOES NOT WORK
mov.r64.r64 rax rbx    # Operands ignored!

# ✅ WORKS (but incomplete)
mov.r64.r64            # Only emits opcode (0x89)
                       # Missing: Which registers?
```

**Generated Code:**
```
Input:  add.r64.r64
Output: 0x01           (ADD opcode only)
        Missing: REX prefix (0x48)
        Missing: ModR/M byte (which registers?)
```

**Consequence:**
- Instructions execute with **undefined register operands**
- Behavior is **unpredictable** and **incorrect**
- Only works by accident if registers happen to be in expected state

**Workaround:** None. Wait for v2.0.0.

**Status:** 🔴 **BLOCKER** for production use

---

### 2. **NO IMMEDIATE VALUE SUPPORT**

**Impact:** HIGH

**Description:**
Cannot specify immediate values (constants) in instructions.

```fox
# ❌ DOES NOT WORK
mov.r64.imm64 rax 42       # Immediate value ignored
add.r64.imm32 rbx 100      # Immediate value ignored

# ✅ WORKS (but useless without operands)
mov.r64.imm64              # Emits opcode only
```

**Consequence:**
- Cannot load constants into registers
- Cannot perform arithmetic with constants
- Cannot set up function arguments
- Cannot initialize variables

**Workaround:** None. Values must be pre-loaded via external means.

**Status:** 🔴 **BLOCKER** for any real program

---

### 3. **NO MEMORY ADDRESSING**

**Impact:** HIGH

**Description:**
Cannot specify memory operands or addressing modes.

```fox
# ❌ DOES NOT WORK
mov.r64.mem rax [rbx+8]    # Memory addressing ignored
lea.r64.mem rsi [rip+offset]
push.mem [rsp+16]

# ✅ WORKS (opcode only)
mov.r64.mem                # Emits opcode, no addressing
```

**Consequence:**
- Cannot access memory
- Cannot load from stack
- Cannot access data structures
- Cannot use pointers

**Workaround:** None.

**Status:** 🔴 **BLOCKER** for memory operations

---

### 4. **morphlib CANNOT BE COMPILED**

**Impact:** HIGH - Library is reference-only

**Description:**
All morphlib modules use **high-level syntax** (`fungsi`, `tutup_fungsi`) which current `morph` binary **DOES NOT SUPPORT**.

```fox
# morphlib/alloc.fox uses:
fungsi mem_alloc          # ❌ NOT SUPPORTED
    mov rdi, 1024
    call sys_brk
    ret
tutup_fungsi              # ❌ NOT SUPPORTED
```

**Consequence:**
- morphlib is **documentation only**
- Cannot use standard library functions
- Must write everything from scratch in low-level ISA

**Workaround:** Copy-paste and manually convert to low-level syntax (labels).

**Status:** 🟡 **LIMITATION** - Library unusable

---

### 5. **LIMITED ISA COVERAGE**

**Impact:** MEDIUM

**What Works:**
```fox
✅ Instruction mnemonics only:
   add.r64.r64
   mov.r64.mem
   jmp.rel32
   call.rel32
   ret
   nop
```

**What Doesn't Work:**
```fox
❌ Register names: rax, rbx, rcx, ...
❌ Immediate values: 0, 42, 0xFF, ...
❌ Memory syntax: [rax], [rip+8], ...
❌ Labels: main:, loop_start:
❌ Directives: .data, .text, .section
❌ High-level: fungsi, jika, loop
```

**Consequence:**
- Must write extremely low-level code
- No symbolic names
- Hard to maintain
- Prone to errors

**Status:** 🟡 **BY DESIGN** (v1.x is low-level foundation)

---

### 6. **PRINT FUNCTIONS LIMITED**

**Impact:** LOW - Debugging affected

**Description:**
- `seer.print.int` outputs **hexadecimal** (not decimal)
- Simplified to avoid decimal conversion bugs

```
Input:  42
Output: 0x000000000000002A  (not "42")
```

**Workaround:** Use `seer.print.hex` directly (same result).

**Status:** 🟢 **KNOWN ISSUE** - Fixed in v2.0.0

---

### 7. **SEGFAULT ON COMPILE MODE EXIT**

**Impact:** LOW - Cosmetic only

**Description:**
After successfully compiling a binary with `-o`, loader segfaults during cleanup.

```bash
./bin/morph -o output input.fox
# Output: output (created successfully, works perfectly)
# Segmentation fault  <- Happens AFTER success
```

**Important:** Binary output is **complete and functional**. Segfault happens **after** successful write.

**Consequence:**
- Annoying error message
- Scripts may interpret as failure
- No data loss (binary already written)

**Workaround:** Ignore segfault. Check if output file exists and is executable.

**Status:** 🟢 **KNOWN ISSUE** - Non-critical, fixed in v2.0.0

---

### 8. **NO LABEL SUPPORT**

**Impact:** MEDIUM

**Description:**
Cannot define or reference labels.

```fox
# ❌ DOES NOT WORK
main:
    call helper
    ret

helper:
    nop
    ret
```

**Consequence:**
- Cannot structure code with functions
- Cannot use loops with labels
- Must rely on absolute instruction ordering

**Workaround:** Magic header provides entry point (0x400078).

**Status:** 🟡 **LIMITATION** - v2.0.0 feature

---

### 9. **NO RELOCATION/LINKING**

**Impact:** MEDIUM

**Description:**
Generated binaries are **statically positioned** at address 0x400000.

**Consequence:**
- Cannot link multiple object files
- Cannot create shared libraries
- Cannot use position-independent code
- One .fox file = one binary

**Workaround:** None. Single-file compilation only.

**Status:** 🟡 **BY DESIGN** (v1.x is simple compiler)

---

### 10. **X86-64 LINUX ONLY**

**Impact:** MEDIUM - Platform limitation

**Description:**
Only supports:
- Architecture: x86-64 (AMD64)
- OS: Linux (kernel 3.0+)
- Binary format: ELF64

**Does NOT Support:**
- ARM, ARM64, RISC-V
- Windows (PE format)
- macOS (Mach-O format)
- FreeBSD, OpenBSD (different syscalls)

**Workaround:** Cross-compilation for other platforms in v2.0.0+.

**Status:** 🟡 **BY DESIGN** (v1.x is Linux/x86-64 foundation)

---

## 📊 Summary Table

| Limitation | Impact | Status | v2.0.0 |
|------------|--------|--------|--------|
| No operand encoding | 🔴 HIGH | Blocker | ✅ Fixed |
| No immediate values | 🔴 HIGH | Blocker | ✅ Fixed |
| No memory addressing | 🔴 HIGH | Blocker | ✅ Fixed |
| morphlib unusable | 🟡 MEDIUM | Limitation | ✅ Fixed |
| Limited ISA | 🟡 MEDIUM | By design | ✅ Extended |
| Print functions | 🟢 LOW | Known issue | ✅ Fixed |
| Compile segfault | 🟢 LOW | Cosmetic | ✅ Fixed |
| No labels | 🟡 MEDIUM | Limitation | ✅ Added |
| No linking | 🟡 MEDIUM | By design | ⏳ Future |
| Linux x86-64 only | 🟡 MEDIUM | By design | ⏳ Future |

---

## 🎯 What CAN You Do With v1.1.0?

**Limited but functional use cases:**

### ✅ **Test ISA Instruction Encoding**
```fox
VZOELFOX
nop
ret
```
Useful for verifying opcode generation.

### ✅ **Binary Format Validation**
Check that ELF64 structure is correct:
```bash
./bin/morph -o test.morph test.fox
file test.morph
objdump -h test.morph
```

### ✅ **Learning Low-Level Concepts**
Study how instructions become machine code (without proper encoding yet).

### ✅ **morphlib as Documentation**
Reference implementation for:
- Memory allocator design
- Runtime architecture
- System call patterns
- Data structure implementations

---

## 🚫 What You CANNOT Do

### ❌ **Write Real Programs**
No operands = no functionality.

### ❌ **Use morphlib**
High-level syntax not supported.

### ❌ **Implement Algorithms**
Cannot move data or perform calculations without operands.

### ❌ **Create Useful Binaries**
Generated code executes with undefined behavior.

### ❌ **Production Deployment**
Not suitable for any production use.

---

## 📋 Recommended Actions

### For Users:
1. **DO NOT use for production**
2. **DO NOT expect morphlib to work**
3. **USE for education/research only**
4. **WAIT for v2.0.0** for usable compiler

### For Developers:
1. **Study morphlib source** as reference
2. **Test ISA definitions** in spec/Brainlib/
3. **Contribute to v2.0.0** development
4. **Report bugs** for non-limitation issues

---

## 🔮 v2.0.0 Roadmap

See [ROADMAP.md](ROADMAP.md) for complete v2.0.0 feature plan.

**Key improvements:**
- ✅ Full operand encoding (registers, immediates, memory)
- ✅ Label support
- ✅ High-level syntax compilation
- ✅ morphlib becomes usable
- ✅ Proper error handling
- ✅ Comprehensive testing

**ETA:** TBD (requires 20-30 hours development)

---

## 📞 Support

**Questions about limitations:** Read this document first.
**Bug reports (non-limitations):** https://github.com/VzoelFox/ABImorph/issues
**Feature requests for v2.0.0:** https://github.com/VzoelFox/ABImorph/discussions

---

**Last Updated:** 2026-01-22
**Version:** 1.1.0-final
