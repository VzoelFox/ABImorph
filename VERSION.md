# Version History - Morph Compiler

## v3.1.0-control-flow (2026-01-23) - CURRENT

**Binary:** bin/morph (48,826 bytes / 48KB)

### New Features
- ✅ **JMP instruction** - Unconditional jump with labels
- ✅ **CALL instruction** - Function calls (backward refs working)
- ✅ **JE instruction** - Conditional jump if equal (backward refs working)
- ✅ **CMP instruction** - Compare registers, sets FLAGS
- ✅ **Labels** - Forward and backward reference support
- ✅ **Symbol table** - 256 entries, 8KB data structure
- ✅ **Fixup system** - Forward reference resolution (rel8/rel32/abs64)

### Bug Fixes
- ✅ Fixed string comparison for label lookup
- ✅ Fixed fixup system to skip unresolved instead of aborting
- ✅ Fixed apply_all missing JIT base address parameter

### Known Issues
- ⚠️ JE forward references not working (backward refs work fine)
- See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for complete list

### Breaking Changes
- None - Fully backward compatible with v2.0.0 .fox files

---

## v2.0.0-bootstrap (2026-01-23)

**Binary:** bin/morph (32,768 bytes / 32KB)

### New Features
- ✅ **Full operand encoding** - REX prefix + ModR/M byte
- ✅ **Immediate values** - Decimal and hex with auto-sizing
- ✅ **Memory addressing** - Load from memory `mov rax, [rbx+8]`
- ✅ **Extended registers** - r8-r15 fully supported
- ✅ **Symbol table infrastructure** - Foundation for labels

### Bug Fixes
- ✅ Fixed segfault after compilation (stack cleanup)
- ✅ Fixed register encoding corruption (use r14 instead of rax)
- ✅ Fixed memory parser complexity

### Known Issues
- ❌ No control flow (JMP, CALL, conditional jumps)
- ❌ No labels
- ⚠️ Memory addressing load-only (no store)

---

## v1.1.0-final (2026-01-22) - DEPRECATED

**Status:** BROKEN - Do not use

### Issues
- ❌ Operand encoding broken - only opcode emitted
- ❌ Segfault after compilation
- ❌ No immediate values
- ❌ No memory addressing
- ❌ Generated code undefined behavior

**Note:** This version is kept for historical reference only.

---

## v1.0.0 (Initial Release)

**Status:** BROKEN - Do not use

### Features
- Basic instruction recognition
- Token parsing
- Minimal JIT compilation

### Issues
- No operand encoding
- Many segfaults
- Incomplete implementation

---

## Version Numbering

**Format:** MAJOR.MINOR.PATCH-label

**MAJOR:** Breaking ISA changes (frozen until v4.0)
**MINOR:** New instructions, features (backward compatible)
**PATCH:** Bug fixes only
**Label:** Release stage (bootstrap, control-flow, etc.)

---

## Upgrade Path

### From v2.0.0 → v3.1.0
- ✅ All v2.0.0 .fox files work unchanged
- ✅ New instructions available (JMP, CALL, JE, CMP)
- ✅ Binary drop-in replacement

### From v1.x → v3.1.0
- ❌ v1.x .fox files may not work (operand encoding changed)
- ⚠️ Recommend rewriting for v3.1.0

---

## Binary Verification

**v3.1.0 SHA256:**
```bash
sha256sum bin/morph
# Expected: (calculate after release)
```

**v3.1.0 File Info:**
```bash
file bin/morph
# ELF 64-bit LSB executable, x86-64, statically linked

ls -lh bin/morph
# 48K (48,826 bytes)
```

---

## Release Channels

**Stable:** v3.1.0 (current)
**Beta:** None
**Dev:** /root/vzlfx/morph_v3 (development builds)

---

## Support Timeline

| Version | Release | Support End | Status |
|---------|---------|-------------|--------|
| v3.1.0 | 2026-01-23 | TBD | ✅ Current |
| v2.0.0 | 2026-01-23 | 2026-02-23 | ⚠️ Use v3.1 |
| v1.x | 2026-01-22 | 2026-01-23 | ❌ Deprecated |

---

**Last Updated:** 2026-01-23
**Maintainer:** VzoelFox

---
