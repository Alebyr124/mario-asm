.data
# =============================================================================
# SUPER MARIO BROS - MIPS Assembly
# Display: 512x512 pixels = 64x64 units (8x8 pixels/unit)
# Base: 0x10040000 (heap)
# =============================================================================

# COLORES CORRECTOS (formato: 0x00RRGGBB para MARS)
COLOR_BLACK:     .word 0x00000000
COLOR_SKY:       .word 0x0087CEEB    # Azul cielo
COLOR_GREEN:     .word 0x0000FF00    # Verde brillante
COLOR_RED:       .word 0x00FF0000    # Rojo brillante
COLOR_YELLOW:    .word 0x00FFFF00    # Amarillo brillante
COLOR_BROWN:     .word 0x008B4513    # Marrón

# Configuración
DISPLAY_BASE:    .word 0x10040000
SCREEN_SIZE:     .word 64

# FÍSICA (mejorada)
GRAVITY:         .word 1
JUMP_STRENGTH:   .word -10          # Salto más fuerte
MAX_FALL:        .word 8
MOVE_SPEED:      .word 2             # Más rápido!

# JUGADOR
player_x:        .word 8
player_y:        .word 54
player_vely:     .word 0
player_grounded: .word 1
player_lives:    .word 3
player_score:    .word 0

# NIVEL - [x, y, w, h, tipo, activo]
# tipo: 0=plataforma, 1=moneda, 2=goomba
level:
    # PLATAFORMAS
    .word 0, 58, 64, 6, 0, 1           # Suelo (más alto)
    .word 8, 46, 14, 3, 0, 1           # Plataforma 1
    .word 26, 38, 12, 3, 0, 1          # Plataforma 2
    .word 44, 46, 12, 3, 0, 1          # Plataforma 3
    .word 12, 30, 14, 3, 0, 1          # Plataforma 4
    .word 34, 22, 12, 3, 0, 1          # Plataforma 5
    
    # MONEDAS
    .word 12, 42, 2, 2, 1, 1           # Moneda 1
    .word 30, 34, 2, 2, 1, 1           # Moneda 2
    .word 16, 26, 2, 2, 1, 1           # Moneda 3
    .word 48, 42, 2, 2, 1, 1           # Moneda 4
    .word 38, 18, 2, 2, 1, 1           # Moneda 5
    
    # GOOMBAS
    .word 20, 55, 2, 2, 2, 1           # Goomba 1
    .word 32, 35, 2, 2, 2, 1           # Goomba 2
    .word 48, 43, 2, 2, 2, 1           # Goomba 3
    
    .word -1, -1, -1, -1, -1, -1       # FIN

# Direcciones goombas
goomba_dirs: .word 1, -1, 1

# Contadores
total_coins:     .word 5
coins_collected: .word 0
frame_counter:   .word 0

# Input
last_key:        .word 0
input_delay:     .word 0

# Mensajes
msg_score:  .asciiz "SCORE: "
msg_lives:  .asciiz "  LIVES: "
msg_win:    .asciiz "\n\n=== YOU WIN! ===\nFinal Score: "
msg_lose:   .asciiz "\n\n=== GAME OVER ===\nFinal Score: "

.text
.globl main

main:
    jal init_game

game_loop:
    li $v0, 32
    li $a0, 30                         # 33 FPS
    syscall
    
    lw $t0, frame_counter
    addi $t0, $t0, 1
    sw $t0, frame_counter
    
    jal handle_input
    jal apply_gravity
    jal check_collisions
    
    # Goombas cada 3 frames
    lw $t0, frame_counter
    li $t1, 3
    div $t0, $t1
    mfhi $t0
    bnez $t0, skip_goomba
    jal move_goombas
skip_goomba:
    
    jal render_all
    jal show_hud
    jal check_game_over
    
    j game_loop

# =============================================================================
# INIT
# =============================================================================
init_game:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal clear_screen
    jal render_all
    jal show_hud
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# =============================================================================
# CLEAR SCREEN
# =============================================================================
clear_screen:
    lw $t0, DISPLAY_BASE
    lw $t1, COLOR_SKY
    li $t2, 4096
clear_loop:
    beqz $t2, clear_done
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    subi $t2, $t2, 1
    j clear_loop
clear_done:
    jr $ra

# =============================================================================
# INPUT
# =============================================================================
handle_input:
    lw $t0, input_delay
    beqz $t0, read_input
    subi $t0, $t0, 1
    sw $t0, input_delay
    jr $ra

