// Copyright 2024 ChipAgents
// UVM Package for CV32E40P Testbench

package cv32e40p_uvm_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Instruction categories for constraint control
  typedef enum {
    INSTR_ALU,           // Basic ALU operations
    INSTR_MUL,           // Multiplication
    INSTR_DIV,           // Division
    INSTR_LOAD,          // Load operations
    INSTR_STORE,         // Store operations
    INSTR_BRANCH,        // Branch instructions
    INSTR_JUMP,          // Jump instructions
    INSTR_CSR,           // CSR operations
    INSTR_PULP_ALU,      // PULP ALU extensions
    INSTR_PULP_MUL,      // PULP multiply-accumulate
    INSTR_PULP_SIMD,     // PULP SIMD operations
    INSTR_PULP_HWLOOP,   // PULP hardware loops
    INSTR_PULP_POSTINC,  // PULP post-increment load/store
    INSTR_FPU            // Floating-point operations
  } instr_type_e;

  // Include all UVM components in dependency order
  `include "cv32e40p_config.sv"
  `include "cv32e40p_instruction_item.sv"
  `include "cv32e40p_enhanced_instruction_item.sv"
  `include "cv32e40p_basic_sequence.sv"
  `include "cv32e40p_alu_random_sequence.sv"
  `include "cv32e40p_division_directed_sequence.sv"
  `include "cv32e40p_hazard_injection_sequence.sv"
  `include "cv32e40p_driver.sv"
  
  // Forward declarations
  typedef class cv32e40p_coverage_collector;
  typedef class cv32e40p_scoreboard;
  
  `include "cv32e40p_monitor.sv"
  `include "cv32e40p_agent.sv"
  `include "cv32e40p_env.sv"
  `include "cv32e40p_basic_test.sv"
  `include "cv32e40p_comprehensive_test.sv"

endpackage