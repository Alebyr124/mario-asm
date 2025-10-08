.data
# Doble buffering con direcciones válidas
bitmap_base:    .word 0x10010000
front_buffer:   .word 0x10010000
back_buffer:    .word 0x10040000  # Dirección válida en MARS
current_buffer: .word 0x10010000

# Colores
color_rojo:     .word 0xFFFF0000
color_verde:    .word 0xFF00FF00
color_amarillo: .word 0xFFFFFF00
color_marron:   .word 0xFF8B4513
color_negro:    .word 0xFF000000
color_cafe:     .word 0xFF8B4513
color_blanco:   .word 0xFFFFFFFF

# Física
gravedad:           .word 2
salto_inicial:      .word -20
velocidad_horizontal: .word 4
velocidad_goomba:   .word 1

# Plataformas
plataformas:
    .word 0, 200, 256, 16
    .word 100, 150, 60, 16
    .word 50, 100, 60, 16
    .word 180, 120, 60, 16
    .word -1, -1, -1, -1

# Monedas
monedas:
    .word 120, 130, 0
    .word 70, 80, 0
    .word 200, 100, 0
    .word -1, -1, -1

# Enemigos
enemigos:
    .word 80, 184, 1, 1
    .word 160, 184, -1, 1
    .word 40, 84, 1, 1
    .word -1, -1, 0, -1

# Estado del juego
puntos:         .word 0
vidas:          .word 3
msg_puntos:     .asciiz "Puntos: "
msg_vidas:      .asciiz " | Vidas: "
msg_victoria:   .asciiz "\n¡GANASTE! Recolectaste todas las monedas!\n"
msg_gameover:   .asciiz "\n¡GAME OVER! Perdiste todas las vidas.\n"

# Control
last_key_pressed: .word 0
input_cooldown:   .word 0

.text
.globl main

main:
    # Inicializar posición de Mario
    li $s0, 50       # x jugador
    li $s1, 180      # y jugador
    li $s2, 0        # velY
    li $s3, 0        # velX
    
    # Inicializar buffers
    la $t0, current_buffer
    lw $t1, front_buffer
    sw $t1, 0($t0)
    
    # Dibujar nivel inicial
    jal draw_level
    
loop:
    # Guardar posición anterior en $s5 y $s6
    move $s5, $s0
    move $s6, $s1
    
    # Decrementar cooldown
    lw $t0, input_cooldown
    beq $t0, $zero, check_input
    subi $t0, $t0, 1
    sw $t0, input_cooldown
    j aplicar_fisica
    
check_input:
    # Leer teclado
    li $t0, 0xFFFF0000
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beq $t1, $zero, no_key_pressed
    
    li $t0, 0xFFFF0004
    lw $t1, 0($t0)
    
    lw $t2, last_key_pressed
    beq $t1, $t2, aplicar_fisica
    
    sw $t1, last_key_pressed
    li $t2, 5
    sw $t2, input_cooldown
    j leer_tecla
    
no_key_pressed:
    sw $zero, last_key_pressed
    j aplicar_fisica

leer_tecla:
    # Salto
    li $t0, 119
    beq $t1, $t0, iniciar_salto
    li $t0, 87
    beq $t1, $t0, iniciar_salto
    li $t0, 32
    beq $t1, $t0, iniciar_salto
    
    # Movimiento
    li $t0, 97
    beq $t1, $t0, move_left
    li $t0, 65
    beq $t1, $t0, move_left
    li $t0, 100
    beq $t1, $t0, move_right
    li $t0, 68
    beq $t1, $t0, move_right
    
    # Salir
    li $t0, 113
    beq $t1, $t0, exit_game
    li $t0, 81
    beq $t1, $t0, exit_game
    
    j aplicar_fisica

iniciar_salto:
    jal check_on_platform
    beq $v0, $zero, aplicar_fisica
    la $t0, salto_inicial
    lw $s2, 0($t0)
    j aplicar_fisica

move_left:
    li $t0, 0
    ble $s0, $t0, aplicar_fisica
    la $t0, velocidad_horizontal
    lw $t1, 0($t0)
    sub $s0, $s0, $t1
    j aplicar_fisica

move_right:
    li $t0, 240
    bge $s0, $t0, aplicar_fisica
    la $t0, velocidad_horizontal
    lw $t1, 0($t0)
    add $s0, $s0, $t1
    j aplicar_fisica

