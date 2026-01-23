# ABImorph Development Roadmap

**Current Version:** 1.1.0-final
**Status:** Stable (with limitations)

---

## 🏗️ Architecture Philosophy

### Layer Separation

```
┌─────────────────────────────────────┐
│   ABI (ABImorph) - ACTIVE DEV       │
│   - Compiler (.fox → binary)        │
│   - Runtime builtins                │
│   - Memory management               │
│   - Wrapper functions (bootstrap)   │
│   - Seer (emit/print)               │
└─────────────────────────────────────┘
              ↓ uses (frozen interface)
┌─────────────────────────────────────┐
│   ISA (vzlfx) - FROZEN FOREVER      │
│   - Syscall primitives              │
│   - Basic mov/add/jmp/call          │
│   - No modifications ever           │
└─────────────────────────────────────┘
```

**Key Principles:**
1. **ISA (vzlfx) = FROZEN** - Foundation never changes
2. **ABI (ABImorph) = EVOLVES** - Built on top of ISA primitives
3. **Code Honesty** - No hidden abstractions in final product
4. **Bootstrap Strategy** - Temporary scaffolding allowed for development speed

---

## 📍 Version History

### v1.0.0 (2026-01-22) - Initial Release
- Binary distribution (morph compiler)
- ISA specification (100+ instructions)
- ABI documentation
- Basic compilation support

### v1.1.0-final (2026-01-22) - Bug Fixes & Documentation
- Fixed seer.print.int segfault
- Added morphlib standard library (19 modules)
- Improved stability
- Comprehensive LIMITATIONS.md
- Development roadmap
- **Limitation: No operand encoding (see LIMITATIONS.md)**

---

## 🎯 v2.0-bootstrap - Self-Host Foundation (MAJOR)

**ETA:** 1-2 weeks
**Status:** 🟡 Planning
**Strategy:** Bootstrap with wrapper scaffolding

### Philosophy: "Cangkok" (Grafting) Approach

**Problem:** Direct operand encoding = 20-30 hours rigor work
**Solution:** Temporary wrapper layer for rapid self-hosting

**Benefits:**
- ✅ 3x faster development (1-2 weeks vs 2-3 months)
- ✅ Self-host without FASM dependency
- ✅ ISA stays frozen (no changes to vzlfx)
- ✅ Solves chicken-egg problem
- ✅ Proven strategy (Rust, GCC, Go all bootstrapped this way)

**Trade-offs:**
- ⚠️ Temporary code debt (wrapper functions)
- ⚠️ Requires discipline for cleanup phase (v3.0)
- ⚠️ NOT production-ready (bootstrap only)

---

### Core Components (Built on ISA Primitives)

#### 1. **Runtime Builtins** ⭐
**Priority:** CRITICAL (Foundation)
**Layer:** ABI
**ISA Dependencies:** sys.mem.mmap, mov, add, jmp

**Components:**
- `memory.alloc` - Heap allocation wrapper
- `memory.free` - Deallocation tracking
- `memory.copy` - memcpy using ISA mov loops
- `memory.zero` - memset using ISA mov loops

**Implementation Strategy:**
```fox
# Wrapper (bootstrap phase):
memory.alloc:
    # Uses sys.mem.mmap primitive from ISA
    mov.r64.r64 rax rdi        # size parameter
    mov.r64.imm64 rdi 0        # addr = NULL
    mov.r64.r64 rsi rax        # length
    sys.mem.mmap               # ISA primitive
    ret

# Documented in WRAPPER_REGISTRY.md for v3.0 cleanup
```

---

#### 2. **Seer (Emit & Print)** ⭐
**Priority:** CRITICAL (Compiler Core)
**Layer:** ABI
**ISA Dependencies:** sys.fs.write, mov, add

**Components:**
- `seer.emit.byte` - Write opcodes to buffer
- `seer.emit.modrm` - Encode ModR/M (wrapper for now)
- `seer.print.hex` - Debug output
- `seer.format.elf64` - ELF header generation

**Bootstrap Approach:**
```fox
# v2.0-bootstrap: Simple wrapper
seer.emit.modrm:
    # Simplified ModR/M encoding
    # NOT full rigor (mod/reg/rm bits)
    # Just enough for self-host
    call memory.alloc
    mov.mem.r64 [rax] rdi
    ret

# v3.0-clean: Direct ISA implementation
# (documented in WRAPPER_REGISTRY.md)
```

---

