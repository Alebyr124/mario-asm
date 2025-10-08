.data
bitmap_base: .word 0x10010000
color_rojo: .word 0xFFFF0000      # Mario (rojo)
color_verde: .word 0xFF00FF00     # Plataformas
color_amarillo: .word 0xFFFFFF00  # Moneda
color_negro: .word 0xFF000000     # Fondo

gravedad: .word 2
salto_inicial: .word -20
velocidad_horizontal: .word 4
max_vel_caida: .word 15

# Plataformas: x, y, ancho, alto (escaladas para 512x512)
plataformas:
    .word 0, 400, 512, 32      # Suelo principal
    .word 200, 300, 120, 32    # Plataforma 1
    .word 100, 200, 120, 32    # Plataforma 2
    .word 360, 240, 120, 32    # Plataforma 3
    .word -1, -1, -1, -1       # Terminador

# Monedas: x, y, recolectada (0=no, 1=sí)
monedas:
    .word 240, 260, 0
    .word 140, 160, 0
    .word 400, 200, 0
    .word -1, -1, -1           # Terminador

puntos: .word 0
msg_puntos: .asciiz "Puntos: "
msg_victoria: .asciiz "\n¡GANASTE! Recolectaste todas las monedas!\n"

# Variables para control de input
last_key_pressed: .word 0
input_cooldown: .word 0

.text
.globl main

main:
    # Inicializar posición de Mario
    li $s0, 100      # x jugador
    li $s1, 360      # y jugador (sobre el suelo)
    li $s2, 0        # velY
    li $s3, 0        # velX
    
    # Dibujar nivel inicial
    jal draw_level
    
loop:
    # Guardar posición anterior
    move $t9, $s0
    move $t8, $s1
    
    # Decrementar cooldown de input
    lw $t0, input_cooldown
    beq $t0, $zero, check_input
    subi $t0, $t0, 1
    sw $t0, input_cooldown
    j aplicar_fisica
    
check_input:
    # Leer teclado
    li $t1, 0xFFFF0000
    lw $t2, 0($t1)
    andi $t2, $t2, 1
    beq $t2, $zero, no_key_pressed
    
    # Hay tecla presionada
    li $t3, 0xFFFF0004
    lw $t4, 0($t3)
    
    # Verificar si es la misma tecla que antes
    lw $t5, last_key_pressed
    beq $t4, $t5, aplicar_fisica
    
    # Es una tecla nueva, procesarla
    sw $t4, last_key_pressed
    
    # Establecer cooldown (3 frames)
    li $t6, 3
    sw $t6, input_cooldown
    
    j leer_tecla
    
no_key_pressed:
    # No hay tecla, resetear last_key
    sw $zero, last_key_pressed
    j aplicar_fisica

leer_tecla:
    # Salto con W o espacio
    li $t5, 119  # 'w'
    beq $t4, $t5, iniciar_salto
    li $t5, 87   # 'W'
    beq $t4, $t5, iniciar_salto
    li $t5, 32   # espacio
    beq $t4, $t5, iniciar_salto
    
    # Movimiento horizontal
    li $t5, 97   # 'a'
    beq $t4, $t5, move_left
    li $t5, 65   # 'A'
    beq $t4, $t5, move_left
    li $t5, 100  # 'd'
    beq $t4, $t5, move_right
    li $t5, 68   # 'D'
    beq $t4, $t5, move_right
    
    # Salir
    li $t5, 113  # 'q'
    beq $t4, $t5, exit_game
    li $t5, 81   # 'Q'
    beq $t4, $t5, exit_game
    
    j aplicar_fisica

iniciar_salto:
    # Verificar si está en una plataforma
    jal check_on_platform
    beq $v0, $zero, aplicar_fisica
    
    la $t1, salto_inicial
    lw $s2, 0($t1)
    j aplicar_fisica

move_left:
    li $t0, 0
    ble $s0, $t0, aplicar_fisica
    la $t1, velocidad_horizontal
    lw $t2, 0($t1)
    sub $s0, $s0, $t2
    j aplicar_fisica

