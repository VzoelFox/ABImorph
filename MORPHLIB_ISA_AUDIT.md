# Morphlib ISA Requirements Audit

**Date:** 2026-01-23
**Current ISA:** v3.1.0
**Status:** ⚠️ CRITICAL FEATURES MISSING

---

## Executive Summary

**morphlib heavily depends on instructions NOT in ISA v3.1.0:**

### 🔴 CRITICAL (Blocking)
1. **`mov [mem], reg`** - Store to memory (used EVERYWHERE)
2. **`push reg`** - Stack operations (used heavily)
3. **`pop reg`** - Stack operations (used heavily)
4. **`sub reg, reg`** - Subtraction (used frequently)

### 🟡 HIGH Priority (Needed soon)
5. **`and reg, reg`** - Bitwise AND
6. **`or reg, reg`** - Bitwise OR
7. **`shl reg, imm`** - Shift left
8. **`shr reg, imm`** - Shift right

### 🟢 NICE TO HAVE (Can workaround)
9. `mul reg` - Multiplication
10. `div reg` - Division
11. `xor reg, reg` - Bitwise XOR
12. `not reg` - Bitwise NOT

---

## Detailed Findings

### 1. Store to Memory (CRITICAL) 🔴

**Usage Count:** 100+ occurrences across morphlib
**Files:** alloc.fox, buffer.fox, morphroutine.fox, daemon.fox, hashmap.fox, io.fox, string.fox

**Examples:**
```fox
# morphroutine.fox:18
mov [rax], rdi          # Store ID to Unit structure

# alloc.fox:45
mov [rbx], rsi          # Store size in allocation header

# buffer.fox:67
mov [rbx], rax          # Store buffer data pointer
```

**Impact:** **BLOCKS ALL MORPHLIB CODE**
- Cannot build data structures
- Cannot write to buffers
- Cannot update state

**ISA Status:** ❌ **NOT IMPLEMENTED**

**Required Encoding:**
```
mov [reg], reg          → REX.W + 0x89 + ModR/M
mov [reg+disp8], reg    → REX.W + 0x89 + ModR/M + disp8
mov [reg+disp32], reg   → REX.W + 0x89 + ModR/M + disp32
```

**Encoding Detail:**
```asm
# mov [rbx+8], rax
REX.W = 0x48            # 64-bit operation
Opcode = 0x89           # MOV r/m64, r64 (vs 0x8B for load)
ModR/M = 0x43           # mod=01, reg=0 (rax), rm=3 (rbx)
Disp8 = 0x08

Machine code: 48 89 43 08
```

---

### 2. PUSH/POP (CRITICAL) 🔴

**Usage Count:** 50+ occurrences
**Files:** alloc.fox, aritmatika.fox, buffer.fox, daemon.fox, hashmap.fox, io.fox, morphroutine.fox, signal.fox, string.fox, sys.fox

**Examples:**
```fox
# alloc.fox:23
push rbx                # Save register

# aritmatika.fox:12
push rax                # Preserve value
sub rax, rsi
pop rax
```

**Impact:** **BLOCKS FUNCTION CALLS WITH STATE**
- Cannot save caller registers
- Cannot pass multiple args to helpers
- Cannot preserve state across calls

**ISA Status:** ❌ **NOT IMPLEMENTED**

**Required Encoding:**
```
push reg    → 0x50 + reg_num (simple!)
pop reg     → 0x58 + reg_num

push rax    → 0x50
push rbx    → 0x53
push r8     → 0x41 0x50  (REX.B + 0x50)
```

**Note:** Requires RSP manipulation (automatic in x86-64)

---

### 3. SUB (HIGH Priority) 🔴

**Usage Count:** 20+ occurrences
**Files:** alloc.fox, aritmatika.fox, buffer.fox, daemon.fox, string.fox

**Examples:**
```fox
# alloc.fox:78
sub rdx, 32             # Calculate available space

# aritmatika.fox:14
sub rax, rsi            # Subtraction operation
```

**Impact:** **BLOCKS ARITHMETIC OPERATIONS**
- Cannot calculate sizes/offsets
- Cannot implement basic math
- Workaround: Use negative ADD (limited)

**ISA Status:** ❌ **NOT IMPLEMENTED**

**Required Encoding:**
```
sub reg, reg    → REX.W + 0x29 + ModR/M
sub reg, imm    → REX.W + 0x81 + ModR/M + imm32

# Same structure as ADD (0x01), just different opcode (0x29)
```

---

### 4. Bitwise Operations (HIGH Priority) 🟡

**AND Usage:** 10+ occurrences
**OR Usage:** 5+ occurrences
**SHL/SHR Usage:** 10+ occurrences

**Examples:**
```fox
# alloc.fox:25
and rdi, -16            # Align to 16 bytes

# aritmatika.fox:24
and rax, rsi            # Bitwise AND

# aritmatika.fox:30
shl rax, 1              # Shift left (multiply by 2)
```

**Impact:** **BLOCKS OPTIMIZATIONS**
- Cannot do alignment
- Cannot do bit manipulation
- Cannot do fast multiply/divide by powers of 2

**ISA Status:** ❌ **NOT IMPLEMENTED**

**Required Encoding:**
```
and reg, reg    → REX.W + 0x21 + ModR/M
and reg, imm    → REX.W + 0x81 + ModR/M(4) + imm32
or reg, reg     → REX.W + 0x09 + ModR/M
xor reg, reg    → REX.W + 0x31 + ModR/M
shl reg, 1      → REX.W + 0xD1 + ModR/M(4)
shl reg, imm8   → REX.W + 0xC1 + ModR/M(4) + imm8
shr reg, 1      → REX.W + 0xD1 + ModR/M(5)
shr reg, imm8   → REX.W + 0xC1 + ModR/M(5) + imm8
```

