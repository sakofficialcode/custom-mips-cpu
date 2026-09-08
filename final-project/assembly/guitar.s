addi $sp, $0,  3072 # RAM scratch base (above song data)
addi $s2, $0,  4096 # ms timer MMIO
addi $s3, $0,  70   # 'F'
addi $s4, $0,  80   # 'P'
addi $s5, $0,  4    # N_PLUCK
addi $s6, $0,  5    # N_FRET

# wait until BTNC press
addi $t9, $0,  4097
wait_btnc:
    lw   $t8, 0($t9)
    bne  $t8, $0,  btnc_pressed
    j    wait_btnc
btnc_pressed:
    lw   $s7, 0($s2)

# look up song start in offset table using selected (MMIO 4098)
addi $t9, $0,  4098
lw   $t8, 0($t9)
lw   $s0, 0($t8)

#set pluck memory to 0
addi $t0, $0,  0
init_ps_body:
    sll  $t1, $t0, 2
    add  $t2, $sp, $t1
    sw   $0,  0($t2)
    addi $t0, $t0, 1
    bne  $t0, $s5, init_ps_body

# init pluck servos to rest
# servo[0]=96, servo[1]=97, servo[2]=98, servo[3]=79
addi $t4, $0,  4100
addi $t2, $0,  103
sw   $t2, 0($t4)
addi $t2, $0,  97
sw   $t2, 4($t4)
addi $t2, $0,  101
sw   $t2, 8($t4)
addi $t2, $0,  79
sw   $t2, 12($t4)

# init fret servos to off position per-index
sll  $t6, $s5, 2
addi $t0, $0,  0
addi $t7, $0,  1
init_fret_sv:
    sll  $t3, $t0, 2
    addi $t4, $0,  4100
    add  $t4, $t4, $t6
    add  $t4, $t4, $t3
    and  $t9, $t0, $t7
    bne  $t9, $0,  init_fret_lsb1
    addi $t2, $0,  77
    j    init_fret_store
init_fret_lsb1:
    addi $t2, $0,  26
init_fret_store:
    sw   $t2, 0($t4)
    addi $t0, $t0, 1
    bne  $t0, $s6, init_fret_sv

# init pluck duty LUT (interleaved rest/plucked per index)
add  $t6, $s5, $s6
sll  $t6, $t6, 2
add  $t6, $sp, $t6
addi $t2, $0,  103
sw   $t2, 0($t6)
addi $t2, $0,  59
sw   $t2, 4($t6)
addi $t2, $0,  97
sw   $t2, 8($t6)
addi $t2, $0,  59
sw   $t2, 12($t6)
addi $t2, $0,  101
sw   $t2, 16($t6)
addi $t2, $0,  65
sw   $t2, 20($t6)
addi $t2, $0,  79
sw   $t2, 24($t6)
addi $t2, $0,  43
sw   $t2, 28($t6)

#main parse branching
read_note:
    lw   $t0, 0($s0)
    bne  $t0, $0,  not_done
    j    done
not_done:
    bne  $t0, $s3, not_F
    j    handle_F
not_F:
    bne  $t0, $s4, not_P
    j    handle_P
not_P:
    addi $s0, $s0, 1
    j    read_note

#handle plucking
handle_P:
    addi $s0, $s0, 2
    lw   $t0, 0($s0)
    addi $t0, $t0, -48          # pluck index
    addi $s0, $s0, 1

    jal  parse_timestamp
    add  $a0, $0,  $v0
    jal  wait_until

    sll  $t1, $t0, 2
    add  $t2, $sp, $t1
    lw   $t3, 0($t2)
    addi $t9, $0,  1
    sub  $t3, $t9, $t3          # toggle 0<->1
    sw   $t3, 0($t2)

    addi $t4, $0,  4100
    add  $t4, $t4, $t1

    # LUT[idx][state]: offset = idx*8 + state*4
    sll  $t6, $t0, 3
    sll  $t7, $t3, 2
    add  $t6, $t6, $t7
    add  $t7, $s5, $s6
    sll  $t7, $t7, 2
    add  $t7, $sp, $t7
    add  $t7, $t7, $t6
    lw   $t5, 0($t7)
    sw   $t5, 0($t4)
    j    read_note

#handle fretting
handle_F:
    addi $s0, $s0, 2

    sll  $t8, $s5, 2
    add  $t8, $sp, $t8

    addi $t0, $0,  0            # i = 0

f_read_body:
    lw   $t2, 0($s0)
    addi $t2, $t2, -48          # fret value
    addi $s0, $s0, 1
    sll  $t3, $t0, 2
    add  $t4, $t8, $t3
    sw   $t2, 0($t4)
    addi $t0, $t0, 1
    bne  $t0, $s6, f_read_body

    jal  parse_timestamp
    add  $a0, $0,  $v0
    jal  wait_until

    # fret_servo_base = 4100 + 4*N_PLUCK
    sll  $t9, $s5, 2
    addi $t6, $0,  4100
    add  $t6, $t6, $t9

    addi $t0, $0,  0

f_write_body:
    sll  $t3, $t0, 2
    add  $t4, $t8, $t3
    lw   $t2, 0($t4)
    add  $t5, $t6, $t3
    addi $t7, $0,  1
    and  $t9, $t0, $t7
    bne  $t9, $t2, f_on
    addi $t1, $0,  77
    sw   $t1, 0($t5)
    j    f_next
f_on:
    addi $t1, $0,  26
    sw   $t1, 0($t5)
f_next:
    addi $t0, $t0, 1
    bne  $t0, $s6, f_write_body
    j    read_note

done:
    j    done

parse_timestamp:
    addi $v0, $0,  0
    addi $t5, $0,  48           # '0'
    addi $t2, $0,  32           # ' '
pt_skip:
    lw   $t1, 0($s0)
    bne  $t1, $t2, pt_loop
    addi $s0, $s0, 1
    j    pt_skip
pt_loop:
    lw   $t1, 0($s0)
    blt  $t1, $t5, pt_done
    sll  $t3, $v0, 3
    sll  $t4, $v0, 1
    add  $v0, $t3, $t4
    sub  $t1, $t1, $t5
    add  $v0, $v0, $t1
    addi $s0, $s0, 1
    j    pt_loop
pt_done:
    jr   $ra

wait_until:
    add  $t6, $a0, $s7
wait_until_loop:
    lw   $t7, 0($s2)
    blt  $t7, $t6, wait_until_loop
    jr   $ra
