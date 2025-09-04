// CV32E40P Simple Coverage Model
// Simplified functional coverage for RISC-V core verification

`ifndef CV32E40P_SIMPLE_COVERAGE_MODEL_SV
`define CV32E40P_SIMPLE_COVERAGE_MODEL_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class cv32e40p_simple_coverage_model extends uvm_component;
  `uvm_component_utils(cv32e40p_simple_coverage_model)

  // Coverage groups
  covergroup instruction_type_cg;
    option.per_instance = 1;
    option.name = "instruction_type_coverage";
    
    INSTR_TYPE: coverpoint instr_type_sample {
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

  covergroup alu_operations_cg;
    option.per_instance = 1;
    option.name = "alu_operations_coverage";
    
    ALU_OP: coverpoint alu_op_sample {
      bins add_sub = {[0:1]};      // ALU_ADD, ALU_SUB
      bins logical = {[2:4]};      // ALU_AND, ALU_OR, ALU_XOR
      bins shifts = {[5:7]};       // ALU_SLL, ALU_SRL, ALU_SRA
      bins compare = {[8:9]};      // ALU_SLT, ALU_SLTU
      bins immediate = {[10:16]};  // Immediate operations
    }
  endgroup

  covergroup register_usage_cg;
    option.per_instance = 1;
    option.name = "register_usage_coverage";
    
    RS1_REG: coverpoint rs1_sample {
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
    
    RS2_REG: coverpoint rs2_sample {
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
    
    RD_REG: coverpoint rd_sample {
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

  // Coverage statistics
  int instruction_count;
  int coverage_hits[string];
  real coverage_percentages[string];
  
  // Sample variables
  int instr_type_sample;
  int alu_op_sample;
  bit [4:0] rs1_sample, rs2_sample, rd_sample;

  function new(string name = "cv32e40p_simple_coverage_model", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize coverage groups
    instruction_type_cg = new();
    alu_operations_cg = new();
    register_usage_cg = new();
    
    instruction_count = 0;
  endfunction

  // Manual sampling functions
  function void sample_instruction_type(int itype);
    instr_type_sample = itype;
    instruction_type_cg.sample();
    instruction_count++;
  endfunction
  
  function void sample_alu_operation(int alu_op);
    alu_op_sample = alu_op;
    alu_operations_cg.sample();
  endfunction
  
  function void sample_register_usage(bit [4:0] rs1, bit [4:0] rs2, bit [4:0] rd);
    rs1_sample = rs1;
    rs2_sample = rs2;
    rd_sample = rd;
    register_usage_cg.sample();
  endfunction

  function void report_coverage();
    real total_coverage;
    
    `uvm_info(get_type_name(), "=== COVERAGE REPORT ===", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Instructions Processed: %0d", instruction_count), UVM_LOW)
    
    // Get coverage percentages
    coverage_percentages["instruction_type"] = instruction_type_cg.get_inst_coverage();
    coverage_percentages["alu_operations"] = alu_operations_cg.get_inst_coverage();
    coverage_percentages["register_usage"] = register_usage_cg.get_inst_coverage();
    
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

`endif // CV32E40P_SIMPLE_COVERAGE_MODEL_SV