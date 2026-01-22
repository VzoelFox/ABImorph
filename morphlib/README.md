# morphlib - Morph Standard Library

Standard library for Morph programming, written in high-level `.fox` syntax.

## Overview

morphlib provides essential functionality for building Morph applications:
- Memory management (heap allocation, arenas)
- Runtime support (routines, concurrency primitives)
- I/O operations (file, network)
- Data structures (hashmaps, buffers, strings)
- System utilities (signals, monitoring, metrics)

## Modules

### Memory Management

**alloc.fox** - Heap Allocator
```fox
fungsi heap_init
fungsi mem_alloc      ; Input: rdi (size) -> Output: rax (ptr)
fungsi mem_free       ; Input: rdi (ptr)
fungsi mem_check_magic
```

**buffer.fox** - Dynamic Buffers
```fox
fungsi buffer_create
fungsi buffer_append
fungsi buffer_free
```

### Runtime & Concurrency

**morphroutine.fox** - Runtime Hierarchy
```fox
; Structures: Unit -> Shard -> Fragment
fungsi routine_init_unit
fungsi routine_init_shard
fungsi routine_init_fragment
fungsi routine_spawn
fungsi routine_wait
```

**daemon.fox** - Circuit Breaker & Monitoring
```fox
fungsi daemon_handler     ; Signal handler for memory monitoring
fungsi daemon_setup       ; Initialize daemon with SIGALRM
```

**signal.fox** - Signal Handling
```fox
fungsi signal_setup
fungsi signal_handler
```

### Data Structures

**hashmap.fox** - Hash Table
```fox
fungsi hashmap_create
fungsi hashmap_put
fungsi hashmap_get
fungsi hashmap_hash       ; Hash function
```

**string.fox** - String Operations
```fox
fungsi string_length
fungsi string_copy
fungsi string_compare
fungsi string_concat
```

**string_ext.fox** - Extended String Utilities
```fox
fungsi string_to_int
fungsi string_split
fungsi string_trim
```

### I/O & System

**io.fox** - File I/O
```fox
fungsi file_open
fungsi file_read
fungsi file_write
fungsi file_close
```

**sys.fox** - System Calls
```fox
fungsi sys_write
fungsi sys_read
fungsi sys_open
fungsi sys_close
fungsi sys_brk
fungsi sys_mmap
fungsi sys_exit
```

**jaringan.fox** - Network Operations
```fox
fungsi net_socket
fungsi net_connect
fungsi net_send
fungsi net_recv
```

### Utilities

**aritmatika.fox** - Arithmetic Helpers
**logika.fox** - Logic Utilities
**float.fox** - Floating Point Operations
**sensor.fox** - Monitoring Utilities
**metrik.fox** - Metrics Collection
**snapshot.fox** - Memory Snapshots

## Syntax

morphlib uses high-level `.fox` syntax:

```fox
fungsi nama_fungsi
    ; Function body
    mov rax, 42
    ret
tutup_fungsi

jika_sama
    ; If body
tutup_jika

jika_beda
    ; Else body
tutup_jika

loop
    ; Loop body
tutup_loop
```

## Usage

Include morphlib modules in your `.fox` programs:

```fox
; Your program
include "morphlib/alloc.fox"
include "morphlib/io.fox"

fungsi main
    call heap_init

    mov rdi, 1024
    call mem_alloc
    mov r15, rax        ; Save pointer

    ; Use allocated memory
    ; ...

    mov rdi, r15
    call mem_free
    ret
tutup_fungsi
```

## Compilation

morphlib modules are compiled using the `morph` compiler:

```bash
# Compile program with morphlib
./bin/morph -o myprogram program.fox
```

The compiler handles includes and generates native x86-64 code.

## Dependencies

- morph compiler (v1.1.0+)
- Linux x86-64
- No external libraries required

## Examples

See `../samples/` directory for complete examples using morphlib.

## License

MIT License - See ../LICENSE

---

**morphlib** - Foundation library for Morph ecosystem development.