aplicar_fisica:
    # Gravedad
    la $t0, gravedad
    lw $t1, 0($t0)
    add $s2, $s2, $t1
    add $s1, $s1, $s2
    
    # Colisiones
    jal check_platform_collision
    jal update_enemies
    jal check_enemy_collision
    jal check_coin_collision
    jal check_game_state
    
actualizar:
    bne $s0, $s5, redibujar_escena
    bne $s1, $s6, redibujar_escena
    jal check_enemies_moving
    bne $v0, $zero, redibujar_escena
    j loop

redibujar_escena:
    # Cambiar a back buffer
    la $t0, back_buffer
    lw $t0, 0($t0)
    sw $t0, bitmap_base
    
    # Limpiar pantalla
    li $a0, 0
    li $a1, 0
    li $a2, 256
    li $a3, 256
    la $t0, color_negro
    lw $s7, 0($t0)
    jal draw_rectangle
    
    # Dibujar todo
    jal draw_level
    
    # Dibujar jugador
    lw $t0, vidas
    ble $t0, $zero, no_draw_player
    move $a0, $s0
    move $a1, $s1
    la $t0, color_rojo
    lw $a2, 0($t0)
    jal draw_square

no_draw_player:
    jal show_score
    jal swap_buffers
    j loop

# ========== DOBLE BUFFERING ==========
swap_buffers:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, front_buffer
    la $t1, back_buffer
    la $t2, current_buffer
    
    lw $t3, 0($t0)
    lw $t4, 0($t1)
    
    sw $t4, 0($t0)
    sw $t3, 0($t1)
    sw $t4, 0($t2)
    sw $t4, bitmap_base
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ========== VERIFICAR PLATAFORMA ==========
check_on_platform:
    la $t0, plataformas
    li $v0, 0
    
check_plat_loop:
    lw $t1, 0($t0)
    beq $t1, -1, check_plat_done
    
    lw $t2, 4($t0)
    lw $t3, 8($t0)
    
    addi $t4, $s1, 16
    bne $t4, $t2, next_plat_check
    
    add $t5, $s0, 16
    blt $t5, $t1, next_plat_check
    
    add $t6, $t1, $t3
    bgt $s0, $t6, next_plat_check
    
    li $v0, 1
    jr $ra

next_plat_check:
    addi $t0, $t0, 16
    j check_plat_loop

check_plat_done:
    jr $ra

# ========== ENEMIGOS SIMPLIFICADOS ==========
update_enemies:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, enemigos
update_enemy_loop:
    lw $t1, 0($t0)
    beq $t1, -1, update_enemies_done
    
    lw $t2, 12($t0)
    beq $t2, $zero, next_enemy_update
    
    # Mover enemigo
    lw $t3, 8($t0)
    la $t4, velocidad_goomba
    lw $t5, 0($t4)
    mul $t6, $t3, $t5
    add $t1, $t1, $t6
    sw $t1, 0($t0)
    
    # Cambiar dirección en bordes
    li $t7, 0
    ble $t1, $t7, change_dir
    li $t7, 240
    bge $t1, $t7, change_dir
    j next_enemy_update

change_dir:
    neg $t3, $t3
    sw $t3, 8($t0)

next_enemy_update:
    addi $t0, $t0, 16
    j update_enemy_loop

update_enemies_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

check_enemy_collision:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, enemigos
enemy_collision_loop:
    lw $t1, 0($t0)
    beq $t1, -1, enemy_collision_done
    
    lw $t2, 12($t0)
    beq $t2, $zero, next_enemy_collision
    
    lw $t3, 4($t0)
    
    # Colisión simple
    sub $t4, $s0, $t1
    abs $t4, $t4
    sub $t5, $s1, $t3
    abs $t5, $t5
    
    li $t6, 16
    bge $t4, $t6, next_enemy_collision
    bge $t5, $t6, next_enemy_collision
    
    # Mario salta sobre enemigo
    sub $t7, $s1, $t3
    blt $t7, $zero, mario_hit
    
    # Eliminar enemigo
    li $t2, 0
    sw $t2, 12($t0)
    lw $t2, puntos
    addi $t2, $t2, 100
    sw $t2, puntos
    j next_enemy_collision

mario_hit:
    # Perder vida
    lw $t2, vidas
    subi $t2, $t2, 1
    sw $t2, vidas
    li $s0, 50
    li $s1, 180
    li $s2, 0
    j enemy_collision_done