---

### 5. MUL/DIV (Nice to Have) 🟢

**Usage Count:** Rare (< 5 occurrences)
**Impact:** LOW - Can workaround with repeated ADD

**ISA Status:** ❌ **NOT IMPLEMENTED**

---

## Syscall Usage Audit

### ✅ SUPPORTED (All syscalls work)

**morphlib uses standard syscalls:**
- `sys_read` (rax=0) ✅
- `sys_write` (rax=1) ✅
- `sys_open` (rax=2) ✅
- `sys_close` (rax=3) ✅
- `sys_mmap` (rax=9) ✅
- `sys_munmap` (rax=11) ✅
- `sys_exit` (rax=60) ✅
- Network syscalls (socket, connect, etc.) ✅

**Status:** All syscalls supported via SYSCALL instruction ✅

---

## Memory Operations Audit

### Load (✅ Supported)
```fox
mov rax, [rbx]          ✅ Works
mov rax, [rbx+8]        ✅ Works
mov rax, [rbx+1000]     ✅ Works
```

### Store (❌ MISSING)
```fox
mov [rbx], rax          ❌ NOT IMPLEMENTED
mov [rbx+8], rax        ❌ NOT IMPLEMENTED
mov [rbx+1000], rax     ❌ NOT IMPLEMENTED
```

---

## Priority Implementation Order

### Phase 1: CRITICAL (v3.2 - URGENT)
1. **`mov [mem], reg`** - 2-3 hours
2. **`push reg`** - 1 hour
3. **`pop reg`** - 1 hour
4. **`sub reg, reg`** - 1 hour
5. **`sub reg, imm`** - 30 min

**Total:** ~6 hours
**Impact:** Unblocks 80% of morphlib

### Phase 2: HIGH (v3.3)
6. **`and reg, reg`** - 1 hour
7. **`and reg, imm`** - 30 min
8. **`or reg, reg`** - 1 hour
9. **`xor reg, reg`** - 1 hour
10. **`shl/shr`** - 2 hours

**Total:** ~5.5 hours
**Impact:** Unblocks remaining 15% of morphlib

### Phase 3: NICE (v4.0)
11. **`mul/div`** - 3 hours
12. Other conditional jumps (JNE, JL, JG) - 2 hours
13. LEA instruction - 1 hour

**Total:** ~6 hours
**Impact:** Full morphlib compatibility

---

## Recommendation

**IMMEDIATE ACTION (v3.2):**

Implement Phase 1 (CRITICAL) instructions:
1. Store to memory
2. PUSH/POP
3. SUB

**Estimated Time:** 1 day (6 hours)

**After Phase 1:**
- ✅ morphlib functions will compile
- ✅ Parser can be written in .fox
- ✅ Data structures work
- ✅ Stack-based code works

**Test Strategy:**
1. Implement store: `mov [rbx+8], rax`
2. Test with buffer write
3. Implement push/pop
4. Test with function call preservation
5. Implement sub
6. Test with arithmetic

---

## Code Examples After Implementation

### Example 1: Buffer Allocation (from buffer.fox)
```fox
fungsi buffer_create
    push rbx                    # ✅ After Phase 1
    mov rdi, 24
    call mem_alloc
    mov rbx, rax

    # Initialize buffer fields
    mov [rbx], rdi              # ✅ After Phase 1
    mov [rbx+8], 0              # ✅ After Phase 1

    mov rax, rbx
    pop rbx                     # ✅ After Phase 1
    ret
tutup_fungsi
```

### Example 2: Size Calculation (from alloc.fox)
```fox
fungsi calculate_blocks
    push rbx                    # ✅ After Phase 1
    mov rbx, rdi
    and rbx, -16                # ⚠️ Phase 2
    sub rax, 32                 # ✅ After Phase 1
    pop rbx                     # ✅ After Phase 1
    ret
tutup_fungsi
```

---

## Impact Matrix

| Instruction | Priority | Usage | Files Blocked | Workaround |
|-------------|----------|-------|---------------|------------|
| `mov [mem], reg` | 🔴 CRITICAL | 100+ | ALL | None |
| `push/pop` | 🔴 CRITICAL | 50+ | Most | Manual RSP |
| `sub` | 🔴 CRITICAL | 20+ | Many | Negative ADD |
| `and` | 🟡 HIGH | 10+ | Some | Complex math |
| `or` | 🟡 HIGH | 5+ | Few | Multiple ops |
| `shl/shr` | 🟡 HIGH | 10+ | Some | Repeated ADD |
| `mul/div` | 🟢 LOW | < 5 | Rare | Loops |

---

## Testing Plan

### After Store-to-Memory
```fox
VZOELFOX
mov rax 42
mov [rbx], rax              # Test store
mov rcx [rbx]               # Load back
mov rdi rcx
mov rax 60
syscall
```
**Expected:** Exit 42

### After PUSH/POP
```fox
VZOELFOX
mov rax 42
push rax                    # Test push
mov rax 99
pop rax                     # Should restore 42
mov rdi rax
mov rax 60
syscall
```
**Expected:** Exit 42

### After SUB
```fox
VZOELFOX
mov rax 50
mov rbx 8
sub rax rbx                 # 50 - 8 = 42
mov rdi rax
mov rax 60
syscall
```
**Expected:** Exit 42

---

## Conclusion

**Current ISA v3.1.0:** ⚠️ **INCOMPLETE** for morphlib

**Required for morphlib:** Phase 1 (CRITICAL) instructions

**Action:** Implement store-to-memory, push/pop, sub immediately

**ETA:** 1 day → morphlib compatible

---

**Last Updated:** 2026-01-23
**Next:** Implement Phase 1 instructions

---