#### 3. **Simple Compiler** ⭐
**Priority:** HIGH
**Layer:** ABI
**Goal:** Self-host `.fox → binary`

**Features (Minimal Viable):**
- Tokenizer (parse .fox syntax)
- Symbol table (functions, labels)
- Code generator (emit ISA opcodes)
- ELF64 output

**NOT Included (defer to v3.0):**
- ❌ Full operand encoding (use wrappers)
- ❌ Complex memory addressing (simple only)
- ❌ Optimization passes
- ❌ Error recovery (fail fast)

**Example:**
```fox
VZOELFOX
fungsi main
    sys.fs.write 1 msg 5
    sys.proc.exit 0
tutup_fungsi

.data
msg db "Hello"
```

Compiles to basic ELF64 binary using wrapper helpers.

---

#### 4. **WRAPPER_REGISTRY.md** ⭐
**Priority:** CRITICAL (Technical Debt Tracking)
**Purpose:** Document all temporary scaffolding

**Format:**
```markdown
## Component: memory.alloc
- **Type**: Runtime wrapper (TEMPORARY)
- **ISA Primitives**: sys.mem.mmap, mov.r64.r64, ret
- **Dependencies**: NONE (foundational)
- **Cleanup Order**: #1 (no deps, cleanup first)
- **v3.0 Replacement**: Direct sys.mem.mmap calls
- **Rationale**: Bootstrap heap management
- **Performance**: 2 extra mov instructions vs direct
- **File**: runtime/memory.fox:12-45

## Component: seer.emit.modrm
- **Type**: Compiler wrapper (TEMPORARY)
- **ISA Primitives**: mov, and, or, shl
- **Dependencies**: memory.alloc (#1)
- **Cleanup Order**: #3 (after #1, #2)
- **v3.0 Replacement**: Rigor ModR/M encoding (mod/reg/rm bit fields)
- **Rationale**: Avoid 6-8 hour ModR/M implementation during bootstrap
- **Performance**: Correct but not optimal
- **File**: compiler/emit.fox:89-156
```

**Benefits:**
1. Know what to cleanup in v3.0
2. Know cleanup order (dependencies)
3. No debugging "is this wrapper or not?"
4. Can self-host and freeze ISA simultaneously

---

### Bootstrap Success Criteria

**v2.0-bootstrap is DONE when:**

✅ **Self-host achieved:**
```bash
# No FASM dependency!
morph compiler.fox -o morph-new
./morph-new compiler.fox -o morph-new2
diff morph-new morph-new2  # Should be identical
```

✅ **Documentation complete:**
- WRAPPER_REGISTRY.md exists with ALL wrapper docs
- Each wrapper has cleanup order documented
- ISA primitive dependencies listed

✅ **Code honesty preserved (final product):**
- Wrappers clearly marked as TEMPORARY
- v3.0 cleanup path documented
- No permanent abstraction creep

✅ **ISA frozen:**
- No changes to vzlfx repository
- All development in ABImorph
- ISA primitives sufficient for self-host

