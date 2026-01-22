# ABImorph Development Roadmap

**Current Version:** 1.1.0-final
**Status:** Stable (with limitations)

---

## 📍 Version History

### v1.0.0 (2026-01-22) - Initial Release
- Binary distribution (morph compiler)
- ISA specification (100+ instructions)
- ABI documentation
- Basic compilation support

### v1.1.0 (2026-01-22) - Bug Fixes & Library
- Fixed seer.print.int segfault
- Added morphlib standard library (19 modules)
- Improved stability
- Documentation updates
- **Limitation: No operand encoding**

---

## 🎯 v2.0.0 - Full Operand Support (MAJOR)

**ETA:** TBD (requires 20-30 hours development)
**Status:** 🟡 Planning

### Core Features

#### 1. **Complete Operand Encoding** ⭐
**Priority:** CRITICAL

**Implementation:**
- Register name parsing (rax-r15, eax-r15d, ax-r15w, al-r15b)
- Immediate value parsing (decimal, hex, binary)
- Memory addressing modes:
  - Direct: `[rax]`
  - Displacement: `[rax+8]`
  - SIB: `[rax+rbx*4]`
  - RIP-relative: `[rip+offset]`
- ModR/M byte generation
- SIB byte generation
- REX prefix generation
- Displacement encoding

**Testing:** All 100+ ISA instructions with operands

**Example:**
```fox
# v2.0.0 supports:
mov.r64.r64 rax rbx          → 0x48 0x89 0xD8
add.r64.imm32 rcx 42         → 0x48 0x81 0xC1 0x0000002A
mov.r64.mem rsi [rdi+16]     → 0x48 0x8B 0x77 0x10
```

---

#### 2. **Label Support** ⭐
**Priority:** HIGH

**Features:**
- Label definitions: `main:`, `loop_start:`
- Label references: `jmp loop_start`, `call helper`
- Forward/backward references
- Automatic offset calculation
- Relocation table

**Example:**
```fox
VZOELFOX
main:
    call helper
    ret

helper:
    nop
    ret
```

---

#### 3. **High-Level Syntax Compilation** ⭐
**Priority:** HIGH

**Features:**
- `fungsi name` → label generation + prologue
- `tutup_fungsi` → epilogue + ret
- `jika_sama` → conditional jumps
- `tutup_jika` → label management
- `loop` → loop labels
- `tutup_loop` → loop jumps

**Benefit:** morphlib becomes usable!

**Example:**
```fox
VZOELFOX
fungsi main
    mov rax, 42
    ret
tutup_fungsi
```

Compiles to:
```asm
main:
    push rbp
    mov rbp, rsp
    mov rax, 42
    leave
    ret
```

---

#### 4. **Improved Error Handling**
**Priority:** MEDIUM

**Features:**
- Detailed error messages with line numbers
- Syntax error reporting
- Register validation
- Immediate value range checking
- Memory addressing validation
- No more silent failures

**Example:**
```
Error: line 5: Invalid register name 'rxa' (did you mean 'rax'?)
Error: line 12: Immediate value 0xFFFFFFFFFFFFFFFF too large for imm32
```

---

#### 5. **Comprehensive Testing**
**Priority:** HIGH

**Coverage:**
- Unit tests for all operand types
- Integration tests for all instructions
- Edge case testing (r8-r15, special encodings)
- Regression tests
- morphlib compilation tests

**Metrics:**
- 90%+ code coverage
- All ISA instructions validated
- No undefined behavior

---

### Secondary Features

#### 6. **Data Section Support**
**Priority:** MEDIUM

**Features:**
- `.data` directive
- String literals: `msg db "Hello", 0`
- Numeric data: `value dq 42`
- Array initialization

**Example:**
```fox
VZOELFOX
.data
msg db "Hello, World!", 0
value dq 42

.text
main:
    mov rsi, msg
    call print
    ret
```

---

#### 7. **Include/Module System**
**Priority:** MEDIUM

**Features:**
- `include "morphlib/alloc.fox"`
- Prevent duplicate includes
- Namespace management
- Circular dependency detection

**Benefit:** morphlib becomes modular and reusable.

---

#### 8. **Optimization Pass**
**Priority:** LOW

**Features:**
- Dead code elimination
- Constant folding
- Peephole optimization
- Register allocation hints

---

#### 9. **Debug Information**
**Priority:** LOW

**Features:**
- DWARF debug info generation
- Source line mapping
- Symbol table
- GDB integration

---

## 🔮 v2.1.0 - Advanced Features

