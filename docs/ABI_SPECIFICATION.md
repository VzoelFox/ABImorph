# Morph ABI Specification v1.0

**Document Version:** 1.0.0
**Date:** 2026-01-22
**Status:** STABLE

Complete Application Binary Interface specification for Morph ecosystem.

## Table of Contents

1. [Binary Format](#1-binary-format)
2. [Calling Convention](#2-calling-convention)
3. [Memory Model](#3-memory-model)
4. [System Interface](#4-system-interface)
5. [Exception Handling](#5-exception-handling)
6. [Instruction Encoding](#6-instruction-encoding)

---

## 1. Binary Format

### 1.1 ELF64 Structure

Morph generates standard ELF64 executables compatible with Linux x86-64.

**ELF Header (64 bytes @ 0x400000):**
```
Offset  Size  Field              Value
------  ----  -----              -----
0x00    4     e_ident[EI_MAG]    0x7F 'E' 'L' 'F'
0x04    1     e_ident[EI_CLASS]  2 (ELFCLASS64)
0x05    1     e_ident[EI_DATA]   1 (ELFDATA2LSB)
0x06    1     e_ident[EI_VERSION] 1 (EV_CURRENT)
0x07    1     e_ident[EI_OSABI]  0 (ELFOSABI_SYSV)
0x08-0x0F     e_ident[EI_PAD]    0 (padding)
0x10    2     e_type             2 (ET_EXEC)
0x12    2     e_machine          62 (EM_X86_64)
0x14    4     e_version          1
0x18    8     e_entry            0x400078
0x20    8     e_phoff            64 (program header offset)
0x28    8     e_shoff            0 (no section headers)
0x30    4     e_flags            0
0x34    2     e_ehsize           64
0x36    2     e_phentsize        56
0x38    2     e_phnum            1
0x3A    2     e_shentsize        0
0x3C    2     e_shnum            0
0x3E    2     e_shstrndx         0
```

**Program Header (56 bytes @ 0x400040):**
```
Offset  Size  Field      Value
------  ----  -----      -----
0x00    4     p_type     1 (PT_LOAD)
0x04    4     p_flags    5 (PF_R | PF_X)
0x08    8     p_offset   0
0x10    8     p_vaddr    0x400000
0x18    8     p_paddr    0x400000
0x20    8     p_filesz   (total file size)
0x28    8     p_memsz    (total file size)
0x30    8     p_align    0x1000 (4KB)
```

**Code Section:**
```
Entry Point: 0x400078
Contains: Generated machine code
Terminator: syscall exit (rax=60, rdi=0)
```

### 1.2 Memory Mapping

**Virtual Address Space:**
```
0x400000 - 0x4FFFFF    Executable segment (1MB)
  0x400000 - 0x400077  ELF headers
  0x400078 - ...       Generated code
```

**Stack:**
- Provided by kernel at program start
- Initial stack pointer in rsp
- Grows downward from high memory
- 16-byte aligned

---

## 2. Calling Convention

### 2.1 Function Call Protocol

**System V AMD64 ABI**

**Integer/Pointer Arguments:**
```
Position  Register  Notes
--------  --------  -----
1         rdi       First argument
2         rsi       Second argument
3         rdx       Third argument
4         rcx       Fourth argument
5         r8        Fifth argument
6         r9        Sixth argument
7+        stack     Push right-to-left
```

**Return Values:**
```
Type              Register
----              --------
Integer (64-bit)  rax
Pointer           rax
```

**Register Usage:**
```
Volatile (caller-saved):
  rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11

Non-volatile (callee-saved):
  rbx, rbp, r12, r13, r14, r15

Reserved:
  rsp (stack pointer)
```

### 2.2 Stack Frame

**Before Call:**
```
Stack aligned to 16-byte boundary
Arguments 7+ pushed right-to-left
Return address pushed by 'call' instruction
```

**Frame Layout:**
```
High Address
  +----------------+
  | Arg N          |
  | ...            |
  | Arg 7          |
  +----------------+
  | Return Address | <- Pushed by 'call'
  +----------------+ <- rsp after call
  | Saved RBP      | <- Optional frame pointer
  +----------------+
  | Local Vars     |
  +----------------+
  | ...            |
Low Address
```

### 2.3 Function Prologue/Epilogue

**Standard Prologue:**
```asm
push rbp           ; Save frame pointer
mov rbp, rsp       ; Set new frame pointer
sub rsp, N         ; Allocate N bytes locals
```

**Standard Epilogue:**
```asm
leave              ; mov rsp, rbp; pop rbp
ret                ; Pop return address and jump
```

---

## 3. Memory Model

### 3.1 Data Types

**Primitive Types:**
```
Type      Size    Alignment
----      ----    ---------
byte      1       1
word      2       2
dword     4       4
qword     8       8
pointer   8       8
```

### 3.2 Alignment Rules

**Structure Alignment:**
- Members aligned to their natural boundary
- Structure aligned to largest member
- Padding inserted as needed

**Stack Alignment:**
- 16-byte alignment before 'call'
- Maintained throughout execution

---

## 4. System Interface

### 4.1 System Call Convention

**Linux x86-64 Syscall ABI:**

**Registers:**
```
Register  Purpose
--------  -------
rax       Syscall number
rdi       Argument 1
rsi       Argument 2
rdx       Argument 3
r10       Argument 4
r8        Argument 5
r9        Argument 6
```

**Invocation:**
```asm
mov rax, syscall_number
mov rdi, arg1
; ... set other args
syscall
; Return value in rax
```

**Return:**
- Success: rax >= 0 (return value)
- Error: rax = -errno (negative)

### 4.2 Standard Syscalls

**I/O Operations:**
```
Number  Name         Signature
------  ----         ---------
0       sys_read     (fd, buf, count) -> bytes_read
1       sys_write    (fd, buf, count) -> bytes_written
2       sys_open     (filename, flags, mode) -> fd
3       sys_close    (fd) -> status
```

**Memory:**
```
9       sys_mmap     (addr, len, prot, flags, fd, off) -> ptr
11      sys_munmap   (addr, len) -> status
```

**Process:**
```
60      sys_exit     (status) -> never returns
```

### 4.3 Standard Library Functions

**Built-in seer.* functions:**

```asm
; Print Functions
seer.print.text    ; (rdi: str_ptr) -> void
seer.print.int     ; (rdi: value) -> void
seer.print.hex     ; (rdi: value) -> void
seer.print.nl      ; () -> void
seer.print.raw     ; (rdi: buf, rsi: len) -> void

; String Functions
seer.string.len         ; (rdi: str) -> rax: length
seer.string.equals      ; (rdi: str1, rsi: str2) -> rax: bool
seer.string.equals_len  ; (rdi: str1, rsi: str2, rdx: len) -> rax: bool
seer.string.copy        ; (rdi: dest, rsi: src) -> void
```

---

## 5. Exception Handling

**No exception handling** - Programs exit on error.

**Error Handling:**
- Syscall errors: Check rax for negative values
- Program errors: Exit with non-zero status
- Signals: Default kernel behavior

---

## 6. Instruction Encoding

### 6.1 Token Format

**Source Format (.fox):**
```
<mnemonic>.<operand_type_1>.<operand_type_2>
```

**Operand Types:**
```
r64        64-bit register
r32        32-bit register
r16        16-bit register
r8         8-bit register
mem        Memory operand
imm64      64-bit immediate
imm32      32-bit immediate
imm16      16-bit immediate
imm8       8-bit immediate
rel32      32-bit relative offset
```

**Examples:**
```
add.r64.r64        ; Add r64 to r64
mov.r64.imm64      ; Move imm64 to r64
mov.r64.mem        ; Move memory to r64
jmp.rel32          ; Jump relative 32-bit
```

### 6.2 Machine Code Generation

**Generated by compiler:**
- REX prefix (when needed)
- Opcode bytes
- ModR/M byte (when needed)
- SIB byte (when needed)
- Displacement (when needed)
- Immediate (when needed)

**Example:**
```
Source:  add.r64.r64
Output:  0x48 0x01 0xD8  (REX.W + ADD + ModR/M[rax,rbx])
```

---

## 7. Versioning

**ABI Version:** 1.0.0

**Compatibility:**
- Binary-level compatibility guaranteed within major version
- Minor version updates: backward compatible additions
- Major version updates: may break compatibility

**Version Encoding:**
```
Binary contains magic: VZOELFOX
No version field in binary (ABI is implicit)
```

---

## 8. Compiler Interface

### 8.1 morph Compiler

**Command Line:**
```bash
morph [options] <input.fox>
```

**Options:**
```
(none)           JIT execute
-o <output>      Compile to binary
```

**Exit Codes:**
```
0     Success
1     Error (compilation or execution)
139   Segmentation fault (internal error)
```

### 8.2 Input File Format

**Magic Header:** "VZOELFOX" (8 bytes)
**Content:** Whitespace-separated instruction tokens
**Encoding:** ASCII text
**Terminator:** Not required

---

## Appendix A: Register Reference

**General Purpose (64-bit):**
```
rax, rbx, rcx, rdx, rsi, rdi, rbp, rsp
r8, r9, r10, r11, r12, r13, r14, r15
```

**32-bit views:**
```
eax, ebx, ecx, edx, esi, edi, ebp, esp
r8d, r9d, r10d, r11d, r12d, r13d, r14d, r15d
```

**16-bit views:**
```
ax, bx, cx, dx, si, di, bp, sp
r8w, r9w, r10w, r11w, r12w, r13w, r14w, r15w
```

**8-bit views:**
```
al, bl, cl, dl, sil, dil, bpl, spl
r8b, r9b, r10b, r11b, r12b, r13b, r14b, r15b
```

---

## Appendix B: Syscall Numbers

See `/usr/include/asm/unistd_64.h` for complete list.

---

**Document End**
