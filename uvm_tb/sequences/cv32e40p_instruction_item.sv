// Copyright 2024 ChipAgents
// UVM Sequence Item for CV32E40P Instructions

class cv32e40p_instruction_item extends uvm_sequence_item;
  `uvm_object_utils(cv32e40p_instruction_item)

  // Instruction fields
  rand bit [31:0] instruction;
  rand bit [31:0] pc;
  rand bit [31:0] operand_a;
  rand bit [31:0] operand_b;
  rand bit [31:0] operand_c;
  
  // ALU-specific fields
  rand bit [6:0]  alu_operator;
  rand bit [1:0]  vector_mode;
  rand bit [4:0]  bmask_a;
  rand bit [4:0]  bmask_b;
  rand bit [1:0]  imm_vec_ext;
  rand bit        is_clpx;
  rand bit        is_subrot;
  rand bit [1:0]  clpx_shift;
  
  // Expected results
  bit [31:0] expected_result;
  bit        expected_comparison_result;
  bit        result_valid;
  
  // Instruction type classification
  typedef enum {
    INSTR_ARITHMETIC,
    INSTR_LOGICAL,
    INSTR_SHIFT,
    INSTR_COMPARISON,
    INSTR_BIT_MANIP,
    INSTR_VECTOR,
    INSTR_DIVISION,
    INSTR_LOAD_STORE,
    INSTR_BRANCH,
    INSTR_JUMP
  } instr_type_e;
  
  rand instr_type_e instr_type;
  
  // Constraints for realistic instruction generation
  constraint valid_instruction_c {
    // Focus on ALU operations for this testbench
    instr_type inside {INSTR_ARITHMETIC, INSTR_LOGICAL, INSTR_SHIFT, 
                      INSTR_COMPARISON, INSTR_BIT_MANIP, INSTR_VECTOR, INSTR_DIVISION};
    
    // Valid ALU operators based on cv32e40p_pkg
    alu_operator inside {
      7'b0011000, // ALU_ADD
      7'b0011001, // ALU_SUB
      7'b0011010, // ALU_ADDU
      7'b0011011, // ALU_SUBU
      7'b0101111, // ALU_XOR
      7'b0101110, // ALU_OR
      7'b0010101, // ALU_AND
      7'b0100100, // ALU_SRA
      7'b0100101, // ALU_SRL
      7'b0100111, // ALU_SLL
      7'b0000000, // ALU_LTS
      7'b0000001, // ALU_LTU
      7'b0001100, // ALU_EQ
      7'b0001101  // ALU_NE
    };
    
    // Vector mode constraints
    vector_mode inside {2'b00, 2'b10, 2'b11}; // 32-bit, 16-bit, 8-bit
    
    // Bit mask constraints
    bmask_a < 32;
    bmask_b < 32;
    
    // PC alignment
    pc[1:0] == 2'b00;
  }
  
  // Constraint for edge cases
  constraint edge_case_c {
    // Include edge values with some probability
    operand_a dist {
      32'h00000000 := 5,
      32'hFFFFFFFF := 5,
      32'h80000000 := 5,
      32'h7FFFFFFF := 5,
      [32'h00000001:32'hFFFFFFFE] := 80
    };
    
    operand_b dist {
      32'h00000000 := 5,
      32'hFFFFFFFF := 5,
      32'h80000000 := 5,
      32'h7FFFFFFF := 5,
      [32'h00000001:32'hFFFFFFFE] := 80
    };
  }

  function new(string name = "cv32e40p_instruction_item");
    super.new(name);
  endfunction

  // Convert to string for debugging
  function string convert2string();
    string s;
    s = $sformatf("PC=0x%08x, INSTR=0x%08x, OP_A=0x%08x, OP_B=0x%08x, ALU_OP=0x%02x",
                  pc, instruction, operand_a, operand_b, alu_operator);
    return s;
  endfunction

  // Copy function
  function void do_copy(uvm_object rhs);
    cv32e40p_instruction_item rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("CAST_ERROR", "Failed to cast rhs to cv32e40p_instruction_item")
    end
    super.do_copy(rhs);
    instruction = rhs_.instruction;
    pc = rhs_.pc;
    operand_a = rhs_.operand_a;
    operand_b = rhs_.operand_b;
    operand_c = rhs_.operand_c;
    alu_operator = rhs_.alu_operator;
    vector_mode = rhs_.vector_mode;
    expected_result = rhs_.expected_result;
    expected_comparison_result = rhs_.expected_comparison_result;
  endfunction

  // Compare function
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    cv32e40p_instruction_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            instruction == rhs_.instruction &&
            pc == rhs_.pc &&
            operand_a == rhs_.operand_a &&
            operand_b == rhs_.operand_b &&
            alu_operator == rhs_.alu_operator);
  endfunction

endclass