next_enemy_collision:
    addi $t0, $t0, 16
    j enemy_collision_loop

enemy_collision_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

check_enemies_moving:
    la $t0, enemigos
    li $v0, 0
check_enemies_loop:
    lw $t1, 0($t0)
    beq $t1, -1, check_enemies_done
    lw $t2, 12($t0)
    beq $t2, $zero, next_enemy_moving
    li $v0, 1
    jr $ra
next_enemy_moving:
    addi $t0, $t0, 16
    j check_enemies_loop
check_enemies_done:
    jr $ra

# ========== DIBUJO SIMPLIFICADO ==========
draw_goomba:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    move $t0, $a0
    move $t1, $a1
    
    # Cuerpo
    move $a0, $t0
    move $a1, $t1
    la $t2, color_cafe
    lw $a2, 0($t2)
    jal draw_square
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_square:
    la $t0, bitmap_base
    lw $t0, 0($t0)
    li $t4, 0
draw_row:
    li $t5, 0
draw_col:
    add $t6, $a0, $t5
    add $t7, $a1, $t4
    
    blt $t6, 0, skip_pixel
    bge $t6, 256, skip_pixel
    blt $t7, 0, skip_pixel
    bge $t7, 256, skip_pixel
    
    li $t1, 256
    mul $t2, $t7, $t1
    add $t2, $t2, $t6
    sll $t2, $t2, 2
    add $t3, $t0, $t2
    sw $a2, 0($t3)
    
skip_pixel:
    addi $t5, $t5, 1
    li $t1, 16
    blt $t5, $t1, draw_col
    addi $t4, $t4, 1
    blt $t4, $t1, draw_row
    jr $ra

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
    blt $t6, 0, rect_skip
    bge $t6, 256, rect_skip
    blt $t7, 0, rect_skip
    bge $t7, 256, rect_skip
    li $t1, 256
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

draw_level:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Plataformas
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
    # Monedas
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
    # Enemigos
    la $t0, enemigos
draw_enemies_loop:
    lw $t1, 0($t0)
    beq $t1, -1, enemies_done
    lw $t2, 12($t0)
    beq $t2, $zero, skip_enemy
    move $a0, $t1
    lw $a1, 4($t0)
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    jal draw_goomba
    lw $t0, 0($sp)
    addi $sp, $sp, 4
skip_enemy:
    addi $t0, $t0, 16
    j draw_enemies_loop

enemies_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

check_platform_collision:
    la $t0, plataformas
coll_plat_loop:
    lw $t1, 0($t0)
    beq $t1, -1, no_collision
    lw $t2, 4($t0)
    lw $t3, 8($t0)
    addi $t4, $s1, 16
    blt $t4, $t2, next_coll_plat
    sub $t5, $t4, $t2
    bgt $t5, 8, next_coll_plat
    add $t5, $s0, 16
    blt $t5, $t1, next_coll_plat
    add $t6, $t1, $t3
    bgt $s0, $t6, next_coll_plat
    subi $s1, $t2, 16
    li $s2, 0
    jr $ra
next_coll_plat:
    addi $t0, $t0, 16
    j coll_plat_loop
no_collision:
    jr $ra

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
    bgt $t3, 20, next_coin
    sub $t4, $s1, $t2
    abs $t4, $t4
    bgt $t4, 20, next_coin
    li $t5, 1
    sw $t5, 8($t0)
    lw $t6, puntos
    addi $t6, $t6, 10
    sw $t6, puntos
next_coin:
    addi $t0, $t0, 12
    j coin_loop
coin_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

check_game_state:
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
    bne $t1, $t2, check_lose
    li $v0, 4
    la $a0, msg_victoria
    syscall
    li $v0, 10
    syscall
check_lose:
    lw $t0, vidas
    bgt $t0, $zero, game_state_done
    li $v0, 4
    la $a0, msg_gameover
    syscall
    li $v0, 10
    syscall
game_state_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

show_score:
    li $v0, 4
    la $a0, msg_puntos
    syscall
    li $v0, 1
    lw $a0, puntos
    syscall
    li $v0, 4
    la $a0, msg_vidas
    syscall
    li $v0, 1
    lw $a0, vidas
    syscall
    li $v0, 11
    li $a0, 10
    syscall
    jr $ra

exit_game:
    li $v0, 10
    syscall