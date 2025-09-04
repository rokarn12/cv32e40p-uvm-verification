.section .text
.global _start
_start:
    # CV32E40P Generated Test Program
    # Instructions: 20
    # Hazards enabled: True
    # PULP enabled: True

    lw x8, -905(x24)
label_4811:
    lw x23, -243(x23)
    bne x23, x25, label_6635
    slli x3, x30, 12
    sw x9, -716(x13)
    lw x24, -710(x6)
    sub x26, x24, sp
    bgeu x9, x5, label_9348
    or x26, x8, x6
    mul x29, x4, x22
label_5315:
    sw x28, -419(x4)
    lb x12, -87(x21)
    sb x22, 123(x5)
    lhu x4, -208(x17)
    div sp, x4, x29
    mulhu x26, sp, x16
    mul sp, x21, x4
    blt x28, x30, label_4872
    bne x29, sp, label_7930
    srli x7, x6, 20

    # End of program
    nop
    j _start  # Loop back for continuous testing
