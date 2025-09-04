// CV32E40P Coverage Model
// Comprehensive functional coverage for RISC-V core verification

`ifndef CV32E40P_COVERAGE_MODEL_SV
`define CV32E40P_COVERAGE_MODEL_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// Forward declaration - actual item will be included by environment
typedef class cv32e40p_enhanced_instruction_item;

class cv32e40p_coverage_model extends uvm_subscriber #(cv32e40p_enhanced_instruction_item);
  `uvm_component_utils(cv32e40p_coverage_model)

  // Coverage groups
  covergroup instruction_type_cg with function sample(int itype);
    option.per_instance = 1;
    option.name = "instruction_type_coverage";
    
    INSTR_TYPE: coverpoint itype {
      bins alu_ops = {0};        // INSTR_ALU
      bins mul_ops = {1};        // INSTR_MUL
      bins div_ops = {2};        // INSTR_DIV
      bins load_ops = {3};       // INSTR_LOAD
      bins store_ops = {4};      // INSTR_STORE
      bins branch_ops = {5};     // INSTR_BRANCH
      bins jump_ops = {6};       // INSTR_JUMP
      bins csr_ops = {7};        // INSTR_CSR
      bins pulp_alu_ops = {8};   // INSTR_PULP_ALU
      bins pulp_mul_ops = {9};   // INSTR_PULP_MUL
      bins pulp_simd_ops = {10}; // INSTR_PULP_SIMD
      bins pulp_hwloop_ops = {11}; // INSTR_PULP_HWLOOP
      bins pulp_postinc_ops = {12}; // INSTR_PULP_POSTINC
      bins fpu_ops = {13};       // INSTR_FPU
    }
  endgroup

  covergroup alu_operations_cg with function sample(int op);
    option.per_instance = 1;
    option.name = "alu_operations_coverage";
    
    ALU_OP: coverpoint op {
      bins add_sub = {[0:1]};      // ALU_ADD, ALU_SUB
      bins logical = {[2:4]};      // ALU_AND, ALU_OR, ALU_XOR
      bins shifts = {[5:7]};       // ALU_SLL, ALU_SRL, ALU_SRA
      bins compare = {[8:9]};      // ALU_SLT, ALU_SLTU
      bins immediate = {[10:16]};  // Immediate operations
    }
  endgroup

  covergroup register_usage_cg with function sample(bit [4:0] rs1, bit [4:0] rs2, bit [4:0] rd);
    option.per_instance = 1;
    option.name = "register_usage_coverage";
    
    RS1_REG: coverpoint rs1 {
      bins zero_reg = {0};
      bins ra_reg = {1};
      bins sp_reg = {2};
      bins gp_reg = {3};
      bins tp_reg = {4};
      bins temp_regs = {[5:7]};
      bins saved_regs = {[8:9]};
      bins arg_regs = {[10:17]};
      bins saved_regs2 = {[18:27]};
      bins temp_regs2 = {[28:31]};
    }
    
    RS2_REG: coverpoint rs2 {
      bins zero_reg = {0};
      bins ra_reg = {1};
      bins sp_reg = {2};
      bins gp_reg = {3};
      bins tp_reg = {4};
      bins temp_regs = {[5:7]};
      bins saved_regs = {[8:9]};
      bins arg_regs = {[10:17]};
      bins saved_regs2 = {[18:27]};
      bins temp_regs2 = {[28:31]};
    }
    
    RD_REG: coverpoint rd {
      bins zero_reg = {0};  // Should never be written (architectural)
      bins ra_reg = {1};
      bins sp_reg = {2};
      bins gp_reg = {3};
      bins tp_reg = {4};
      bins temp_regs = {[5:7]};
      bins saved_regs = {[8:9]};
      bins arg_regs = {[10:17]};
      bins saved_regs2 = {[18:27]};
      bins temp_regs2 = {[28:31]};
    }
    
    // Cross coverage for register dependencies
    REG_DEPENDENCY: cross RS1_REG, RD_REG {
      // RAW hazard: read-after-write dependency
      bins raw_hazard = binsof(RS1_REG) intersect {[1:31]} && 
                        binsof(RD_REG) intersect {[1:31]};
    }
  endgroup

  covergroup immediate_values_cg with function sample(bit [31:0] imm, int itype);
    option.per_instance = 1;
    option.name = "immediate_values_coverage";
    
    IMM_VALUE: coverpoint imm {
      bins zero = {0};
      bins small_pos = {[1:15]};
      bins medium_pos = {[16:2047]};
      bins large_pos = {[2048:32'h7FFFFFFF]};
      bins small_neg = {[32'hFFFFFFF0:32'hFFFFFFFF]};
      bins medium_neg = {[32'hFFFFF800:32'hFFFFFFF0]};
      bins large_neg = {[32'h80000000:32'hFFFFF800]};
      bins corner_cases = {32'h7FFFFFFF, 32'h80000000, 32'hFFFFFFFF};
    }
    
    INSTR_TYPE: coverpoint itype {
      bins alu_ops = {0};        // INSTR_ALU
      bins mul_ops = {1};        // INSTR_MUL
      bins div_ops = {2};        // INSTR_DIV
      bins load_ops = {3};       // INSTR_LOAD
      bins store_ops = {4};      // INSTR_STORE
      bins branch_ops = {5};     // INSTR_BRANCH
      bins jump_ops = {6};       // INSTR_JUMP
      bins csr_ops = {7};        // INSTR_CSR
    }
    
    // Cross coverage of immediate values with instruction types
    IMM_INSTR_CROSS: cross IMM_VALUE, INSTR_TYPE {
      ignore_bins ignore_non_imm = binsof(INSTR_TYPE) intersect {1, 2, 5, 6}; // MUL, DIV, BRANCH, JUMP
    }
  endgroup

  covergroup branch_conditions_cg with function sample(int op, bit taken);
    option.per_instance = 1;
    option.name = "branch_conditions_coverage";
    
    BRANCH_OP: coverpoint op {
      bins beq = {0};   // BRANCH_BEQ
      bins bne = {1};   // BRANCH_BNE
      bins blt = {2};   // BRANCH_BLT
      bins bge = {3};   // BRANCH_BGE
      bins bltu = {4};  // BRANCH_BLTU
      bins bgeu = {5};  // BRANCH_BGEU
    }
    
    BRANCH_TAKEN: coverpoint taken {
      bins taken = {1};
      bins not_taken = {0};
    }
    
    // Cross coverage of branch operations with taken/not-taken
    BRANCH_BEHAVIOR: cross BRANCH_OP, BRANCH_TAKEN;
  endgroup

  covergroup memory_access_cg with function sample(int op, bit [1:0] addr_align);
    option.per_instance = 1;
    option.name = "memory_access_coverage";
    
    MEM_OP: coverpoint op {
      bins load_byte = {[0:1]};   // MEM_LB, MEM_LBU
      bins load_half = {[2:3]};   // MEM_LH, MEM_LHU
      bins load_word = {4};       // MEM_LW
      bins store_byte = {5};      // MEM_SB
      bins store_half = {6};      // MEM_SH
      bins store_word = {7};      // MEM_SW
    }
    
    ADDR_ALIGN: coverpoint addr_align {
      bins aligned_0 = {0};
      bins aligned_1 = {1};
      bins aligned_2 = {2};
      bins aligned_3 = {3};
    }
    
    // Cross coverage of memory operations with alignment
    MEM_ALIGN_CROSS: cross MEM_OP, ADDR_ALIGN {
      // Only certain alignments are valid for certain operations
      ignore_bins ignore_invalid_half = binsof(MEM_OP.load_half) && binsof(ADDR_ALIGN) intersect {1, 3};
      ignore_bins ignore_invalid_word = binsof(MEM_OP.load_word) && binsof(ADDR_ALIGN) intersect {1, 2, 3};
    }
  endgroup

  covergroup corner_cases_cg with function sample(bit enable_corner_case, int itype);
    option.per_instance = 1;
    option.name = "corner_cases_coverage";
    
    CORNER_CASE: coverpoint enable_corner_case {
      bins enabled = {1};
      bins disabled = {0};
    }
    
    INSTR_TYPE: coverpoint itype {
      bins alu_ops = {0};        // INSTR_ALU
      bins mul_ops = {1};        // INSTR_MUL
      bins div_ops = {2};        // INSTR_DIV
      bins load_ops = {3};       // INSTR_LOAD
      bins store_ops = {4};      // INSTR_STORE
      bins branch_ops = {5};     // INSTR_BRANCH
      bins jump_ops = {6};       // INSTR_JUMP
      bins csr_ops = {7};        // INSTR_CSR
    }
    
    // Cross coverage of corner cases with instruction types
    CORNER_INSTR_CROSS: cross CORNER_CASE, INSTR_TYPE {
      bins corner_alu = binsof(CORNER_CASE.enabled) && binsof(INSTR_TYPE) intersect {0}; // ALU
      bins corner_div = binsof(CORNER_CASE.enabled) && binsof(INSTR_TYPE) intersect {2}; // DIV
      bins corner_mem = binsof(CORNER_CASE.enabled) && binsof(INSTR_TYPE) intersect {3, 4}; // LOAD, STORE
    }
  endgroup

  covergroup hazard_scenarios_cg with function sample(bit [4:0] producer_rd, bit [4:0] consumer_rs1, bit [4:0] consumer_rs2, int distance);
    option.per_instance = 1;
    option.name = "hazard_scenarios_coverage";
    
    HAZARD_DISTANCE: coverpoint distance {
      bins immediate = {1};      // Back-to-back instructions
      bins one_cycle = {2};      // One instruction gap
      bins two_cycle = {3};      // Two instruction gap
      bins resolved = {[4:10]};  // Hazard resolved by forwarding/stalling
    }
    
    RAW_HAZARD_RS1: coverpoint (producer_rd == consumer_rs1 && producer_rd != 0) {
      bins hazard_present = {1};
      bins no_hazard = {0};
    }
    
    RAW_HAZARD_RS2: coverpoint (producer_rd == consumer_rs2 && producer_rd != 0) {
      bins hazard_present = {1};
      bins no_hazard = {0};
    }
    
    // Cross coverage of hazard types with distances
    HAZARD_DISTANCE_CROSS: cross RAW_HAZARD_RS1, HAZARD_DISTANCE {
      bins immediate_raw_rs1 = binsof(RAW_HAZARD_RS1.hazard_present) && binsof(HAZARD_DISTANCE.immediate);
      bins delayed_raw_rs1 = binsof(RAW_HAZARD_RS1.hazard_present) && binsof(HAZARD_DISTANCE.one_cycle);
    }
  endgroup

  covergroup performance_scenarios_cg with function sample(int itype, int estimated_cycles);
    option.per_instance = 1;
    option.name = "performance_scenarios_coverage";
    
    INSTR_TYPE: coverpoint itype {
      bins alu_ops = {0};        // INSTR_ALU
      bins mul_ops = {1};        // INSTR_MUL
      bins div_ops = {2};        // INSTR_DIV
      bins load_ops = {3};       // INSTR_LOAD
      bins store_ops = {4};      // INSTR_STORE
      bins branch_ops = {5};     // INSTR_BRANCH
      bins jump_ops = {6};       // INSTR_JUMP
      bins csr_ops = {7};        // INSTR_CSR
    }
    
    CYCLE_COUNT: coverpoint estimated_cycles {
      bins single_cycle = {1};
      bins multi_cycle_2 = {2};
      bins multi_cycle_3_5 = {[3:5]};
      bins high_latency = {[6:32]};
      bins very_high_latency = {[33:100]};
    }
    
    // Cross coverage of instruction types with cycle counts
    PERF_CROSS: cross INSTR_TYPE, CYCLE_COUNT {
      bins fast_alu = binsof(INSTR_TYPE) intersect {0} && binsof(CYCLE_COUNT.single_cycle); // ALU
      bins slow_div = binsof(INSTR_TYPE) intersect {2} && binsof(CYCLE_COUNT.high_latency); // DIV
      bins mem_access = binsof(INSTR_TYPE) intersect {3, 4} && binsof(CYCLE_COUNT.multi_cycle_2); // LOAD, STORE
    }
  endgroup

  // Coverage statistics
  int instruction_count;
  int coverage_hits[string];
  real coverage_percentages[string];

  function new(string name = "cv32e40p_coverage_model", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize coverage groups
    instruction_type_cg = new();
    alu_operations_cg = new();
    register_usage_cg = new();
    immediate_values_cg = new();
    branch_conditions_cg = new();
    memory_access_cg = new();
    corner_cases_cg = new();
    hazard_scenarios_cg = new();
    performance_scenarios_cg = new();
    
    instruction_count = 0;
  endfunction

  function void write(cv32e40p_enhanced_instruction_item t);
    instruction_count++;
    
    // Sample all coverage groups
    instruction_type_cg.sample(int'(t.instr_type));
    
    if (int'(t.instr_type) == 0) begin // INSTR_ALU
      alu_operations_cg.sample(int'(t.alu_op));
    end
    
    register_usage_cg.sample(t.rs1, t.rs2, t.rd);
    immediate_values_cg.sample(t.immediate, int'(t.instr_type));
    
    if (int'(t.instr_type) == 5) begin // INSTR_BRANCH
      branch_conditions_cg.sample(int'(t.branch_op), t.branch_taken);
    end
    
    if (int'(t.instr_type) == 3 || int'(t.instr_type) == 4) begin // INSTR_LOAD || INSTR_STORE
      memory_access_cg.sample(int'(t.mem_op), t.address[1:0]);
    end
    
    corner_cases_cg.sample(t.enable_corner_case, int'(t.instr_type));
    
    // Sample hazard scenarios (simplified - would need sequence context in real implementation)
    if (instruction_count > 1) begin
      hazard_scenarios_cg.sample(t.rd, t.rs1, t.rs2, 1); // Simplified distance
    end
    
    performance_scenarios_cg.sample(int'(t.instr_type), t.estimated_cycles);
  endfunction

  function void report_coverage();
    real total_coverage;
    
    `uvm_info(get_type_name(), "=== COVERAGE REPORT ===", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Instructions Processed: %0d", instruction_count), UVM_LOW)
    
    // Get coverage percentages
    coverage_percentages["instruction_type"] = instruction_type_cg.get_inst_coverage();
    coverage_percentages["alu_operations"] = alu_operations_cg.get_inst_coverage();
    coverage_percentages["register_usage"] = register_usage_cg.get_inst_coverage();
    coverage_percentages["immediate_values"] = immediate_values_cg.get_inst_coverage();
    coverage_percentages["branch_conditions"] = branch_conditions_cg.get_inst_coverage();
    coverage_percentages["memory_access"] = memory_access_cg.get_inst_coverage();
    coverage_percentages["corner_cases"] = corner_cases_cg.get_inst_coverage();
    coverage_percentages["hazard_scenarios"] = hazard_scenarios_cg.get_inst_coverage();
    coverage_percentages["performance_scenarios"] = performance_scenarios_cg.get_inst_coverage();
    
    // Report individual coverage groups
    foreach (coverage_percentages[group]) begin
      `uvm_info(get_type_name(), $sformatf("%s Coverage: %0.2f%%", group, coverage_percentages[group]), UVM_LOW)
    end
    
    // Calculate overall coverage
    total_coverage = 0;
    foreach (coverage_percentages[group]) begin
      total_coverage += coverage_percentages[group];
    end
    total_coverage = total_coverage / coverage_percentages.num();
    
    `uvm_info(get_type_name(), $sformatf("Overall Functional Coverage: %0.2f%%", total_coverage), UVM_LOW)
    `uvm_info(get_type_name(), "=== END COVERAGE REPORT ===", UVM_LOW)
  endfunction

  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    report_coverage();
  endfunction

endclass

`endif // CV32E40P_COVERAGE_MODEL_SV