**ETA:** TBD
**Prerequisites:** v2.0.0 complete

### Features:
- Multi-file compilation
- Linking support
- Static libraries
- Macro system
- Inline assembly
- Optimization levels (-O0, -O1, -O2)

---

## 🌐 v3.0.0 - Cross-Platform Support

**ETA:** TBD
**Prerequisites:** v2.1.0 complete

### Targets:
- ARM64 (AArch64)
- RISC-V
- Windows (PE format)
- macOS (Mach-O format)
- FreeBSD/OpenBSD

---

## 📦 v4.0.0 - Ecosystem Maturity

**ETA:** TBD

### Features:
- Package manager
- Standard library expansion
- IDE integrations
- Language server protocol (LSP)
- Documentation generator
- Testing framework
- Build system integration

---

## 🛠️ Development Phases

### Phase 1: v2.0.0 Foundation (Current)
**Duration:** 20-30 hours
**Focus:** Core functionality (operands, labels, syntax)

**Milestones:**
1. ✅ Operand parser complete
2. ✅ ModR/M generator complete
3. ✅ Tokenizer updated
4. ✅ Runner rewritten
5. ✅ All tests passing
6. ✅ Documentation updated

---

### Phase 2: v2.0.0 Testing & Polish
**Duration:** 10-15 hours
**Focus:** Quality assurance

**Tasks:**
- Comprehensive test suite
- Bug fixes
- Performance optimization
- Documentation completion
- Example programs

---

### Phase 3: v2.1.0+ Features
**Duration:** 30-40 hours
**Focus:** Advanced features

---

## 📊 Progress Tracking

### v2.0.0 Development Status

| Component | Status | Progress |
|-----------|--------|----------|
| Register parser | 🟡 In progress | 70% |
| ModR/M generator | 🔴 Not started | 0% |
| Immediate parser | 🔴 Not started | 0% |
| Memory addressing | 🔴 Not started | 0% |
| Label system | 🔴 Not started | 0% |
| High-level syntax | 🔴 Not started | 0% |
| Tokenizer update | 🔴 Not started | 0% |
| Runner rewrite | 🔴 Not started | 0% |
| Testing | 🔴 Not started | 0% |
| Documentation | 🔴 Not started | 0% |

**Overall:** 7% complete

---

## 🤝 Contributing

### How to Contribute to v2.0.0

1. **Code contributions:**
   - Fork ABImorph repository
   - Implement features from roadmap
   - Submit pull requests

2. **Testing:**
   - Test current binaries
   - Report bugs (non-limitations)
   - Suggest improvements

3. **Documentation:**
   - Improve guides
   - Write tutorials
   - Create examples

4. **Design:**
   - Propose architectures
   - Review implementations
   - Provide feedback

---

## 📅 Timeline (Tentative)

```
2026-01 (Current)
├─ v1.1.0 Release ✅
└─ v2.0.0 Planning ✅

2026-02 (Target)
├─ v2.0.0 Development start
├─ Operand encoding
├─ Label support
└─ High-level syntax

2026-03 (Target)
├─ v2.0.0 Testing
├─ Bug fixes
└─ v2.0.0 Release

2026-04+ (Future)
├─ v2.1.0 Planning
└─ Advanced features
```

**Note:** Timeline is flexible and depends on contributor availability.

---

## 🎯 Success Criteria

### v2.0.0 Definition of Done

**Must Have:**
- ✅ All operand types work correctly
- ✅ Register encoding correct
- ✅ Immediate values work
- ✅ Memory addressing works
- ✅ Labels and jumps work
- ✅ High-level syntax compiles
- ✅ morphlib compiles successfully
- ✅ 90%+ test coverage
- ✅ Zero critical bugs
- ✅ Complete documentation

**Nice to Have:**
- Optimization pass
- Debug info
- Better error messages

---

## 📞 Communication

**Discussions:** https://github.com/VzoelFox/ABImorph/discussions
**Issues:** https://github.com/VzoelFox/ABImorph/issues
**Pull Requests:** https://github.com/VzoelFox/ABImorph/pulls

---

## 🔗 Related Documents

- [LIMITATIONS.md](LIMITATIONS.md) - Current v1.1.0 limitations
- [README.md](README.md) - Project overview
- [docs/ABI_SPECIFICATION.md](docs/ABI_SPECIFICATION.md) - ABI details
- [docs/ISA_REFERENCE.md](docs/ISA_REFERENCE.md) - Instruction reference

---

**Last Updated:** 2026-01-22
**Version:** 1.1.0-final
**Next Milestone:** v2.0.0 Development Start
