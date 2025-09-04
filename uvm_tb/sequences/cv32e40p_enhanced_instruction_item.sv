// Copyright 2024 ChipAgents
// Enhanced UVM Sequence Item for CV32E40P Instructions - Stage 2

class cv32e40p_enhanced_instruction_item extends uvm_sequence_item;
  `uvm_object_utils(cv32e40p_enhanced_instruction_item)



  // Instruction fields
  rand instr_type_e instr_type;
  rand logic [31:0] instruction;
  rand logic [31:0] pc;
  rand logic [6:0]  opcode;
  rand logic [4:0]  rd, rs1, rs2;
  rand logic [2:0]  funct3;
  rand logic [6:0]  funct7;
  rand logic [31:0] immediate;
  
  // ALU operation fields (enhanced for PULP)
  rand logic [6:0]  alu_operator;
  rand logic [31:0] operand_a;
  rand logic [31:0] operand_b;
  rand logic [31:0] operand_c;
  rand logic [1:0]  vector_mode;
  rand logic [4:0]  bmask_a, bmask_b;
  rand logic        is_clpx;
  rand logic        is_subrot;
  rand logic [1:0]  clpx_shift;
  
  // PULP-specific fields
  rand logic [11:0] post_inc_imm;
  rand logic        use_post_inc;
  rand logic [1:0]  hwloop_id;
  rand logic [31:0] hwloop_start, hwloop_end;
  rand logic [31:0] hwloop_count;
  
  // SIMD operation fields
  rand logic [1:0]  simd_mode;  // 00: 32-bit, 10: 16-bit, 11: 8-bit
  rand logic        simd_scalar_repl;
  rand logic [5:0]  simd_immediate;
  
  // CSR fields
  rand logic [11:0] csr_addr;
  rand logic [31:0] csr_data;
  rand logic [2:0]  csr_op;  // CSRRW, CSRRS, CSRRC, etc.
  
  // Memory operation fields
  rand logic [31:0] mem_addr;
  rand logic [31:0] mem_data;
  rand logic [3:0]  mem_be;    // Byte enable
  rand logic        mem_we;    // Write enable
  rand logic [2:0]  mem_size;  // 000: byte, 001: half, 010: word
  rand logic        mem_sign_ext;
  
  // Control flow fields
  rand logic [31:0] branch_target;
  rand logic        branch_taken;
  rand logic [31:0] jump_target;
  
  // Expected results
  logic [31:0] expected_result;
  logic        expected_comparison_result;
  logic        result_valid;
  logic        exception_expected;
  logic [4:0]  exception_cause;
  
  // Performance tracking
  int unsigned expected_cycles;
  int unsigned actual_cycles;
  time         timestamp;
  
  // Coverage hints
  rand bit enable_hazard_injection;
  rand bit enable_corner_case;
  rand bit enable_performance_test;

  // Constraint: Instruction type distribution
  constraint instr_type_dist_c {
    instr_type dist {
      INSTR_ALU         := 30,  // Most common
      INSTR_MUL         := 10,
      INSTR_DIV         := 5,   // Less common due to high latency
      INSTR_LOAD        := 15,
      INSTR_STORE       := 10,
      INSTR_BRANCH      := 10,
      INSTR_JUMP        := 5,
      INSTR_CSR         := 3,
      INSTR_PULP_ALU    := 8,
      INSTR_PULP_SIMD   := 4
    };
  }

  // Constraint: Valid ALU operators
  constraint alu_operator_c {
    if (instr_type == INSTR_ALU) {
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
    }
    
    if (instr_type == INSTR_PULP_ALU) {
      alu_operator inside {
        7'b0101000, // ALU_BEXT
        7'b0101001, // ALU_BEXTU
        7'b0101010, // ALU_BINS
        7'b0101011, // ALU_BCLR
        7'b0101100, // ALU_BSET
        7'b0110110, // ALU_FF1
        7'b0110111, // ALU_FL1
        7'b0110100, // ALU_CNT
        7'b0010000, // ALU_MIN
        7'b0010001, // ALU_MINU
        7'b0010010, // ALU_MAX
        7'b0010011  // ALU_MAXU
      };
    }
    
    // For non-ALU instructions, alu_operator should be don't care
    if (instr_type inside {INSTR_JUMP, INSTR_BRANCH, INSTR_LOAD, INSTR_STORE, INSTR_CSR}) {
      alu_operator == 7'b0000000; // Default/don't care value
    }
  }

  // Constraint: Operand distributions for different scenarios
  constraint operand_dist_c {
    if (enable_corner_case) {
      operand_a dist {
        32'h00000000 := 10,  // Zero
        32'hFFFFFFFF := 10,  // All ones
        32'h80000000 := 10,  // Most negative
        32'h7FFFFFFF := 10,  // Most positive
        32'h00000001 := 5,   // Small positive
        32'hFFFFFFFE := 5,   // Small negative
        [32'h00000002:32'h7FFFFFFE] := 25,
        [32'h80000001:32'hFFFFFFFD] := 25
      };
      
      operand_b dist {
        32'h00000000 := 10,
        32'hFFFFFFFF := 10,
        32'h80000000 := 10,
        32'h7FFFFFFF := 10,
        32'h00000001 := 5,
        32'hFFFFFFFE := 5,
        [32'h00000002:32'h7FFFFFFE] := 25,
        [32'h80000001:32'hFFFFFFFD] := 25
      };
    } else {
      // Normal distribution for regular testing
      operand_a dist {
        [32'h00000000:32'hFFFFFFFF] := 100
      };
      operand_b dist {
        [32'h00000000:32'hFFFFFFFF] := 100
      };
    }
  }

  // Constraint: Division-specific constraints
  constraint division_c {
    if (instr_type == INSTR_DIV) {
      // Include division by zero cases
      operand_b dist {
        32'h00000000 := 10,  // Division by zero
        32'h00000001 := 10,  // Division by one
        32'hFFFFFFFF := 10,  // Division by -1
        [32'h00000002:32'h7FFFFFFF] := 35,
        [32'h80000000:32'hFFFFFFFE] := 35
      };
      
      // Test overflow case: most negative / -1
      (operand_a == 32'h80000000 && operand_b == 32'hFFFFFFFF) dist {1 := 5, 0 := 95};
    }
  }

  // Constraint: Memory address alignment
  constraint memory_addr_c {
    if (instr_type inside {INSTR_LOAD, INSTR_STORE, INSTR_PULP_POSTINC}) {
      // Most accesses should be aligned
      mem_addr[1:0] dist {
        2'b00 := 70,  // Word aligned
        2'b01 := 10,  // Misaligned
        2'b10 := 15,  // Half-word aligned
        2'b11 := 5    // Byte aligned
      };
      
      // Valid memory range (assuming 1MB memory)
      mem_addr < 32'h00100000;
    }
  }

  // Constraint: CSR addresses
  constraint csr_addr_c {
    if (instr_type == INSTR_CSR) {
      csr_addr inside {
        12'h300,  // mstatus
        12'h301,  // misa
        12'h304,  // mie
        12'h305,  // mtvec
        12'h340,  // mscratch
        12'h341,  // mepc
        12'h342,  // mcause
        12'h343,  // mtval
        12'h344,  // mip
        12'hB00,  // mcycle
        12'hB02,  // minstret
        12'hC00,  // cycle
        12'hC02   // instret
      };
    }
  }

  // Constraint: SIMD mode consistency
  constraint simd_mode_c {
    if (instr_type == INSTR_PULP_SIMD) {
      simd_mode inside {2'b00, 2'b10, 2'b11}; // 32-bit, 16-bit, 8-bit
      vector_mode == simd_mode;
      
      if (simd_scalar_repl) {
        simd_immediate inside {[0:63]};
      }
    }
  }

  // Constraint: Hardware loop parameters
  constraint hwloop_c {
    if (instr_type == INSTR_PULP_HWLOOP) {
      hwloop_id inside {0, 1};  // Two hardware loops
      hwloop_count inside {[2:1024]};  // Minimum 2 iterations
      hwloop_end > hwloop_start;
      (hwloop_end - hwloop_start) >= 8;  // Minimum loop body size
      hwloop_start[1:0] == 2'b00;  // Word aligned
      hwloop_end[1:0] == 2'b00;    // Word aligned
    }
  }

  // Constraint: PC alignment
  constraint pc_alignment_c {
    pc[1:0] == 2'b00;  // Word aligned
    pc < 32'h00100000; // Valid instruction memory range
  }

  function new(string name = "cv32e40p_enhanced_instruction_item");
    super.new(name);
  endfunction

  // Convert to string for debugging
  function string convert2string();
    string s;
    s = $sformatf("Type=%s, PC=0x%08x, OP_A=0x%08x, OP_B=0x%08x, ALU_OP=0x%02x, Cycles=%0d",
                  instr_type.name(), pc, operand_a, operand_b, alu_operator, expected_cycles);
    return s;
  endfunction

  // Calculate expected cycles based on instruction type
  function void calculate_expected_cycles();
    case (instr_type)
      INSTR_ALU, INSTR_PULP_ALU, INSTR_PULP_SIMD: expected_cycles = 1;
      INSTR_MUL: expected_cycles = (alu_operator inside {7'b0110110, 7'b0110111}) ? 5 : 1; // MULH* = 5, MUL = 1
      INSTR_DIV: expected_cycles = $urandom_range(3, 35); // Variable based on operand
      INSTR_LOAD, INSTR_STORE: expected_cycles = (mem_addr[1:0] != 2'b00) ? 2 : 1; // Misaligned = 2
      INSTR_BRANCH: expected_cycles = branch_taken ? 3 : 1;
      INSTR_JUMP: expected_cycles = 2;
      INSTR_CSR: expected_cycles = (csr_addr inside {12'h300, 12'h341, 12'h305, 12'h342}) ? 4 : 1;
      INSTR_PULP_POSTINC: expected_cycles = 1;
      INSTR_PULP_HWLOOP: expected_cycles = 1;
      default: expected_cycles = 1;
    endcase
  endfunction

  // Post-randomize to calculate derived fields
  function void post_randomize();
    calculate_expected_cycles();
    
    // Set result_valid flag
    result_valid = 1'b1;
    
    // Set exception expectations for division by zero
    if (instr_type == INSTR_DIV && operand_b == 32'h0) begin
      exception_expected = 1'b0; // CV32E40P doesn't trap on div by zero
      expected_result = 32'hFFFFFFFF; // Returns -1 for div by zero
    end else begin
      exception_expected = 1'b0;
    end
  endfunction

  // Copy function
  function void do_copy(uvm_object rhs);
    cv32e40p_enhanced_instruction_item rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("CAST_ERROR", "Failed to cast rhs to cv32e40p_enhanced_instruction_item")
    end
    super.do_copy(rhs);
    instr_type = rhs_.instr_type;
    instruction = rhs_.instruction;
    pc = rhs_.pc;
    operand_a = rhs_.operand_a;
    operand_b = rhs_.operand_b;
    operand_c = rhs_.operand_c;
    alu_operator = rhs_.alu_operator;
    expected_cycles = rhs_.expected_cycles;
  endfunction

  // Compare function
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    cv32e40p_enhanced_instruction_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            instr_type == rhs_.instr_type &&
            instruction == rhs_.instruction &&
            pc == rhs_.pc &&
            operand_a == rhs_.operand_a &&
            operand_b == rhs_.operand_b &&
            alu_operator == rhs_.alu_operator);
  endfunction

endclass