move_right:
    li $t0, 480
    bge $s0, $t0, aplicar_fisica
    la $t1, velocidad_horizontal
    lw $t2, 0($t1)
    add $s0, $s0, $t2
    j aplicar_fisica

aplicar_fisica:
    # Aplicar gravedad
    la $t1, gravedad
    lw $t2, 0($t1)
    add $s2, $s2, $t2       # velY += gravedad
    
    # Limitar velocidad de caída máxima
    la $t1, max_vel_caida
    lw $t3, 0($t1)
    blt $s2, $t3, vel_ok
    move $s2, $t3
vel_ok:
    
    add $s1, $s1, $s2       # y += velY
    
    # Verificar colisión con plataformas
    jal check_platform_collision
    
    # Verificar colisión con monedas
    jal check_coin_collision
    
    # Verificar victoria
    jal check_victory
    
actualizar:
    # Solo redibujar si cambió la posición
    bne $s0, $t9, redibujar
    bne $s1, $t8, redibujar
    j loop

redibujar:
    # Borrar jugador anterior
    move $a0, $t9
    move $a1, $t8
    la $t0, color_negro
    lw $a2, 0($t0)
    jal draw_square
    
    # Dibujar jugador nuevo
    move $a0, $s0
    move $a1, $s1
    la $t0, color_rojo
    lw $a2, 0($t0)
    jal draw_square
    
    # Mostrar puntos
    jal show_score
    
    j loop

exit_game:
    li $v0, 10
    syscall

# Dibuja un cuadrado de 32x32 en (x=$a0, y=$a1) con color $a2
draw_square:
    la $t0, bitmap_base
    lw $t0, 0($t0)
    li $t4, 0
draw_row:
    li $t5, 0
draw_col:
    add $t6, $a0, $t5
    add $t7, $a1, $t4
    
    # Verificar límites
    blt $t6, 0, skip_pixel
    bge $t6, 512, skip_pixel
    blt $t7, 0, skip_pixel
    bge $t7, 512, skip_pixel
    
    li $t1, 512
    mul $t2, $t7, $t1
    add $t2, $t2, $t6
    sll $t2, $t2, 2
    add $t3, $t0, $t2
    sw $a2, 0($t3)
    
skip_pixel:
    addi $t5, $t5, 1
    li $t8, 32
    blt $t5, $t8, draw_col
    addi $t4, $t4, 1
    blt $t4, $t8, draw_row
    jr $ra

# Dibuja un rectángulo en (x=$a0, y=$a1) de tamaño (w=$a2, h=$a3) con color en $s7
draw_rectangle:
    la $t0, bitmap_base
    lw $t0, 0($t0)
    li $t4, 0
rect_row:
    bge $t4, $a3, rect_done
    li $t5, 0
rect_col:
    bge $t5, $a2, rect_next_row
    
    add $t6, $a0, $t5
    add $t7, $a1, $t4
    
    # Verificar límites
    blt $t6, 0, rect_skip
    bge $t6, 512, rect_skip
    blt $t7, 0, rect_skip
    bge $t7, 512, rect_skip
    
    li $t1, 512
    mul $t2, $t7, $t1
    add $t2, $t2, $t6
    sll $t2, $t2, 2
    add $t3, $t0, $t2
    sw $s7, 0($t3)
    
rect_skip:
    addi $t5, $t5, 1
    j rect_col
rect_next_row:
    addi $t4, $t4, 1
    j rect_row
rect_done:
    jr $ra

# Dibuja el nivel completo
draw_level:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Dibujar todas las plataformas
    la $t0, plataformas
draw_platforms_loop:
    lw $a0, 0($t0)
    beq $a0, -1, platforms_done
    
    lw $a1, 4($t0)
    lw $a2, 8($t0)
    lw $a3, 12($t0)
    
    la $t1, color_verde
    lw $s7, 0($t1)
    
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_rectangle
    
    lw $t0, 0($sp)
    addi $sp, $sp, 4
    
    addi $t0, $t0, 16
    j draw_platforms_loop

platforms_done:
    # Dibujar todas las monedas
    la $t0, monedas
