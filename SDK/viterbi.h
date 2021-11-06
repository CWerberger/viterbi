// Generated register defines for viterbi

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _VITERBI_REG_DEFS_
#define _VITERBI_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define VITERBI_PARAM_REG_WIDTH 32

// DataX Input
#define VITERBI_DATAX(id) (Viterbi ## id ## _BASE_ADDR + 0x0)
#define VITERBI_DATAX_REG_OFFSET 0x0
#define VITERBI_DATAX_DATAX_MASK 0xff
#define VITERBI_DATAX_DATAX_OFFSET 0
#define VITERBI_DATAX_DATAX_FIELD \
  ((bitfield_field32_t) { .mask = VITERBI_DATAX_DATAX_MASK, .index = VITERBI_DATAX_DATAX_OFFSET })

// DataY Input.
#define VITERBI_DATAY(id) (Viterbi ## id ## _BASE_ADDR + 0x4)
#define VITERBI_DATAY_REG_OFFSET 0x4
#define VITERBI_DATAY_DATAY_MASK 0xff
#define VITERBI_DATAY_DATAY_OFFSET 0
#define VITERBI_DATAY_DATAY_FIELD \
  ((bitfield_field32_t) { .mask = VITERBI_DATAY_DATAY_MASK, .index = VITERBI_DATAY_DATAY_OFFSET })

// results
#define VITERBI_BITOUT(id) (Viterbi ## id ## _BASE_ADDR + 0x8)
#define VITERBI_BITOUT_REG_OFFSET 0x8
#define VITERBI_BITOUT_BITOUT_BIT 0

// Controls trigger signal of the gf arithmetic.
#define VITERBI_CTRL1(id) (Viterbi ## id ## _BASE_ADDR + 0xc)
#define VITERBI_CTRL1_REG_OFFSET 0xc
#define VITERBI_CTRL1_TRIGGER_BIT 0

// Reset Viterbi.
#define VITERBI_FLUSH(id) (Viterbi ## id ## _BASE_ADDR + 0x10)
#define VITERBI_FLUSH_REG_OFFSET 0x10
#define VITERBI_FLUSH_TRIGGER_BIT 0

// Tell if the Output is valid.
#define VITERBI_VALID(id) (Viterbi ## id ## _BASE_ADDR + 0x14)
#define VITERBI_VALID_OUTPUT_REG_OFFSET 0x14
#define VITERBI_VALID_OUTPUT_STATUS_BIT 0

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _VITERBI_REG_DEFS_
// End generated register defines for viterbi