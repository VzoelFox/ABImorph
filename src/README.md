# Parser Implementation - Current Status

**Date:** 2026-01-23
**Status:** ⚠️ BLOCKED by ISA Limitation

---

## Problem: No Store-to-Memory

**ISA v3.1.0 Limitation:**
```fox
mov rax [rbx]      # Load ✅ (implemented)
mov [rbx] rax      # Store ❌ (NOT implemented)
```

**Impact on Parser:**
- Cannot build output buffer byte-by-byte
- Cannot modify memory buffers
- Cannot build complex data structures

---

## Attempted Solutions

### Approach 1: Buffer-based Parser ❌
- Allocate input/output buffers
- Parse and transform in memory
- **BLOCKED:** Cannot write to output buffer

### Approach 2: Streaming Parser ⚠️
- Read byte by byte
- Output directly to stdout
- **LIMITED:** No lookahead, no backtracking

### Approach 3: External Bootstrapping ✅ (Recommended)
- Write parser in C/Python
- Generate .fox from morphlib
- Use until store-to-memory implemented

---

## Recommended Path Forward

### Option A: Implement Store-to-Memory in ISA

**Add to v3.2:**
```fox
mov [reg], reg        # Store register to memory
mov [reg+offset], reg  # Store with displacement
```

**Encoding:**
```
REX.W + 0x89 + ModR/M + displacement
```

**Effort:** ~2-3 hours
**Benefit:** Enables full parser in .fox

### Option B: External Parser (Temporary)

**Python parser:** `tools/morphlib_parser.py`
```python
#!/usr/bin/env python3
import sys

def parse_morphlib(input_file, output_file):
    with open(input_file) as f:
        lines = f.readlines()

    output = ["VZOELFOX\n"]

    for line in lines:
        line = line.strip()

        if line.startswith("fungsi "):
            name = line.split()[1]
            output.append(f"{name}:\n")

        elif line == "tutup_fungsi":
            continue  # Skip

        elif line.startswith("kembali"):
            output.append("ret\n")

        elif line.startswith("panggil "):
            func = line.split()[1]
            output.append(f"call {func}\n")

        elif line.startswith("runtime.keluar"):
            arg = line.split()[1]
            output.append(f"mov rdi {arg}\n")
            output.append(f"mov rax 60\n")
            output.append(f"syscall\n")

        else:
            # Pass through ISA instructions
            output.append(line + "\n")

    with open(output_file, 'w') as f:
        f.writelines(output)

if __name__ == "__main__":
    parse_morphlib(sys.argv[1], sys.argv[2])
```

**Usage:**
```bash
python3 tools/morphlib_parser.py program.morphlib program.fox
./bin/morph program.fox
```

**Effort:** 1-2 hours
**Benefit:** Working parser immediately

---

## Current Files

### src/PARSER_SPEC.md
Complete specification for morphlib → ISA translation.
- ✅ Syntax defined
- ✅ Transformations documented
- ✅ Built-ins specified

### src/parser.fox (INCOMPLETE)
Attempted implementation with `db` directives.
- ❌ Uses unsupported `db` directive
- ❌ Requires data sections (not in ISA)
- **Status:** Non-functional

### src/parser_mvp.fox (INCOMPLETE)
Attempted minimal implementation.
- ✅ Memory allocation works
- ✅ Syscall I/O works
- ❌ Cannot build output (no store-to-memory)
- **Status:** Blocked

---

## Decision Required

**Question:** Which path to take?

**A. Implement store-to-memory (~2-3 hours)**
- Unblock .fox parser
- Required for v3.2 anyway
- Long-term solution

**B. External parser in Python (~1-2 hours)**
- Working immediately
- Temporary workaround
- Use until ISA complete

**C. Wait and design more**
- Document requirements
- Plan v4.0 architecture
- Skip parser for now

---

## Recommendation

**Implement store-to-memory (Option A)**

**Why:**
1. Required feature anyway
2. Small implementation (similar to load)
3. Unblocks parser in .fox
4. Enables many future features

**Encoding is simple:**
```asm
# mov [rbx+8], rax
# Opcode: 0x89 (vs 0x8B for load)
# Same ModR/M encoding, just swap direction bit

REX.W = 0x48
Opcode = 0x89
ModR/M = 0x43   # mod=01, reg=0 (rax), rm=3 (rbx)
Disp8 = 0x08

Machine code: 48 89 43 08
```

**After implementation:**
- Parser can build buffers
- Full morphlib → ISA translation possible
- Self-hosting closer

---

## Next Steps (If Choosing Option A)

1. Add `mov [mem], reg` to runner_v3.asm
2. Support variants:
   - `mov [reg], reg`
   - `mov [reg+disp8], reg`
   - `mov [reg+disp32], reg`
3. Test with buffer writes
4. Rebuild parser.fox
5. Test morphlib → ISA translation

**Estimated Time:** 2-3 hours
**Blocker Removed:** Parser can proceed

---

## Files Status

| File | Status | Notes |
|------|--------|-------|
| PARSER_SPEC.md | ✅ Complete | Full specification |
| parser.fox | ❌ Blocked | Uses unsupported `db` |
| parser_mvp.fox | ❌ Blocked | No store-to-memory |
| README.md | ✅ Complete | This file |

---

**Last Updated:** 2026-01-23
**Blocked By:** ISA v3.1.0 - No store-to-memory
**Recommended:** Implement store-to-memory in v3.2

---
