

; Объявляем публичные функции
public process_grid
public update_cell
public count_neighbors
public init_random_grid
public print_grid
public print_grid_with_generation
public clear_console
public wait_for_space
public parse_number
public skip_spaces
public show_current_rules
public print_number



new_line:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    mov rax, 0xA
    push rax
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    mov rax, 1
    syscall
    pop rax
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

clear_console:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    lea rsi, [clear_screen]
    mov rdx, 7          ; Length of escape sequence
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret


wait_for_space:
    push rdi
    push rsi
    push rdx
    push rbx

.show_prompt:
    call show_current_rules
    mov rax, 1
    mov rdi, 1
    mov rsi, press_space_msg
    mov rdx, 38
    syscall

.read_input:
    ; Читаем всю строку
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall

    ; Проверяем первый символ
    mov al, [input_buffer]
    cmp al, 'q'
    je .quit
    cmp al, 'Q'
    je .quit
    cmp al, 'l'
    je .change_rules
    cmp al, 'L'
    je .change_rules
    cmp al, 10     ; Enter
    je .done
    
    ; Если не распознано - продолжаем
    jmp .show_prompt

.change_rules:
    ; Пропускаем 'L' и пробелы
    mov rsi, input_buffer+1
.skip_spaces:
    cmp byte [rsi], ' '
    jne .parse_rules
    inc rsi
    jmp .skip_spaces

.parse_rules:
    ; Парсим три числа
    call parse_number
    jc .invalid
    mov [birth_rule], al
    
    call skip_spaces
    call parse_number
    jc .invalid
    mov [survive_min], al
    
    call skip_spaces
    call parse_number
    jc .invalid
    mov [survive_max], al
    
    ; Проверяем что строка закончилась
    call skip_spaces
    cmp byte [rsi], 10
    jne .invalid
    
    call clear_console
    jmp .show_prompt

.invalid:
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_input
    mov rdx, 52
    syscall
    jmp .show_prompt

.quit:
    mov rax, 60
    xor rdi, rdi
    syscall

.done:
    call clear_console
    pop rbx
    pop rdx
    pop rsi
    pop rdi
    ret

; Улучшенный парсер чисел
parse_number:
    xor rax, rax
    mov al, [rsi]
    cmp al, '0'
    jb .error
    cmp al, '9'
    ja .error
    sub al, '0'
    inc rsi
    clc
    ret
.error:
    stc
    ret

skip_spaces:
    cmp byte [rsi], ' '
    jne .done
    inc rsi
    jmp skip_spaces
.done:
    ret

show_current_rules:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Выводим сообщение о текущих правилах
    mov rax, 1
    mov rdi, 1
    mov rsi, rules_msg
    mov rdx, 20
    syscall
    
    ; Выводим birth_rule
    movzx rax, byte [birth_rule]
    call print_number
    
    ; Выводим вторую часть сообщения
    mov rax, 1
    mov rdi, 1
    mov rsi, rules_msg2
    mov rdx, 13
    syscall
    
    ; Выводим survive_min
    movzx rax, byte [survive_min]
    call print_number
    
    ; Выводим третью часть сообщения
    mov rax, 1
    mov rdi, 1
    mov rsi, rules_msg3
    mov rdx, 13
    syscall
    
    ; Выводим survive_max
    movzx rax, byte [survive_max]
    call print_number
    
    ; Новая строка
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_number:
    push rsi
    push rdx
    
    add al, '0'
    mov [temp_char], al
    
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    
    pop rdx
    pop rsi
    ret

print_grid_with_generation:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r12

    ; Вычисляем номер поколения (0-99)
    movzx rax, byte [max_iterations]
    sub rax, r12

    ; Преобразуем число в две цифры
    mov rbx, 10
    xor rdx, rdx
    div rbx             ; rax = десятки, rdx = единицы

    ; Сохраняем цифры в буфер
    add al, '0'
    mov [digit_buffer], al
    add dl, '0'
    mov [digit_buffer+1], dl

    ; Копируем цифры в сообщение
    mov al, [digit_buffer]
    mov [msg+11], al    ; Десятки
    mov al, [digit_buffer+1]
    mov [msg+12], al    ; Единицы

    ; Выводим сообщение о поколении
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, 13         ; "Generation: XX" + нулевой байт
    syscall

    ; Выводим перевод строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Выводим само поле
    call print_grid

    pop r12
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

print_grid:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rsi, grid      ; Указатель на начало сетки
    mov rbx, grid_size  ; Счетчик строк
    
    .row_loop:
        mov rcx, grid_size  ; Счетчик столбцов
        push rsi           
        
    .col_loop:
        ; значение клетки
        mov al, [rsi]
        
        mov rdx, 2        
        lea rdi, [dead_cell] 
        cmp al, 0
        jz .print
        lea rdi, [alive_cell] 
        
    .print:
        push rcx
        push rsi
        mov rax, 1          
        mov rsi, rdi       
        mov rdi, 1       
        syscall
        pop rsi
        pop rcx
        
        ;  к следующей клетке
        inc rsi
        dec rcx
        jnz .col_loop
        
        ;  на новую строку
        push rsi
        mov rax, 1          
        mov rdi, 1          
        lea rsi, [newline]
        mov rdx, 1          
        syscall
        pop rsi
        
        pop rsi             ; Восстанавливаем начало строки
        add rsi, grid_size  ; Переходим к следующей строке
        dec rbx
        jnz .row_loop
        
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret


