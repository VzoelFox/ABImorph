format ELF64 executable 3
entry start

segment readable executable

start:
    ; --- Argument Parsing ---
    pop rcx             ; argc
    cmp rcx, 2
    jl error_usage

    pop rdi             ; argv[0]
    pop rdi             ; argv[1] (filename)
    mov [filename], rdi

    ; --- Open File ---
    mov rax, 2          ; sys_open
    mov rsi, 0          ; O_RDONLY
    mov rdx, 0
    syscall
    test rax, rax
    js error_open
    mov [fd], rax

    ; --- Get File Size ---
    mov rax, 8          ; sys_lseek
    mov rdi, [fd]
    mov rsi, 0
    mov rdx, 2          ; SEEK_END
    syscall
    mov [filesize], rax

    ; Reset cursor
    mov rax, 8
    mov rdi, [fd]
    mov rsi, 0
    mov rdx, 0          ; SEEK_SET
    syscall

    ; --- Mmap Source File ---
    mov rax, 9          ; sys_mmap
    mov rdi, 0
    mov rsi, [filesize]
    mov rdx, 1          ; PROT_READ
    mov r10, 2          ; MAP_PRIVATE
    mov r8, [fd]
    mov r9, 0
    syscall
    test rax, rax
    js error_mmap
    mov [source_ptr], rax
    mov [source_curr], rax

    ; Calculate source end
    mov rbx, [source_ptr]
    add rbx, [filesize]
    mov [source_end], rbx

    ; --- Mmap Executable Buffer (JIT Area) ---
    mov rax, 9          ; sys_mmap
    mov rdi, 0
    mov rsi, 1048576    ; 1MB
    mov rdx, 7          ; PROT_READ | PROT_WRITE | PROT_EXEC
    mov r10, 34         ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    mov r9, 0
    syscall
    test rax, rax
    js error_mmap
    mov [jit_ptr], rax
    mov [jit_cursor], rax

    ; --- Header Check ---
    ; Read first 8 bytes
    mov rsi, [source_ptr]
    mov rdi, header_magic
    mov rcx, 8
    repe cmpsb
    jne error_header

    add [source_curr], 8

    ; --- Parsing Loop ---
parse_loop:
    call skip_whitespace
    call check_eof
    test rax, rax
    jnz execute_jit

    call parse_token

    ; Check "syscall"
    mov rdi, token_buffer
    mov rsi, str_syscall
    call strcmp
    test rax, rax
    jz emit_syscall

    ; Check "mov.r64.imm64"
    mov rdi, token_buffer
    mov rsi, str_mov_r64_imm64
    call strcmp
    test rax, rax
    jz emit_mov_r64_imm64

    ; If unknown token, ignore for now (or error)
    ; For robustness, let's just loop (maybe it's a comment or unsupported instruction)
    ; But better to fail on unknown to be sure
    jmp error_unknown

emit_syscall:
    mov rdi, [jit_cursor]
    mov word [rdi], 0x050F ; syscall instruction (0F 05)
    add [jit_cursor], 2
    jmp parse_loop

emit_mov_r64_imm64:
    ; Parse Register
    call skip_whitespace
    call parse_token
    call get_register_id
    cmp rax, -1
    je error_unknown
    mov rbx, rax ; reg id

    ; Parse Immediate
    call skip_whitespace
    call parse_token
    call parse_int
    mov rdx, rax ; imm value

    ; Emit: 48 B8+rd <imm64>
    mov rdi, [jit_cursor]
    mov byte [rdi], 0x48
    inc rdi

    mov al, 0xB8
    add al, bl ; add reg id
    mov byte [rdi], al
    inc rdi

    mov [rdi], rdx ; imm64
    add rdi, 8

    mov [jit_cursor], rdi
    jmp parse_loop

execute_jit:
    mov rax, [jit_ptr]
    call rax

    ; Clean exit from runner
    mov rax, 60
    mov rdi, 0
    syscall

; --- Helper Functions ---

; Skip whitespace and comments
; Advances [source_curr]
skip_whitespace:
.loop:
    call check_eof
    test rax, rax
    jnz .done

    mov rsi, [source_curr]
    mov al, [rsi]

    ; Check for comment ';'
    cmp al, ';'
    je .skip_comment

    cmp al, ' '
    je .advance
    cmp al, 10 ; newline
    je .advance
    cmp al, 13 ; CR
    je .advance
    cmp al, 9  ; tab
    je .advance

    jmp .done