read_input:
    lui $t0, 0xFFFF
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, no_input
    
    lw $t2, 4($t0)
    lw $t3, last_key
    beq $t2, $t3, no_input
    sw $t2, last_key
    
    li $t4, 1                          # Delay corto
    sw $t4, input_delay
    
    # Procesar tecla
    beq $t2, 97, move_left
    beq $t2, 65, move_left
    beq $t2, 100, move_right
    beq $t2, 68, move_right
    beq $t2, 119, try_jump
    beq $t2, 87, try_jump
    beq $t2, 32, try_jump
    beq $t2, 113, quit
    beq $t2, 81, quit
    j no_input

move_left:
    lw $t0, player_x
    lw $t1, MOVE_SPEED
    sub $t0, $t0, $t1
    bltz $t0, no_input
    sw $t0, player_x
    jr $ra

move_right:
    lw $t0, player_x
    lw $t1, MOVE_SPEED
    add $t0, $t0, $t1
    li $t2, 62
    bgt $t0, $t2, no_input
    sw $t0, player_x
    jr $ra

try_jump:
    lw $t0, player_grounded
    beqz $t0, no_input
    lw $t1, JUMP_STRENGTH
    sw $t1, player_vely
    sw $zero, player_grounded
    jr $ra

quit:
    li $v0, 10
    syscall

no_input:
    sw $zero, last_key
    jr $ra

# =============================================================================
# GRAVITY
# =============================================================================
apply_gravity:
    lw $t0, player_vely
    lw $t1, GRAVITY
    add $t0, $t0, $t1
    
    lw $t2, MAX_FALL
    ble $t0, $t2, grav_ok
    move $t0, $t2
grav_ok:
    sw $t0, player_vely
    
    lw $t1, player_y
    add $t1, $t1, $t0
    sw $t1, player_y
    
    # Caída del mapa
    li $t2, 63
    ble $t1, $t2, grav_done
    jal respawn_player
grav_done:
    jr $ra

respawn_player:
    li $t0, 8
    sw $t0, player_x
    li $t0, 54
    sw $t0, player_y
    sw $zero, player_vely
    li $t0, 1
    sw $t0, player_grounded
    lw $t1, player_lives
    subi $t1, $t1, 1
    sw $t1, player_lives
    jr $ra

# =============================================================================
# COLLISIONS (MEJORADO - arregla traspasar plataformas y monedas)
# =============================================================================
check_collisions:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    sw $zero, player_grounded
    
    lw $s0, player_x
    lw $s1, player_y
    li $s2, 2                          # player width
    li $s3, 2                          # player height
    
    la $t0, level
    li $s7, 0                          # index
    
coll_loop:
    lw $a0, 0($t0)                     # obj_x
    li $t1, -1
    beq $a0, $t1, coll_done
    
    lw $a1, 4($t0)                     # obj_y
    lw $a2, 8($t0)                     # obj_w
    lw $a3, 12($t0)                    # obj_h
    lw $t2, 16($t0)                    # tipo
    lw $t3, 20($t0)                    # activo
    
    beqz $t3, coll_next                # skip si inactivo
    
    # Calcular bordes
    add $t4, $s0, $s2                  # player_right
    add $t5, $s1, $s3                  # player_bottom
    add $t6, $a0, $a2                  # obj_right
    add $t7, $a1, $a3                  # obj_bottom
    
    # Check overlap X
    bge $s0, $t6, coll_next            # player_left >= obj_right
    bge $a0, $t4, coll_next            # obj_left >= player_right
    
    # Check overlap Y
    bge $s1, $t7, coll_next            # player_top >= obj_bottom
    bge $a1, $t5, coll_next            # obj_top >= player_bottom
    
    # HAY COLISIÓN!
    beq $t2, 0, handle_platform
    beq $t2, 1, handle_coin
    beq $t2, 2, handle_goomba
    j coll_next

handle_platform:
    # Verificar dirección
    lw $t8, player_vely
    
    # Si está cayendo (vely > 0)
    blez $t8, check_hit_below
    
    # Calcular distancia player_bottom a obj_top
    sub $t9, $t5, $a1
    bgt $t9, 6, coll_next              # Si está muy adentro, skip
    
    # Colocar sobre plataforma
    sub $a1, $a1, $s3
    sw $a1, player_y
    sw $zero, player_vely
    li $t9, 1
    sw $t9, player_grounded
    j coll_next

check_hit_below:
    # Si está subiendo
    bgez $t8, coll_next
    
    # Golpear desde abajo
    add $t9, $a1, $a3
    sw $t9, player_y
    sw $zero, player_vely
    j coll_next

handle_coin:
    # Recoger moneda
    sw $zero, 20($t0)
    lw $t4, player_score
    addi $t4, $t4, 10
    sw $t4, player_score
    lw $t5, coins_collected
    addi $t5, $t5, 1
    sw $t5, coins_collected
    j coll_next