**NOT Required for v2.0-bootstrap:**
- ❌ Production-ready compiler
- ❌ Optimized code generation
- ❌ Full error handling
- ❌ All morphlib modules working
- ❌ Wrapper cleanup (that's v3.0)

---

### Development Timeline (Bootstrap Phase)

**Week 1:**
- Day 1-2: Runtime builtins (memory.*, string.*)
- Day 3-4: Seer emit functions (simplified ModR/M)
- Day 5-7: Tokenizer + parser

**Week 2:**
- Day 8-10: Code generator (basic ISA emission)
- Day 11-12: ELF64 output + linking
- Day 13-14: Self-host testing + WRAPPER_REGISTRY.md

**Total:** 1-2 weeks for self-hosting compiler

---

---

## 🧹 v3.0-clean - Production Ready (MAJOR)

**ETA:** 2-3 weeks
**Prerequisites:** v2.0-bootstrap complete
**Status:** 🔴 Not started
**Goal:** Remove ALL wrappers, achieve code honesty

### Philosophy: Cleanup Phase

**Objective:** Transform bootstrap compiler into production compiler
- ✅ Self-hosted (from v2.0-bootstrap)
- ✅ No FASM dependency (from v2.0-bootstrap)
- ✅ Code honesty (new in v3.0)
- ✅ Production quality (new in v3.0)

**Strategy:** Use WRAPPER_REGISTRY.md for systematic cleanup

---

### Cleanup Process (Documented Order)

#### Phase 1: Foundation Wrappers (Week 1)
**Order:** #1 → #2 → #3 (no dependencies first)

```markdown
Cleanup #1: memory.alloc, memory.free, memory.copy
- Remove wrapper layer
- Direct sys.mem.mmap calls
- Update all call sites
- Test: Self-compile still works

Cleanup #2: string.compare, string.length
- Direct ISA mov/cmp loops
- Remove abstraction
- Test: Tokenizer still works

Cleanup #3: Basic I/O wrappers
- Direct sys.fs.write calls
- Remove seer.print.* wrappers
- Keep only seer.emit.* (compiler core)
```

#### Phase 2: Compiler Core (Week 2)
**Order:** #4 → #5 → #6 (depends on Phase 1)

```markdown
Cleanup #4: seer.emit.modrm (CRITICAL)
- Implement RIGOR ModR/M encoding
- Mod bits (2 bits): 00=indirect, 01=disp8, 10=disp32, 11=direct
- Reg bits (3 bits): Register encoding
- R/M bits (3 bits): Register/memory encoding
- REX prefix handling for r8-r15
- SIB byte generation for [base+index*scale]

Cleanup #5: Immediate value encoding
- Sign-extension handling
- imm8 vs imm32 vs imm64 selection
- Range validation

Cleanup #6: Label resolution
- Two-pass assembly (collect labels, then emit)
- Forward reference handling
- Relocation table generation
```

#### Phase 3: Polish (Week 3)
**Order:** #7 → #8 (final touches)

```markdown
Cleanup #7: Error handling
- Replace "fail fast" with detailed errors
- Line number tracking
- Helpful error messages

Cleanup #8: Testing & validation
- Compile all morphlib modules
- Compare output with v2.0-bootstrap
- Performance benchmarks
- Binary size analysis
```

---

### Code Honesty Validation

**Before v3.0 (v2.0-bootstrap with wrappers):**
```fox
# User writes:
memory.alloc 1024

# What actually happens?
# ??? (hidden in wrapper, could be 10 instructions)
```

**After v3.0-clean (code honesty):**
```fox
# User writes:
mov.r64.imm64 rdi 1024
mov.r64.imm64 rsi 3          # PROT_READ|PROT_WRITE
mov.r64.imm64 rdx 34         # MAP_PRIVATE|MAP_ANONYMOUS
mov.r64.imm64 r10 -1         # fd
mov.r64.imm64 r8 0           # offset
sys.mem.mmap

# What actually happens: EXACTLY THIS
# 6 mov instructions + 1 syscall = 7 operations, predictable
```

**Result:** User knows EXACTLY what hardware executes.

---

### v3.0-clean Success Criteria

✅ **Zero wrappers remaining:**
- WRAPPER_REGISTRY.md marked all as "REMOVED"
- grep "wrapper" compiler.fox → 0 results
- All code direct ISA primitives

✅ **Self-host 3x verification:**
```bash
morph-v3 compiler.fox -o gen1
gen1 compiler.fox -o gen2
gen2 compiler.fox -o gen3
diff gen1 gen2 && diff gen2 gen3  # All identical
```

✅ **morphlib fully usable:**
- All 19 modules compile
- Examples run correctly
- No wrapper dependencies

✅ **Code honesty audit:**
- No hidden control flow
- All syscalls explicit
- Performance predictable
- Binary size minimal

✅ **ISA still frozen:**
- No changes to vzlfx
- All work in ABImorph layer

---

## 🚀 v3.1+ - Advanced Features

**ETA:** TBD
**Prerequisites:** v3.0-clean complete

### Features:
- Multi-file compilation
- Linking support
- Static libraries
- Macro system
- Include system
- Optimization levels (-O0, -O1, -O2)
- Better error messages
- Debug information (DWARF)

---

## 🌐 v4.0 - Cross-Platform Support

**ETA:** TBD
**Prerequisites:** v3.1+ complete

### Targets:
- ARM64 (AArch64)
- RISC-V
- Windows (PE format)
- macOS (Mach-O format)
- FreeBSD/OpenBSD

**Note:** ISA expansion required (new repos: vzlfx-arm64, vzlfx-riscv)

---

## 📦 v5.0 - Ecosystem Maturity

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

## 🛠️ Development Phases (Revised Bootstrap Strategy)

### Phase 1: v2.0-bootstrap - Self-Host with Wrappers
**Duration:** 1-2 weeks
**Focus:** Rapid self-hosting without FASM
**Strategy:** Temporary scaffolding + documentation

**Milestones:**
1. 🔴 Runtime builtins (memory, string)
2. 🔴 Seer emit (simplified ModR/M wrapper)
3. 🔴 Tokenizer + parser
4. 🔴 Code generator (basic ISA emission)
5. 🔴 ELF64 output
6. 🔴 Self-host verification
7. 🔴 WRAPPER_REGISTRY.md complete

---

### Phase 2: v3.0-clean - Remove All Wrappers
**Duration:** 2-3 weeks
**Focus:** Production quality + code honesty
**Strategy:** Systematic cleanup using WRAPPER_REGISTRY.md

**Milestones:**
1. 🔴 Cleanup foundation wrappers (#1-#3)
2. 🔴 Cleanup compiler core (#4-#6)
3. 🔴 Polish and testing (#7-#8)
4. 🔴 Rigor ModR/M encoding
5. 🔴 morphlib full compilation
6. 🔴 Self-host 3x verification
7. 🔴 Code honesty audit

---

### Phase 3: v3.1+ - Advanced Features
**Duration:** 4-6 weeks
**Focus:** Production compiler features

---

### Phase 4: v4.0+ - Cross-Platform
**Duration:** 8-12 weeks
**Focus:** ARM64, RISC-V, Windows, macOS

---

## 📊 Progress Tracking

### Overall Roadmap Status

| Version | Status | Progress | ETA |
|---------|--------|----------|-----|
| v1.1.0-final | ✅ Complete | 100% | Released |
| v2.0-bootstrap | 🔴 Not started | 0% | 1-2 weeks |
| v3.0-clean | 🔴 Not started | 0% | 2-3 weeks |
| v3.1+ | 🔴 Not started | 0% | TBD |
| v4.0+ | 🔴 Not started | 0% | TBD |

---

### v2.0-bootstrap Development Status

| Component | Status | Progress | Notes |
|-----------|--------|----------|-------|
| Runtime builtins | 🔴 Not started | 0% | memory.*, string.* |
| Seer emit | 🔴 Not started | 0% | Simplified ModR/M |
| Tokenizer | 🔴 Not started | 0% | .fox parser |
| Code generator | 🔴 Not started | 0% | ISA emission |
| ELF64 output | 🔴 Not started | 0% | Binary format |
| Self-host test | 🔴 Not started | 0% | Verification |
| WRAPPER_REGISTRY | 🔴 Not started | 0% | Documentation |

**Overall:** 0% complete (v2.0-bootstrap not started)

---

### v3.0-clean Cleanup Tracking

| Cleanup Task | Dependencies | Status | Notes |
|--------------|--------------|--------|-------|
| #1: memory.* | NONE | 🔴 Pending | Foundation |
| #2: string.* | NONE | 🔴 Pending | Foundation |
| #3: I/O wrappers | NONE | 🔴 Pending | Foundation |
| #4: seer.emit.modrm | #1,#2,#3 | 🔴 Pending | CRITICAL |
| #5: Immediate encoding | #1,#2,#3 | 🔴 Pending | Core |
| #6: Label resolution | #1,#2,#3,#4 | 🔴 Pending | Core |
| #7: Error handling | #1-#6 | 🔴 Pending | Polish |
| #8: Testing | #1-#7 | 🔴 Pending | Validation |

**Overall:** 0% complete (awaiting v2.0-bootstrap)

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

## 📅 Timeline (Revised Bootstrap Strategy)

```
2026-01 (Current)
├─ v1.1.0-final Release ✅
├─ LIMITATIONS.md ✅
├─ ROADMAP.md (bootstrap strategy) ✅
└─ v2.0-bootstrap Planning ⏳

2026-02 (Target - Bootstrap Phase)
├─ Week 1: Runtime + Seer
│   ├─ memory.* builtins
│   ├─ string.* helpers
│   └─ seer.emit.* (wrapper version)
├─ Week 2: Compiler Core
│   ├─ Tokenizer + parser
│   ├─ Code generator
│   └─ ELF64 output
├─ Week 3-4: Self-Host
│   ├─ Self-compilation test
│   ├─ WRAPPER_REGISTRY.md complete
│   └─ v2.0-bootstrap Release

2026-03 (Target - Cleanup Phase)
├─ Week 1: Foundation cleanup (#1-#3)
├─ Week 2: Compiler core cleanup (#4-#6)
├─ Week 3: Polish (#7-#8)
└─ v3.0-clean Release

2026-04+ (Future)
├─ v3.1+ Advanced features
└─ v4.0+ Cross-platform
```

**Note:** Timeline assumes focused development. May adjust based on contributor availability.

---

## 🎯 Success Criteria

### v2.0-bootstrap Definition of Done

**Must Have:**
- ✅ Self-host works (morph compiles morph)
- ✅ No FASM dependency for compilation
- ✅ Basic .fox syntax support
- ✅ ELF64 binary output
- ✅ WRAPPER_REGISTRY.md complete
- ✅ All wrappers documented with cleanup order
- ✅ ISA (vzlfx) remains frozen

**Acceptable Limitations (temporary):**
- ⚠️ Wrappers present (documented in WRAPPER_REGISTRY.md)
- ⚠️ Not production-ready
- ⚠️ Limited error messages
- ⚠️ morphlib partial support
- ⚠️ No optimization

**NOT Acceptable:**
- ❌ Undocumented wrappers
- ❌ ISA modifications
- ❌ Permanent abstractions without cleanup plan

---

### v3.0-clean Definition of Done

**Must Have:**
- ✅ Zero wrappers remaining
- ✅ WRAPPER_REGISTRY.md all marked "REMOVED"
- ✅ Code honesty validated (all operations explicit)
- ✅ Self-host 3x identical binaries
- ✅ morphlib compiles fully
- ✅ Rigor ModR/M encoding
- ✅ Performance predictable
- ✅ ISA still frozen

**Production Ready:**
- ✅ No hidden abstractions
- ✅ No performance surprises
- ✅ Binary size minimal
- ✅ Debugging straightforward
- ✅ Full control over hardware

**Philosophy Compliance:**
- ✅ Code honesty preserved
- ✅ Direct syscalls
- ✅ Predictable execution
- ✅ No wrapper bloat

---

## 🎓 Why Bootstrap Strategy?

### Historical Precedent

**Rust:**
```
OCaml → rustc v0.1 → rustc v0.2 → ... → pure Rust
Temporary scaffolding → Self-host → Cleanup → Production
```

**Go:**
```
C compiler → Go v1.0-v1.4 → Go v1.5+ (pure Go)
External dependency → Self-host → Independence
```

**GCC:**
```
Another C compiler → GCC v1 → GCC compiling itself
Bootstrap → Self-host → Standard
```

### Morph Strategy (Similar Pattern)

```
FASM → morph v2.0-bootstrap (wrappers) → v3.0-clean (pure ISA)
External tool → Self-host with scaffolding → Code honesty
```

### Why This Works

**Technical:**
- ✅ Proven strategy (Rust, Go, GCC all did this)
- ✅ Faster time-to-self-host (3x speedup)
- ✅ Solves chicken-egg problem
- ✅ ISA can stay frozen

**Philosophical:**
- ✅ Wrappers are TEMPORARY (documented cleanup)
- ✅ Final product maintains code honesty
- ✅ No permanent abstraction creep
- ✅ Clear path from bootstrap → production

**Practical:**
- ✅ 1 month total vs 3 months direct approach
- ✅ Can test compiler logic early
- ✅ Iterative development
- ✅ Clear milestones

### Risk Mitigation

**Risk:** Wrappers become permanent
**Mitigation:** WRAPPER_REGISTRY.md mandatory, cleanup order documented

**Risk:** Code honesty violated
**Mitigation:** v3.0-clean is MANDATORY release, not optional

**Risk:** Complex cleanup
**Mitigation:** Dependencies tracked, cleanup order numbered (#1, #2, ...)

**Risk:** Lost motivation after self-host
**Mitigation:** Set concrete timeline, v3.0 is "production" not v2.0

---

## 📞 Communication

**Discussions:** https://github.com/VzoelFox/ABImorph/discussions
**Issues:** https://github.com/VzoelFox/ABImorph/issues
**Pull Requests:** https://github.com/VzoelFox/ABImorph/pulls

---

## 🔗 Related Documents

- [LIMITATIONS.md](LIMITATIONS.md) - Current v1.1.0 limitations
- [README.md](README.md) - Project overview
- [spec/](spec/) - ISA specification (100+ instructions)
- [morphlib/](morphlib/) - Standard library (reference)
- **WRAPPER_REGISTRY.md** - To be created in v2.0-bootstrap

---

**Last Updated:** 2026-01-22
**Version:** 1.1.0-final
**Strategy:** Bootstrap with temporary wrappers → Self-host → Cleanup
**Next Milestone:** v2.0-bootstrap Development Start