.advance:
    inc [source_curr]
    jmp .loop

.skip_comment:
    ; Skip until newline
    inc [source_curr]
    call check_eof
    test rax, rax
    jnz .done
    mov rsi, [source_curr]
    mov al, [rsi]
    cmp al, 10
    je .loop ; Found newline, go back to whitespace check
    jmp .skip_comment

.done:
    ret

; Parse token into token_buffer
; Stops at whitespace or EOF
parse_token:
    mov rdi, token_buffer
    mov rsi, [source_curr]
.loop:
    call check_eof
    test rax, rax
    jnz .done

    mov al, [rsi]
    cmp al, ' '
    je .done
    cmp al, 10
    je .done
    cmp al, 13
    je .done
    cmp al, 9
    je .done
    cmp al, ';'
    je .done

    mov [rdi], al
    inc rdi
    inc rsi
    inc [source_curr]
    jmp .loop

.done:
    mov byte [rdi], 0 ; null terminator
    ret

; Check EOF
; Returns 1 in RAX if EOF, 0 otherwise
check_eof:
    mov rax, [source_curr]
    cmp rax, [source_end]
    jae .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret

; strcmp(rdi, rsi) -> rax (0 if equal, non-zero otherwise)
strcmp:
    push rsi
    push rdi
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .diff
    test al, al
    jz .equal
    inc rdi
    inc rsi
    jmp .loop
.diff:
    mov rax, 1
    pop rdi
    pop rsi
    ret
.equal:
    xor rax, rax
    pop rdi
    pop rsi
    ret

; get_register_id() -> rax
; Reads token_buffer, returns ID (0-15) or -1 if not found
get_register_id:
    push rbx

    ; rax
    mov rdi, token_buffer
    mov rsi, reg_rax
    call strcmp
    test rax, rax
    jz .found_rax

    ; rdi
    mov rdi, token_buffer
    mov rsi, reg_rdi
    call strcmp
    test rax, rax
    jz .found_rdi

    ; rsi
    mov rdi, token_buffer
    mov rsi, reg_rsi
    call strcmp
    test rax, rax
    jz .found_rsi

    ; rdx
    mov rdi, token_buffer
    mov rsi, reg_rdx
    call strcmp
    test rax, rax
    jz .found_rdx

    ; Not found
    pop rbx
    mov rax, -1
    ret

.found_rax:
    pop rbx
    mov rax, 0
    ret
.found_rdi:
    pop rbx
    mov rax, 7
    ret
.found_rsi:
    pop rbx
    mov rax, 6
    ret
.found_rdx:
    pop rbx
    mov rax, 2
    ret

; parse_int() -> rax
; Parses decimal from token_buffer
parse_int:
    push rbx
    push rcx
    mov rsi, token_buffer
    xor rax, rax
    xor rcx, rcx
.loop:
    mov cl, [rsi]
    test cl, cl
    jz .done

    sub cl, '0'
    ; TODO: check if valid digit

    imul rax, 10
    add rax, rcx

    inc rsi
    jmp .loop
.done:
    pop rcx
    pop rbx
    ret

; Errors
error_usage:
    mov rax, 60
    mov rdi, 1
    syscall
error_open:
    mov rax, 60
    mov rdi, 2
    syscall
error_mmap:
    mov rax, 60
    mov rdi, 3
    syscall
error_header:
    mov rax, 60
    mov rdi, 4
    syscall
error_unknown:
    mov rax, 60
    mov rdi, 5
    syscall

segment readable writeable
fd dq 0
filesize dq 0
source_ptr dq 0
source_curr dq 0
source_end dq 0
jit_ptr dq 0
jit_cursor dq 0
filename dq 0

header_magic db 'VZOELFOX'
str_syscall db 'syscall', 0
str_mov_r64_imm64 db 'mov.r64.imm64', 0

reg_rax db 'rax', 0
reg_rdi db 'rdi', 0
reg_rsi db 'rsi', 0
reg_rdx db 'rdx', 0

token_buffer rb 256
