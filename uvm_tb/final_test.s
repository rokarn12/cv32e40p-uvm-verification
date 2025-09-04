.section .text
.global _start
_start:
    # CV32E40P Generated Test Program
    # Instructions: 50
    # Hazards enabled: True
    # PULP enabled: True

    and x19, x29, x28
    sw x13, 1247(x9)
    mulhsu x3, x29, x29
    divu x28, x29, x9
    div x21, x28, x17
    sw x25, -1579(x3)
label_8663:
    remu x4, x29, x30
    sll x10, sp, x17
    sb sp, -1983(x12)
    div x12, x15, x10
    bgeu x12, x14, label_1800
    lw x31, 353(x29)
    or ra, x6, x11
    lb x31, 1445(ra)
    lw x22, 109(x24)
    remu x27, x4, x29
    bltu x14, x16, label_5838
    bne x6, x25, label_2190
    lw x29, 672(x14)
    lb x5, 365(x9)
    divu x3, x5, x8
    bge x22, x20, label_6095
    or x23, x11, x30
    bltu x27, x29, label_4266
    bgeu x15, x27, label_5837
    bltu x19, x24, label_4057
    lb x8, 984(x15)
    lh x5, -1617(x8)
label_6098:
    remu x11, x22, x23
    lw x9, 1827(x11)
    addi x16, x25, -101
    remu x27, x7, x7
    div x5, x8, sp
    div x31, x21, x16
    bge x9, x30, label_1767
    divu x11, x20, x8
    beq x11, x6, label_7597
    add x5, x31, x27
    mulhsu x26, x10, x11
    rem x18, x5, x13
    sb sp, -1729(x5)
    blt x16, x24, label_4368
    lh x26, -1148(x14)
    bne x26, x30, label_4461
    div x24, x7, x8
    lb x27, -158(x10)
    beq x27, sp, label_3165
label_1563:
    beq x3, x11, label_3684
    bge x29, x16, label_2619
    bltu x26, x31, label_1500

    # End of program
    nop
    j _start  # Loop back for continuous testing
