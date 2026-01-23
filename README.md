# ABImorph - Morph ABI Specification & Binary Distribution

**Version:** 3.1.0-control-flow
**Release Date:** 2026-01-23
**Status:** CONTROL FLOW READY 🚀

Official ABI specification, binary distribution, and standard library for the Morph programming ecosystem.

---

## 🎉 NEW in v3.1.0: CONTROL FLOW!

### ✅ **Major Features**

**v3.1.0 now supports**:
- ✅ **Control Flow** - JMP, CALL, JE (conditional jumps)!
- ✅ **Labels** - Forward and backward references with fixup system
- ✅ **Function Calls** - CALL/RET for modular code
- ✅ **Comparisons** - CMP instruction with conditional jumps
- ✅ **Full operand encoding** - Registers, immediates, memory addressing
- ✅ **Register operations** - All GPRs (rax-r15) with proper REX encoding
- ✅ **Immediate values** - Decimal (42) and hexadecimal (0xFF) with auto-sizing
- ✅ **Memory addressing** - Load from memory: `mov rax, [rbx+8]`
- ✅ **Extended registers** - r8-r15 fully supported

**What this means:** You can now write complex parsers and compilers with proper control flow!

**See:** [ISA_SPEC_v3.0.md](ISA_SPEC_v3.0.md) for complete instruction reference.

**Status:** Ready for parser implementation 🚀

---

## Overview

ABImorph provides:
- **Binary Distribution** - Ready-to-use `morph` compiler (v3.1.0, 48KB)
- **Control Flow** - JMP, CALL, JE with label support
- **Full Operand Encoding** - Registers, immediates, memory addressing
- **ABI Specification** - Complete calling convention and binary format
- **ISA Reference** - Full instruction set architecture documentation (ISA_SPEC_v3.0.md)
- **Symbol Table & Fixups** - Forward/backward reference support
- **Documentation** - Complete guides for development

## Quick Start

```bash
# Download binary
git clone https://github.com/VzoelFox/ABImorph.git
cd ABImorph

# Compile a simple program
cat > hello.fox << 'EOF'
VZOELFOX
mov rax 1
mov rdi 1
mov rsi 0x600000
mov rdx 13
syscall
mov rax 60
mov rdi 0
syscall
EOF

./bin/morph -o hello hello.fox
./hello
```

**What works now:**
```fox
VZOELFOX
mov rax 60        # Immediate values
mov rdi 42        # Exit code
add rax rbx       # Register operations
mov r8 100        # Extended registers
mov rax [rbx+8]   # Memory addressing
syscall           # System calls
```

## Binary Distribution

### Compiler: `morph`

**Location:** `bin/morph`
**Size:** 30KB
**Platform:** Linux x86-64
**Dependencies:** None (statically linked)

**Features:**
- Native x86-64 code generation
- JIT execution mode
- ELF64 binary output
- Zero runtime dependencies

**Usage:**
```bash
# JIT execution (development)
./bin/morph program.fox

# Compile to native binary (production)
./bin/morph -o output program.fox
./output
```

## ABI Specification

### 1. Binary Format

**Output Format:** ELF64 (Executable and Linkable Format)
```
Magic:        0x7F 'E' 'L' 'F'
Class:        ELFCLASS64 (64-bit)
Data:         ELFDATA2LSB (little-endian)
OS/ABI:       SYSV (Linux)
Type:         ET_EXEC (executable)
Machine:      EM_X86_64 (AMD x86-64)
Entry Point:  0x400078
```

**Memory Layout:**
```
0x400000        ELF Header (64 bytes)
0x400040        Program Header (56 bytes)
0x400078        Code Entry Point
0x400078 + N    Generated code
```

### 2. Calling Convention

**Standard:** System V AMD64 ABI

**Function Parameters:**
```
1st arg:  rdi
2nd arg:  rsi
3rd arg:  rdx
4th arg:  rcx
5th arg:  r8
6th arg:  r9
7+ args:  stack (right-to-left)
```

**Return Value:**
```
Integer/Pointer: rax
Floating Point:  xmm0
```

**Register Preservation:**
```
Caller-saved: rax, rcx, rdx, rsi, rdi, r8-r11
Callee-saved: rbx, rbp, r12-r15
```

**Stack Alignment:** 16-byte boundary before `call`

### 3. System Calls

**Interface:** Direct Linux syscalls (no libc)

**Common Syscalls:**
```
rax = syscall number
rdi = arg1
rsi = arg2
rdx = arg3
r10 = arg4
r8  = arg5
r9  = arg6
syscall instruction
```

**Standard Syscalls:**
```
0   sys_read
1   sys_write
2   sys_open
3   sys_close
9   sys_mmap
60  sys_exit
```

### 4. File Format (.fox)

**Structure:**
```
Offset  Content
------  -------
0-7     Magic: "VZOELFOX" (8 bytes)
8+      Instruction tokens (whitespace-separated)
```

**Example:**
```
VZOELFOX
nop
mov.r64.imm64
add.r64.r64
ret
```

**Token Format:**
```
Instruction format: <mnemonic>.<operand1>.<operand2>
Example: add.r64.r64  (add register64 to register64)
```

## ISA Reference

