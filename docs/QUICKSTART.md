# Quick Start Guide - Morph Compiler

Get started with Morph in 5 minutes.

## Installation

```bash
# Clone repository
git clone https://github.com/VzoelFox/ABImorph.git
cd ABImorph

# Verify binary
./bin/morph
# Usage: loader <file.fox> OR loader -o <output> <input.fox>
```

**Requirements:**
- Linux x86-64
- No additional dependencies

---

## Your First Program

### 1. Create a simple program

**hello.fox:**
```
VZOELFOX
nop
```

### 2. Run it (JIT mode)

```bash
./bin/morph hello.fox
```

**Output:**
```
Loading: hello.fox
Read bytes: 12
Runner: Control transferred to Native Runner.
Runner: JIT Buffer allocated at 0x...
Runner: Executing JIT Code...
Runner: Execution Finished.
Loader finished.
```

### 3. Compile to binary

```bash
./bin/morph -o hello hello.fox
./hello
echo $?  # Exit code: 0
```

**Output:**
- Binary created: `hello` (133 bytes)
- Exit code: 0 (success)

---

## Example Programs

### Example 1: No Operation

**nop.fox:**
```
VZOELFOX
nop
```

**What it does:** Nothing, just exits successfully.

**Run:**
```bash
./bin/morph -o nop nop.fox
./nop
```

### Example 2: Multiple NOPs

**multi_nop.fox:**
```
VZOELFOX
nop
nop
nop
nop
nop
```

**What it does:** Executes 5 NOP instructions, then exits.

**Run:**
```bash
./bin/morph -o multi multi_nop.fox
./multi
```

### Example 3: Using Registers

**register.fox:**
```
VZOELFOX
mov.r64.imm64
add.r64.r64
nop
```

**What it does:**
- Loads immediate value to register
- Adds registers
- No operation
- Exits

**Note:** This is low-level ISA - you work directly with instruction mnemonics.

---

## Understanding the Workflow

### Development Mode (JIT)

**Fast iteration:**
```bash
# Edit program
vim program.fox

# Test immediately
./bin/morph program.fox
```

**Advantages:**
- Instant execution
- No binary output
- Fast debugging

### Production Mode (Compile)

**Generate distributable binary:**
```bash
# Compile once
./bin/morph -o myapp program.fox

# Distribute
./myapp  # Standalone, no dependencies
```

**Advantages:**
- Native performance
- Portable binary
- No runtime needed

---

## ISA Basics

### Instruction Format

```
<mnemonic>.<operand_type_1>.<operand_type_2>
```

**Example:**
```
add.r64.r64     # Add 64-bit register to register
mov.r64.imm64   # Move 64-bit immediate to register
jmp.rel32       # Jump with 32-bit relative offset
```

### Common Instructions

**Arithmetic:**
```
add.r64.r64     Addition
sub.r64.r64     Subtraction
mul.r64         Multiplication
div.r64         Division
inc.r64         Increment
dec.r64         Decrement
```

**Logic:**
```
and.r64.r64     Bitwise AND
or.r64.r64      Bitwise OR
xor.r64.r64     Bitwise XOR
not.r64         Bitwise NOT
```

**Control Flow:**
```
cmp.r64.r64     Compare
jmp.rel32       Unconditional jump
je.rel32        Jump if equal
jne.rel32       Jump if not equal
call.rel32      Function call
ret             Return
```

**Data Movement:**
```
mov.r64.r64     Move register to register
mov.r64.imm64   Move immediate to register
push.r64        Push to stack
pop.r64         Pop from stack
```

**System:**
```
nop             No operation
syscall         System call
```

### Full ISA Reference

See: `docs/ISA_REFERENCE.md`

---

## File Format

### .fox File Structure

```
VZOELFOX        <- Magic header (8 bytes, required)
instruction1    <- Whitespace-separated
instruction2    <- instructions
instruction3
...
```

**Rules:**
- First 8 bytes MUST be "VZOELFOX"
- Instructions separated by whitespace (space, tab, newline)
- Comments NOT supported in v1.0
- ASCII text encoding

---

## Common Tasks

### Check if binary is valid

```bash
file output.morph
# output.morph: ELF 64-bit LSB executable, x86-64, statically linked
```

### Inspect generated code

```bash
objdump -d output.morph
# Shows disassembly
```

### Check binary size

```bash
ls -lh output.morph
# Typical size: 120-200 bytes for simple programs
```

### Debug execution

```bash
strace ./output.morph
# Shows system calls
```

---

## Troubleshooting

### "Error: Invalid Magic Number"

**Problem:** File doesn't start with "VZOELFOX"

**Solution:**
```bash
# Make sure first line is exactly:
VZOELFOX
```

### "Error: Unknown instruction"

**Problem:** Invalid instruction mnemonic

**Solution:**
- Check spelling
- Verify operand types match
- See `docs/ISA_REFERENCE.md` for valid instructions

### Segmentation Fault (after successful compile)

**Problem:** Known issue in loader cleanup (non-critical)

**Solution:**
- Binary is successfully generated before crash
- Binary is fully functional
- Safe to ignore

### Binary won't execute

**Problem:** File permissions or architecture mismatch

**Solution:**
```bash
# Check permissions
ls -l output.morph
# Should show: -rwxr-xr-x

# If not executable:
chmod +x output.morph

# Verify architecture
file output.morph
# Must be: x86-64
```

---

## Next Steps

### Learn More

1. **ABI Specification:** `docs/ABI_SPECIFICATION.md`
   - Binary format details
   - Calling conventions
   - System call interface

2. **ISA Reference:** `docs/ISA_REFERENCE.md`
   - Complete instruction list
   - Encoding details
   - Example programs

3. **Brainlib Specs:** `spec/Brainlib/*.json`
   - Raw ISA definitions
   - Opcode mappings
   - Hint messages

### Build Your Own Compiler

Use `morph` as a backend for higher-level languages:

```
Your Language (.lang)
    ↓ [Your Parser]
AST/IR
    ↓ [Your Codegen]
Morph ISA (.fox)
    ↓ [morph compiler]
Native Binary (.morph)
```

### Join Development

- **Source Code:** https://github.com/VzoelFox/vzlfx
- **ABI Repo:** https://github.com/VzoelFox/ABImorph
- **Issues:** Report bugs or request features

---

## Quick Reference Card

```bash
# JIT execute
./bin/morph program.fox

# Compile to binary
./bin/morph -o output program.fox

# Run compiled binary
./output

# Check file type
file output

# Disassemble
objdump -d output

# Trace syscalls
strace ./output

# Check size
ls -lh output
```

---

**You're ready to start developing with Morph!**

For questions or help: https://github.com/VzoelFox/ABImorph/discussions
