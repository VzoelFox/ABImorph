# Morph ISA Reference Guide

**Version:** 1.0.0
**Architecture:** x86-64
**Instruction Count:** 100+

Quick reference for all supported Morph instructions.

## Instruction Format

```
<mnemonic>.<operand1>.<operand2>
```

**Operand Types:**
- `r64` - 64-bit register
- `r32` - 32-bit register
- `mem` - Memory operand
- `imm64` - 64-bit immediate
- `imm32` - 32-bit immediate
- `imm8` - 8-bit immediate
- `rel32` - 32-bit relative offset

---

## Arithmetic Instructions

**Addition:**
```
add.r64.r64        Add register to register
add.r64.mem        Add memory to register
add.mem.r64        Add register to memory
add.r64.imm32      Add immediate to register
add.r64.imm8       Add 8-bit immediate to register
```

**Subtraction:**
```
sub.r64.r64        Subtract register from register
sub.r64.mem        Subtract memory from register
sub.mem.r64        Subtract register from memory
sub.r64.imm32      Subtract immediate from register
sub.r64.imm8       Subtract 8-bit immediate from register
```

**Multiplication:**
```
mul.r64            Unsigned multiply (rax * operand -> rdx:rax)
imul.r64.r64       Signed multiply register by register
imul.r64.mem       Signed multiply register by memory
imul.r64.imm32     Signed multiply register by immediate
```

**Division:**
```
div.r64            Unsigned divide (rdx:rax / operand)
idiv.r64           Signed divide
```

**Increment/Decrement:**
```
inc.r64            Increment register
dec.r64            Decrement register
neg.r64            Negate register (two's complement)
```

**With Carry:**
```
adc.r64.r64        Add with carry
sbb.r64.r64        Subtract with borrow
```

---

## Logic Instructions

**Bitwise Operations:**
```
and.r64.r64        Bitwise AND
and.r64.imm32      AND with immediate
or.r64.r64         Bitwise OR
or.r64.imm32       OR with immediate
xor.r64.r64        Bitwise XOR
xor.r64.imm32      XOR with immediate
not.r64            Bitwise NOT (one's complement)
```

**Shifts:**
```
shl.r64.imm8       Shift left logical
shr.r64.imm8       Shift right logical
sal.r64.imm8       Shift arithmetic left
sar.r64.imm8       Shift arithmetic right
rol.r64.imm8       Rotate left
ror.r64.imm8       Rotate right
```

**Bit Test:**
```
bt.r64.imm8        Bit test
bts.r64.imm8       Bit test and set
btr.r64.imm8       Bit test and reset
btc.r64.imm8       Bit test and complement
```

---

## Data Movement

**MOV - Move Data:**
```
mov.r64.r64        Move register to register
mov.r64.mem        Move memory to register
mov.mem.r64        Move register to memory
mov.r64.imm64      Move 64-bit immediate to register
mov.r64.imm32      Move 32-bit immediate to register
mov.mem.imm32      Move immediate to memory
```

**LEA - Load Effective Address:**
```
lea.r64.mem        Load effective address
```

**MOVSX/MOVZX - Sign/Zero Extend:**
```
movsx.r64.r32      Sign-extend 32 to 64 bit
movsx.r64.r16      Sign-extend 16 to 64 bit
movsx.r64.r8       Sign-extend 8 to 64 bit
movzx.r64.r32      Zero-extend 32 to 64 bit
movzx.r64.r16      Zero-extend 16 to 64 bit
movzx.r64.r8       Zero-extend 8 to 64 bit
```

**XCHG - Exchange:**
```
xchg.r64.r64       Exchange register with register
xchg.r64.mem       Exchange register with memory
```

---

## Stack Operations

```
push.r64           Push register onto stack
push.imm32         Push immediate onto stack
pop.r64            Pop from stack to register
```

---

## Control Flow

**Comparison:**
```
cmp.r64.r64        Compare register with register
cmp.r64.imm32      Compare register with immediate
cmp.r64.imm8       Compare register with 8-bit immediate
test.r64.r64       Test (bitwise AND, set flags only)
```

**Unconditional Jump:**
```
jmp.rel32          Jump unconditional
```

**Conditional Jumps:**
```
je.rel32           Jump if equal (ZF=1)
jne.rel32          Jump if not equal (ZF=0)
jz.rel32           Jump if zero (ZF=1)
jnz.rel32          Jump if not zero (ZF=0)

jl.rel32           Jump if less (signed, SF≠OF)
jle.rel32          Jump if less or equal (signed, ZF=1 or SF≠OF)
jg.rel32           Jump if greater (signed, ZF=0 and SF=OF)
jge.rel32          Jump if greater or equal (signed, SF=OF)

jb.rel32           Jump if below (unsigned, CF=1)
jbe.rel32          Jump if below or equal (unsigned, CF=1 or ZF=1)
ja.rel32           Jump if above (unsigned, CF=0 and ZF=0)
jae.rel32          Jump if above or equal (unsigned, CF=0)

js.rel32           Jump if sign (SF=1)
jns.rel32          Jump if not sign (SF=0)
jo.rel32           Jump if overflow (OF=1)
jno.rel32          Jump if not overflow (OF=0)
```

**Function Calls:**
```
call.rel32         Call function (push rip, jump)
ret                Return from function (pop rip)
```

**No Operation:**
```
nop                No operation (0x90)
```

---

## Conversion Instructions

```
cbw                Convert byte to word (AL -> AX)
cwde               Convert word to doubleword (AX -> EAX)
cdqe               Convert doubleword to quadword (EAX -> RAX)
cwd                Convert word to doubleword (AX -> DX:AX)
cdq                Convert doubleword to quadword (EAX -> EDX:EAX)
cqo                Convert quadword to octword (RAX -> RDX:RAX)
```

---

## System Instructions

```
syscall            System call (Linux x86-64)
```

---

## Special Instructions

**Atomic Operations:**
```
lock.prefix        Lock prefix (for atomic operations)
xadd.r64.r64       Exchange and add (atomic)
cmpxchg.r64.r64    Compare and exchange (atomic)
```

**Memory Barriers:**
```
mfence             Memory fence (full barrier)
lfence             Load fence
sfence             Store fence
```

**CPU Information:**
```
cpuid              CPU identification
rdtsc              Read time-stamp counter
```

**Misc:**
```
lahf               Load flags into AH
sahf               Store AH into flags
pause              Pause (for spin-wait loops)
```

---

## Pseudo-Instructions (seer.*)

**Print Functions:**
```
seer.print.text    Print null-terminated string (rdi=ptr)
seer.print.int     Print signed integer (rdi=value)
seer.print.hex     Print hexadecimal (rdi=value)
seer.print.nl      Print newline
seer.print.raw     Print raw bytes (rdi=ptr, rsi=len)
```

**String Functions:**
```
seer.string.len         Get string length (rdi=str) -> rax
seer.string.equals      Compare strings (rdi=s1, rsi=s2) -> rax
seer.string.equals_len  Compare with length (rdi=s1, rsi=s2, rdx=len) -> rax
seer.string.copy        Copy string (rdi=dest, rsi=src)
```

---

## Flags Register (RFLAGS)

**Status Flags:**
```
CF (bit 0)   Carry Flag
PF (bit 2)   Parity Flag
AF (bit 4)   Auxiliary Carry Flag
ZF (bit 6)   Zero Flag
SF (bit 7)   Sign Flag
OF (bit 11)  Overflow Flag
```

**Control Flags:**
```
DF (bit 10)  Direction Flag
```

---

## Example Programs

### Hello World
```
VZOELFOX
mov.r64.imm64 rdi msg
call seer.print.text
call seer.print.nl
ret

msg: db "Hello, World!", 0
```

### Simple Loop
```
VZOELFOX
mov.r64.imm64 rcx 10
loop_start:
    dec.r64 rcx
    jnz.rel32 loop_start
ret
```

### Function Call
```
VZOELFOX
mov.r64.imm64 rdi 42
call print_number
ret

print_number:
    push.r64 rbp
    mov.r64.r64 rbp rsp
    call seer.print.int
    call seer.print.nl
    pop.r64 rbp
    ret
```

---

## Instruction Encoding Details

For complete encoding details including opcodes, ModR/M, and SIB bytes, see:
- `spec/Brainlib/*.json` - Full ISA definition with encoding
- Intel® 64 and IA-32 Architectures Software Developer's Manual

---

**ISA Reference v1.0.0**