**Location:** `spec/Brainlib/`

### Instruction Categories

**Arithmetic:** `spec/Brainlib/aritmatika.json`
- add, sub, mul, div, imul, idiv
- inc, dec, neg
- adc, sbb (with carry)

**Logic:** `spec/Brainlib/logika.json`
- and, or, xor, not
- shl, shr, sal, sar, rol, ror

**Control Flow:** `spec/Brainlib/kontrol.json`
- cmp, test
- jmp, je, jne, jl, jg, jle, jge
- call, ret
- nop

**Data Movement:** `spec/Brainlib/data.json`
- mov (register, memory, immediate)
- lea (load effective address)
- push, pop

**System:** `spec/Brainlib/kernel.json`
- syscall wrappers
- I/O operations

**Total Instructions:** 100+

See `spec/Brainlib/*.json` for complete instruction encoding details.

## Standard Library

### seer.print.* (Output Functions)

**Location:** Built into `morph` binary

```asm
seer.print.text    ; Print null-terminated string
seer.print.int     ; Print decimal integer
seer.print.hex     ; Print hexadecimal value
seer.print.nl      ; Print newline
seer.print.raw     ; Print raw bytes
```

**Implementation:** Direct syscall to `sys_write(1, buf, len)`

### seer.string.* (String Operations)

```asm
seer.string.len        ; Calculate string length
seer.string.equals     ; Compare null-terminated strings
seer.string.equals_len ; Compare with length
seer.string.copy       ; Copy string
```

### seer.format.* (Output Generation)

```asm
seer.format.elf64_write  ; Generate ELF64 binary
seer.format.asm_write    ; Generate assembly text
```

## Development Workflow

### 1. Write Program (.fox)

```
VZOELFOX
; Your code using ISA mnemonics
nop
mov.r64.imm64
ret
```

### 2. Compile

```bash
# Development: JIT execution
./bin/morph program.fox

# Production: Native binary
./bin/morph -o program program.fox
```

### 3. Distribute

Binary is standalone ELF64 - no dependencies required.

```bash
./program  # Just run it
```

## morphlib - Standard Library

**Location:** `morphlib/`

Complete standard library written in `.fox` for high-level development:

### Memory Management
- **alloc.fox** - Heap allocator with arena support
- **buffer.fox** - Dynamic buffer management

### Runtime & Concurrency
- **morphroutine.fox** - Runtime hierarchy (Unit/Shard/Fragment)
- **daemon.fox** - Circuit breaker and memory monitoring
- **signal.fox** - Signal handling

### Data Structures
- **hashmap.fox** - Hash table implementation
- **string.fox** - String operations
- **string_ext.fox** - Extended string utilities

### I/O & System
- **io.fox** - File I/O operations
- **sys.fox** - System call wrappers
- **jaringan.fox** - Network operations

### Utilities
- **aritmatika.fox** - Arithmetic helpers
- **logika.fox** - Logic utilities
- **float.fox** - Floating point operations
- **sensor.fox** - Monitoring utilities
- **metrik.fox** - Metrics collection
- **snapshot.fox** - Memory snapshots

All libraries use high-level `.fox` syntax (fungsi/tutup_fungsi, jika/tutup_jika) and compile to native code via `morph`.

## Philosophy: Code Honesty

**Transparent:** Every instruction is explicit
**Auditable:** No hidden abstractions or magic
**Minimal:** Zero runtime dependencies
**Native:** Direct machine code generation

## Version History

**v2.0.0-bootstrap (2026-01-23)** - WORKING COMPILER! 🎉
- ✅ **Full operand encoding** - Registers, immediates, memory addressing
- ✅ **Register operations** - MOV, ADD with all GPRs (rax-r15)
- ✅ **Extended registers** - r8-r15 with proper REX encoding
- ✅ **Memory addressing** - `mov reg, [mem]` with offset support
- ✅ **Immediate values** - Decimal/hex with auto-sizing (imm8/imm32)
- ✅ **Symbol table & fixups** - Label infrastructure ready
- ✅ **Bug fixes** - Compilation segfault fixed, stable exit
- ✅ **Test suite** - Comprehensive validation of all features
- Binary size: 32KB (optimized)
- Status: Ready for bootstrap self-hosting

**v1.1.0 (2026-01-22)** - Bug Fix & Library Release
- Fixed: seer.print.int segfault (now uses hex output)
- Added: morphlib standard library (19 modules)
- Improved: Binary stability and error handling
- Note: Operand encoding not implemented (v2.0 adds this!)

**v1.0.0 (2026-01-22)** - Initial ABI Release
- Binary distribution: morph compiler
- Complete ISA specification
- System V AMD64 ABI
- ELF64 binary format
- Standard library functions

## Related Repositories

- **vzlfx** - Compiler source code (assembly)
  https://github.com/VzoelFox/vzlfx

- **morphx86_64** - High-level language compiler (future)
  Uses this ABI as backend

## License

MIT License - See LICENSE file

## Support

**Issues:** https://github.com/VzoelFox/ABImorph/issues
**Discussions:** https://github.com/VzoelFox/ABImorph/discussions

---

**ABImorph v1.0.0** - The foundation for native Morph development.