handle_goomba:
    # Verificar si salta sobre él
    lw $t8, player_vely
    blez $t8, goomba_hurt
    
    # Matar goomba
    sw $zero, 20($t0)
    lw $t4, player_score
    addi $t4, $t4, 50
    sw $t4, player_score
    li $t5, -6
    sw $t5, player_vely
    j coll_next

goomba_hurt:
    addi $sp, $sp, -8
    sw $t0, 0($sp)
    sw $ra, 4($sp)
    jal respawn_player
    lw $t0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

coll_next:
    addi $t0, $t0, 24
    addi $s7, $s7, 1
    j coll_loop

coll_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# =============================================================================
# MOVE GOOMBAS
# =============================================================================
move_goombas:
    la $t0, level
    la $t1, goomba_dirs
    li $t2, 0

goomba_loop:
    lw $t3, 0($t0)
    li $t4, -1
    beq $t3, $t4, goomba_done
    
    lw $t5, 16($t0)
    li $t6, 2
    bne $t5, $t6, goomba_next
    
    lw $t7, 20($t0)
    beqz $t7, goomba_next
    
    # Índice goomba (11, 12, 13)
    subi $t8, $t2, 11
    bltz $t8, goomba_next
    bgt $t8, 2, goomba_next
    
    sll $t9, $t8, 2
    add $a0, $t1, $t9
    lw $a1, 0($a0)
    
    lw $a2, 0($t0)
    add $a2, $a2, $a1
    
    bltz $a2, reverse_goomba
    li $a3, 62
    bgt $a2, $a3, reverse_goomba
    
    sw $a2, 0($t0)
    j goomba_next

reverse_goomba:
    sub $a1, $zero, $a1
    sw $a1, 0($a0)

goomba_next:
    addi $t0, $t0, 24
    addi $t2, $t2, 1
    j goomba_loop

goomba_done:
    jr $ra

# =============================================================================
# RENDER
# =============================================================================
render_all:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_screen
    
    la $s0, level

render_loop:
    lw $a0, 0($s0)
    li $t0, -1
    beq $a0, $t0, render_player
    
    lw $t1, 20($s0)
    beqz $t1, render_next
    
    lw $a1, 4($s0)
    lw $a2, 8($s0)
    lw $a3, 12($s0)
    lw $t2, 16($s0)
    
    beq $t2, 0, color_green
    beq $t2, 1, color_yellow
    lw $s1, COLOR_BROWN
    j do_render

color_green:
    lw $s1, COLOR_GREEN
    j do_render
color_yellow:
    lw $s1, COLOR_YELLOW

do_render:
    addi $sp, $sp, -8
    sw $s0, 0($sp)
    sw $ra, 4($sp)
    jal draw_rect
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8

render_next:
    addi $s0, $s0, 24
    j render_loop

render_player:
    lw $a0, player_x
    lw $a1, player_y
    li $a2, 2
    li $a3, 2
    lw $s1, COLOR_RED
    jal draw_rect
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# =============================================================================
# DRAW RECT
# =============================================================================
draw_rect:
    lw $t0, DISPLAY_BASE
    li $t4, 0

draw_y:
    bge $t4, $a3, draw_done
    li $t5, 0

draw_x:
    bge $t5, $a2, draw_ny
    
    add $t6, $a0, $t5
    add $t7, $a1, $t4
    
    bltz $t6, draw_skip
    li $t8, 64
    bge $t6, $t8, draw_skip
    bltz $t7, draw_skip
    bge $t7, $t8, draw_skip
    
    sll $t1, $t7, 6
    add $t1, $t1, $t6
    sll $t1, $t1, 2
    add $t2, $t0, $t1
    sw $s1, 0($t2)

draw_skip:
    addi $t5, $t5, 1
    j draw_x

draw_ny:
    addi $t4, $t4, 1
    j draw_y

draw_done:
    jr $ra

# =============================================================================
# HUD
# =============================================================================
show_hud:
    li $v0, 4
    la $a0, msg_score
    syscall
    li $v0, 1
    lw $a0, player_score
    syscall
    li $v0, 4
    la $a0, msg_lives
    syscall
    li $v0, 1
    lw $a0, player_lives
    syscall
    li $v0, 11
    li $a0, 13
    syscall
    jr $ra

# =============================================================================
# GAME OVER
# =============================================================================
check_game_over:
    lw $t0, player_lives
    bgtz $t0, check_win
    li $v0, 4
    la $a0, msg_lose
    syscall
    li $v0, 1
    lw $a0, player_score
    syscall
    li $v0, 10
    syscall

check_win:
    lw $t1, coins_collected
    lw $t2, total_coins
    blt $t1, $t2, no_end
    li $v0, 4
    la $a0, msg_win
    syscall
    li $v0, 1
    lw $a0, player_score
    syscall
    li $v0, 10
    syscall

no_end:
    jr $ra