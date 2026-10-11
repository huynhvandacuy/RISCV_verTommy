#ifndef TOMMY_RISCV_TEST_H
#define TOMMY_RISCV_TEST_H

#define TESTNUM x3

#define RVTEST_RV32U
#define RVTEST_RV64U

#define RVTEST_CODE_BEGIN \
    .section .text.init; \
    .balign 4; \
    .globl _start; \
_start: \
    .option norvc; \
    .option norelax; \
    li TESTNUM, 0;

#define RVTEST_CODE_END

/* Data-memory address 0x3ffc is reserved for test status.
 * PASS = 1; FAIL = failing test number + 2.
 */
#define RVTEST_PASS \
    li x10, 1; \
    li x11, 0x3ffc; \
    sw x10, 0(x11); \
1:  j 1b;

#define RVTEST_FAIL \
    addi x10, TESTNUM, 2; \
    li x11, 0x3ffc; \
    sw x10, 0(x11); \
1:  j 1b;

#define RVTEST_DATA_BEGIN \
    .section .data; \
    .balign 4; \
    .globl begin_signature; \
begin_signature:

#define RVTEST_DATA_END \
    .globl end_signature; \
end_signature:

#endif