;---[process_grid]---
; Вход: rSI=grid, rDI=new_grid, rCX=size
process_grid:
  push rax
  push rcx 
  push rbx
  push r12
  xor rbx, rbx            ; Индекс клетки (0..size*size-1)
  mov rcx, grid_size * grid_size
    .cell_loop:
        ; Сохраняем указатели и индекс
        push rsi
        push rdi
        push rbx
        
        ; Подсчёт соседей для текущей клетки
        mov rdi, rbx        ; Передаем индекс в RDI
        call count_neighbors ; Результат в DL
        
        ; В process_grid после call count_neighbors:
        

        
                
        ; Восстанавливаем указатель на исходную сетку
        pop rbx
        pop rdi
        pop rsi
        
        ; Получаем текущее состояние и обновляем
        mov al, [rsi + rbx]    ; Текущее состояние
        call update_cell        ; AL = новое состояние
        mov [rdi + rbx], al    ; Сохраняем в new_grid
        
        inc rbx
        cmp rbx, rcx
    jne .cell_loop
        pop r12
        pop rbx
        pop rcx
        pop rax
    ret



;---[update_cell]---
; Вход: AL = текущее состояние (0 или 1)
;       DL = число живых соседей
; Выход: AL = новое состояние (0 или 1)

;---[update_cell]---
; Вход: AL = текущее состояние (0 или 1)
;       DL = число живых соседей
; Выход: AL = новое состояние (0 или 1)
update_cell:
    cmp al, 1
    je .alive_cell

    ; Мертвая клетка - проверяем рождение
    cmp dl, [birth_rule]
    je .make_alive
    xor al, al          ; остается мертвой
    ret

.alive_cell:
    ; Живая клетка - проверяем выживание
    cmp dl, [survive_min]
    jl .make_dead
    cmp dl, [survive_max]
    jg .make_dead
    mov al, 1           ; остается живой
    ret

.make_alive:
    mov al, 1
    ret

.make_dead:
    xor al, al
    ret



;---[count_neighbors]---
; Вход: RSI = указатель на grid, RDI = индекс клетки
; Выход: DL = количество живых соседей (0-8)
count_neighbors:
    push rbx
    push rcx
    push r8
    push r9
    push r10
    push r11
    push rsi       ; Важно сохранить указатель на grid!

    ; Преобразуем индекс в координаты (x,y)
    mov rax, rdi    ; index
    xor rdx, rdx
    mov rbx, grid_size
    div rbx         ; rax = y, rdx = x
    mov r8, rax     ; сохраняем y
    mov r9, rdx     ; сохраняем x

    xor r10, r10    ; обнуляем счетчик соседей

    ; Проверяем всех 8 соседей
    mov r11, -1     ; dy = -1
.y_loop:
    mov rcx, -1     ; dx = -1
.x_loop:
    ; Пропускаем центральную клетку (dx=0, dy=0)
    test r11, r11
    jnz .check_neighbor
    test rcx, rcx
    jz .skip_neighbor

.check_neighbor:
    ; Вычисляем координаты соседа
    mov rax, r8     ; y
    add rax, r11    ; y + dy
    cmp rax, 0
    jl .skip_neighbor   ; если y < 0
    cmp rax, grid_size-1
    jg .skip_neighbor   ; если y >= grid_size

    mov rbx, r9     ; x
    add rbx, rcx    ; x + dx
    cmp rbx, 0
    jl .skip_neighbor   ; если x < 0
    cmp rbx, grid_size-1
    jg .skip_neighbor   ; если x >= grid_size

    ; Вычисляем индекс соседа
    imul rax, grid_size
    add rax, rbx

    ; Проверяем состояние клетки
    cmp byte [rsi + rax], 1
    jne .skip_neighbor
    inc r10         ; увеличиваем счетчик живых соседей

.skip_neighbor:
    inc rcx         ; увеличиваем dx
    cmp rcx, 1
    jle .x_loop     ; dx <= 1

    inc r11         ; увеличиваем dy
    cmp r11, 1
    jle .y_loop     ; dy <= 1

    ; Возвращаем результат в dl
    mov dl, r10b

    pop rsi         ; Восстанавливаем указатель на grid
    pop r11
    pop r10
    pop r9
    pop r8
    pop rcx
    pop rbx
    ret

init_random_grid:
    push rax
    push rcx
    push rdi
    
    mov rdi, grid
    mov rcx, grid_size*grid_size
    
.fill_loop:
    rdrand eax          ; Получаем случайное число
    and al, 1           ; Берем только младший бит
    mov [rdi], al
    inc rdi
    loop .fill_loop
    
    pop rdi
    pop rcx
    pop rax
    ret
    
    ; Преобразуем в 0 или 1
    mov al, [random_byte]
    and al, 1           ; Берем только младший бит
    mov [rdi], al
    
    inc rdi
    loop .fill_loop
    
    ; Закрываем файл
    mov rax, 3          ; sys_close
    mov rdi, [urandom_fd]
    syscall
    
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret

