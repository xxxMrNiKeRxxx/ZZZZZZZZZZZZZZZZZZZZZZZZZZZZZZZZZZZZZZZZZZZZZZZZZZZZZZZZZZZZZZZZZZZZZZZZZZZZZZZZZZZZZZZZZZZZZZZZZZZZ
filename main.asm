format ELF64

include "logic.asm"


section '.bss' writable
    temp_char rb 1      ; Temporary buffer for keyboard input
    public temp_char

section '.data' writable

    public grid
    public new_grid
    public debug_msg
    public urandom_fd
    public random_byte
    public msg
    public digit_buffer
    public alive_cell
    public dead_cell
    public newline
    public clear_screen
    public press_space_msg
    public cell_buf
    public birth_rule
    public survive_min
    public survive_max
    public max_iterations
    public rules_prompt
    public input_buffer
    public rules_msg
    public rules_msg2
    public rules_msg3
    public invalid_input
    

    macro public_const [name] { public name }
    public_const grid_size  ; Объявляем константу как публичную

    grid_size = 15  ; Используем '=' вместо 'equ' для числовых констант



    grid db grid_size*grid_size dup(0)
    new_grid db grid_size*grid_size dup(0)
    debug_msg db '0', 10

    urandom_fd dq 0
    random_byte db 0

    msg db "Generation: 00", 0
    digit_buffer rb 2
    alive_cell db "1 ", 0
    dead_cell db "0 ", 0
    newline db 10, 0
    clear_screen db 27,"[H",27,"[2J",0
    press_space_msg db "Press ENTER to continue or Q to quit...", 10, 0
    cell_buf rb 1

    birth_rule db 3
    survive_min db 2
    survive_max db 4

    max_iterations db 100

    rules_prompt db "Enter new rules (birth survive_min survive_max): ", 0
    input_buffer rb 32
    rules_msg db "Current rules: birth=", 0
    rules_msg2 db " survive_min=", 0
    rules_msg3 db " survive_max=", 0
    invalid_input db 10,"Invalid input! Using default rules.",10,0


section '.text' executable
public _start

_start:
    call init_random_grid
    movzx r12, byte [max_iterations]  ; Load number of generations
    call clear_console
    call print_grid_with_generation

.main_loop:
    ; Wait for SPACE key press
    call wait_for_space
    
    ; Check if user wants to quit (Q pressed)
    cmp al, 'q'
    je .exit
    cmp al, 'Q'
    je .exit

    ; Process the grid
    mov esi, grid
    mov edi, new_grid
    mov ecx, grid_size
    call process_grid

    ; Copy new_grid back to grid
    mov ecx, grid_size * grid_size
    lea rsi, [new_grid]
    lea rdi, [grid]
    rep movsb

    ; Decrement counter and check
    dec r12
    jz .exit
    
    ; Clear console and print next generation
    call clear_console
    call print_grid_with_generation
    jmp .main_loop

.exit:
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; exit code 0
    syscall