draw_coins_loop:
    lw $t1, 0($t0)
    beq $t1, -1, coins_done
    
    lw $t2, 8($t0)
    bne $t2, $zero, skip_coin
    
    move $a0, $t1
    lw $a1, 4($t0)
    la $t3, color_amarillo
    lw $a2, 0($t3)
    
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    
    jal draw_square
    
    lw $t0, 0($sp)
    addi $sp, $sp, 4

skip_coin:
    addi $t0, $t0, 12
    j draw_coins_loop

coins_done:
    # Dibujar Mario inicial
    move $a0, $s0
    move $a1, $s1
    la $t0, color_rojo
    lw $a2, 0($t0)
    jal draw_square
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Verifica si Mario está sobre una plataforma
check_on_platform:
    la $t0, plataformas
check_plat_loop:
    lw $t1, 0($t0)
    beq $t1, -1, not_on_platform
    
    lw $t2, 4($t0)
    lw $t3, 8($t0)
    
    addi $t4, $s1, 32
    
    # Verificar si está en la superficie (tolerancia de ±3 pixels)
    sub $t5, $t4, $t2
    blt $t5, -3, next_check_plat
    bgt $t5, 3, next_check_plat
    
    add $t5, $s0, 32
    blt $t5, $t1, next_check_plat
    
    add $t6, $t1, $t3
    bgt $s0, $t6, next_check_plat
    
    li $v0, 1
    jr $ra

next_check_plat:
    addi $t0, $t0, 16
    j check_plat_loop

not_on_platform:
    li $v0, 0
    jr $ra

# Verifica colisión con plataformas y ajusta posición
check_platform_collision:
    la $t0, plataformas
coll_plat_loop:
    lw $t1, 0($t0)
    beq $t1, -1, no_collision
    
    lw $t2, 4($t0)
    lw $t3, 8($t0)
    
    addi $t4, $s1, 32
    
    blt $t4, $t2, next_coll_plat
    sub $t5, $t4, $t2
    bgt $t5, 15, next_coll_plat
    
    add $t5, $s0, 32
    blt $t5, $t1, next_coll_plat
    
    add $t6, $t1, $t3
    bgt $s0, $t6, next_coll_plat
    
    subi $s1, $t2, 32
    li $s2, 0
    jr $ra

next_coll_plat:
    addi $t0, $t0, 16
    j coll_plat_loop

no_collision:
    jr $ra

# Verifica colisión con monedas
check_coin_collision:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, monedas
coin_loop:
    lw $t1, 0($t0)
    beq $t1, -1, coin_done
    
    lw $t2, 8($t0)
    bne $t2, $zero, next_coin
    
    lw $t2, 4($t0)
    
    sub $t3, $s0, $t1
    abs $t3, $t3
    bgt $t3, 40, next_coin
    
    sub $t4, $s1, $t2
    abs $t4, $t4
    bgt $t4, 40, next_coin
    
    li $t5, 1
    sw $t5, 8($t0)
    
    lw $t6, puntos
    addi $t6, $t6, 10
    sw $t6, puntos
    
    move $a0, $t1
    move $a1, $t2
    la $t7, color_negro
    lw $a2, 0($t7)
    
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    jal draw_square
    lw $t0, 0($sp)
    addi $sp, $sp, 4

next_coin:
    addi $t0, $t0, 12
    j coin_loop

coin_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Muestra la puntuación
show_score:
    li $v0, 4
    la $a0, msg_puntos
    syscall
    
    li $v0, 1
    lw $a0, puntos
    syscall
    
    li $v0, 11
    li $a0, 10
    syscall
    
    jr $ra

# Verifica si ganó el juego
check_victory:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, monedas
    li $t1, 0
    li $t2, 0
    
count_coins:
    lw $t3, 0($t0)
    beq $t3, -1, check_win
    
    addi $t1, $t1, 1
    lw $t4, 8($t0)
    add $t2, $t2, $t4
    
    addi $t0, $t0, 12
    j count_coins

check_win:
    bne $t1, $t2, no_win
    
    li $v0, 4
    la $a0, msg_victoria
    syscall
    
    li $v0, 10
    syscall

no_win:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra