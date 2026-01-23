# Morphlib Features & Requirements

**Date:** 2026-01-23
**Purpose:** Document morphlib-specific features for ISA implementation

---

## 🔮 Magic Numbers

### 1. MORPHSNP (Snapshot Header)
**Value:** `0x504E534850524F4D` (Little Endian)
**ASCII:** "MORPHSNP"
**Usage:** Snapshot file format header
**File:** `snapshot.fox`

```fox
; Snapshot file structure:
; [0-7]   Magic: MORPHSNP (0x504E534850524F4D)
; [8-15]  Heap Size (bytes)
; [16+]   Heap Data (r15 ... brk)
```

### 2. Memory Allocation Magic
**Value:** `28062004`
**Usage:** Heap block verification
**File:** `alloc.fox`

```fox
; Allocation header (32 bytes):
; [0-7]   Size (payload size in bytes)
; [8-15]  Status (1=Used, 0=Free)
; [16-23] Magic (28062004) ← Corruption detection
; [24-31] Padding
```

**Purpose:** Detect heap corruption before reading block metadata.

---

## 🏗️ Memory Architecture

### Global Heap Register
**r15 = Heap Root**
- Reserved globally across all morphlib code
- Never modified after `heap_init`
- All allocations relative to r15

### Heap Layout
```
r15 → [Header 32B][Payload][Header 32B][Payload]... → brk
```

### Allocation Strategy
1. **First-fit** - Traverse from r15, find first free block ≥ size
2. **Reuse** - Free blocks marked Status=0, can be reused
3. **Expand** - If no fit, extend heap via `sys_brk`

---

## 🔄 Memory Management Modules

### 1. daemon.fox - Active Memory Monitor
**Role:** Garbage Collection replacement via signal-based monitoring

**Features:**
- SIGALRM handler checks memory usage every interval
- Threshold: 10 MB (configurable)
- **Circuit Breaker:** If exceeded → snapshot + exit(999)

**Key Operations:**
```fox
daemon_handler:
    # Check: (brk - r15) > threshold?
    sub rbx, r15            # Used size
    cmp rbx, 10485760       # 10 MB threshold
    jika_diatas
        call snapshot_save  # Emergency dump
        call sys_exit       # Controlled crash
    tutup_jika
```

### 2. snapshot.fox - Heap Serialization
**Role:** Save/restore entire heap to disk

**Operations:**
- `snapshot_save(filename)` → Write heap to file
- `snapshot_load(filename)` → Restore heap from file

**File Format:**
```
[Magic: MORPHSNP (8B)]
[Size: bytes (8B)]
[Data: heap contents (Size bytes)]
```

### 3. sandbox.fox - Isolated Execution
**Role:** Execute code with resource limits (TODO: check file)

### 4. swap.fox - Disk-backed Memory
**Role:** Swap heap segments to disk when low memory (TODO: check file)

---

## 🎯 Morphlib Syntax Extensions

### Conditionals
```fox
jika_sama           # if equal (ZF=1)
jika_beda           # if not equal (ZF=0)
jika_diatas         # if above (unsigned >)
jika_diatas_sama    # if above or equal (unsigned ≥)
jika_negatif        # if negative (SF=1)
tutup_jika          # end if
```

**Translation to ISA:**
```fox
# morphlib:
jika_sama
    mov rax 1
tutup_jika

# ISA v3.1.0:
je .L1
jmp .L2
.L1:
    mov rax 1
.L2:
```

### Loops
```fox
loop nama
    # body
    henti           # break
tutup_loop
```

**Translation to ISA:**
```fox
# morphlib:
loop search
    cmp rax rbx
    jika_sama
        henti
    tutup_jika
tutup_loop

# ISA v3.1.0:
.loop_search:
    cmp rax rbx
    je .loop_search_end
    jmp .loop_search
.loop_search_end:
```

### Functions
```fox
fungsi nama
    # body
    ret
tutup_fungsi
```

**Translation to ISA:**
```fox
# morphlib:
fungsi add_ten
    add rax 10
    ret
tutup_fungsi

# ISA v3.1.0:
add_ten:
    add rax 10
    ret
```

---

## 📦 Required ISA Instructions (Priority Order)

### Phase 1: CRITICAL (v3.2) - 6 hours
1. ✅ `mov [mem], reg` - Store to memory (100+ uses)
2. ✅ `push reg` - Stack ops (50+ uses)
3. ✅ `pop reg` - Stack ops (50+ uses)
4. ✅ `sub reg, reg/imm` - Arithmetic (20+ uses)

**Why Critical:**
- Store: Cannot write headers, cannot build structures
- Push/Pop: Cannot save state across calls
- Sub: Cannot calculate sizes/offsets

### Phase 2: HIGH (v3.3) - 5 hours
5. ⬜ `and reg, reg/imm` - Alignment (10+ uses)
6. ⬜ `or reg, reg` - Bit manipulation (5+ uses)
7. ⬜ `xor reg, reg` - Clear register idiom
8. ⬜ `shl/shr reg, imm` - Shifts (10+ uses)

**Why High:**
- And: Alignment calculations (`and rdi, -16`)
- Shifts: Fast multiply/divide by powers of 2

### Phase 3: MEDIUM (v3.4) - 3 hours
9. ⬜ `jne/jl/jg/jle/jge` - More conditionals
10. ⬜ `test reg, reg` - Bit testing
11. ⬜ `lea reg, [mem]` - Address calculation

### Phase 4: LOW (v4.0) - 3 hours
12. ⬜ `mul/div` - Arithmetic
13. ⬜ `not reg` - Bitwise NOT
14. ⬜ `inc/dec reg` - Increment/decrement

---

## 🧪 Test Cases After Implementation

### Test 1: Magic Number Verification
```fox
VZOELFOX
jmp main

check_magic:
    mov r10 rdi
    add r10 16
    mov rax [r10]           # Load magic
    mov rdx 28062004
    cmp rax rdx
    je valid
    mov rdi 666
    mov rax 60
    syscall
valid:
    ret

main:
    # Allocate memory
    mov rdi 0
    mov rsi 65536
    mov rdx 3
    mov r10 34
    mov r8 -1
    mov r9 0
    mov rax 9
    syscall

    # Write magic
    mov rbx rax
    add rbx 16
    mov rcx 28062004
    mov [rbx] rcx           # ← Store magic

    # Verify
    mov rdi rax
    call check_magic

    # Success
    mov rax 60
    mov rdi 0
    syscall
```
**Expected:** Exit 0 (magic valid)

### Test 2: Allocation Header
```fox
VZOELFOX
# Create allocation header
mov rdi 0
mov rsi 65536
mov rdx 3
mov r10 34
mov r8 -1
mov r9 0
mov rax 9
syscall

mov rbx rax

# Write header
mov rcx 1024
mov [rbx] rcx           # Size = 1024

mov rcx 1
mov r10 rbx
add r10 8
mov [r10] rcx           # Status = 1 (Used)

mov rcx 28062004
add r10 8
mov [r10] rcx           # Magic = 28062004

# Read back and verify
mov rax [rbx]           # Load size
mov rdi rax
mov rax 60
syscall
```
**Expected:** Exit 1024 (size read correctly)

### Test 3: Stack Operations
```fox
VZOELFOX
mov rax 42
mov rbx 99
push rax
push rbx
pop rcx         # rcx = 99
pop rdx         # rdx = 42
sub rcx rdx     # 99 - 42 = 57
mov rdi rcx
mov rax 60
syscall
```
**Expected:** Exit 57

---

## 🎨 Morphlib Design Philosophy

### 1. No Traditional GC
**Instead:** daemon.fox with active monitoring
- Signal-based memory checks
- Circuit breaker on threshold
- Emergency snapshot before crash

### 2. Explicit Memory Management
**Pattern:**
```fox
fungsi process_data
    push rbx
    mov rdi 1024
    call mem_alloc      # Allocate
    mov rbx rax

    # Use memory...

    mov rdi rbx
    call mem_free       # Explicit free
    pop rbx
    ret
tutup_fungsi
```

### 3. Heap Introspection
**All metadata in-band:**
- Headers before each allocation
- Magic numbers for validation
- Status tracking for reuse
- Snapshot-able entire heap

### 4. Register Conventions
**Reserved:**
- r15 = Heap Root (never modified)
- r14 = (available)
- r13 = (available)
- r12 = (available)

**Caller-saved:** rax, rcx, rdx, rdi, rsi, r8-r11
**Callee-saved:** rbx, rbp, r12-r15

---

## 📊 Instruction Usage Statistics

| Instruction | Count | Priority | Status |
|-------------|-------|----------|--------|
| mov [mem], reg | 100+ | 🔴 CRITICAL | ❌ Missing |
| push reg | 50+ | 🔴 CRITICAL | ❌ Missing |
| pop reg | 50+ | 🔴 CRITICAL | ❌ Missing |
| sub reg, reg | 20+ | 🔴 CRITICAL | ❌ Missing |
| and reg, imm | 10+ | 🟡 HIGH | ❌ Missing |
| add reg, reg | 20+ | ✅ DONE | ✅ v3.1.0 |
| mov reg, [mem] | 50+ | ✅ DONE | ✅ v3.1.0 |
| call label | 30+ | ✅ DONE | ✅ v3.1.0 |
| cmp reg, reg | 15+ | ✅ DONE | ✅ v3.1.0 |
| je label | 10+ | ✅ DONE | ✅ v3.1.0 |

---

## 🚀 Implementation Plan

### Today (Phase 1)
1. ✅ Audit morphlib requirements (this file)
2. ⬜ Implement `mov [mem], reg` (2 hours)
3. ⬜ Implement `push reg` (1 hour)
4. ⬜ Implement `pop reg` (1 hour)
5. ⬜ Implement `sub reg, reg/imm` (1 hour)
6. ⬜ Test with morphlib snippets (1 hour)

**Total:** 6 hours → morphlib functional

### Tomorrow (Phase 2)
7. ⬜ Implement bitwise ops (and, or, xor, shl, shr)
8. ⬜ Test with alloc.fox alignment code
9. ⬜ Full morphlib compilation test

### Week 2 (Phase 3+)
10. ⬜ Parser.fox using morphlib syntax
11. ⬜ Self-hosting test
12. ⬜ Bootstrap complete

---

**Last Updated:** 2026-01-23
**Next:** Implement store-to-memory

---
