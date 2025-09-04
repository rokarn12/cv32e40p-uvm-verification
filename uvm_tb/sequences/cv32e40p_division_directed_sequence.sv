// Copyright 2024 ChipAgents
// Directed Division Edge Cases Sequence

class cv32e40p_division_directed_sequence extends uvm_sequence #(cv32e40p_enhanced_instruction_item);
  `uvm_object_utils(cv32e40p_division_directed_sequence)

  // Test vectors for division edge cases
  typedef struct {
    logic [31:0] dividend;
    logic [31:0] divisor;
    logic [31:0] expected_quotient;
    logic [31:0] expected_remainder;
    string description;
  } div_test_vector_t;

  div_test_vector_t test_vectors[];

  function new(string name = "cv32e40p_division_directed_sequence");
    super.new(name);
    build_test_vectors();
  endfunction

  function void build_test_vectors();
    test_vectors = new[12];
    
    // Division by zero cases
    test_vectors[0] = '{32'h00000001, 32'h00000000, 32'hFFFFFFFF, 32'h00000001, "Positive / 0"};
    test_vectors[1] = '{32'hFFFFFFFF, 32'h00000000, 32'hFFFFFFFF, 32'hFFFFFFFF, "Negative / 0"};
    test_vectors[2] = '{32'h00000000, 32'h00000000, 32'hFFFFFFFF, 32'h00000000, "Zero / 0"};
    
    // Overflow case: most negative / -1
    test_vectors[3] = '{32'h80000000, 32'hFFFFFFFF, 32'h80000000, 32'h00000000, "Overflow: MIN_INT / -1"};
    
    // Division by 1 and -1
    test_vectors[4] = '{32'h12345678, 32'h00000001, 32'h12345678, 32'h00000000, "Positive / 1"};
    test_vectors[5] = '{32'h12345678, 32'hFFFFFFFF, 32'hEDCBA988, 32'h00000000, "Positive / -1"};
    
    // Edge values
    test_vectors[6] = '{32'h7FFFFFFF, 32'h7FFFFFFF, 32'h00000001, 32'h00000000, "MAX_POS / MAX_POS"};
    test_vectors[7] = '{32'h80000000, 32'h80000000, 32'h00000001, 32'h00000000, "MIN_NEG / MIN_NEG"};
    test_vectors[8] = '{32'h7FFFFFFF, 32'h80000000, 32'h00000000, 32'h7FFFFFFF, "MAX_POS / MIN_NEG"};
    
    // Performance test cases (different leading zero patterns)
    test_vectors[9] = '{32'h12345678, 32'h80000000, 32'h00000000, 32'h12345678, "Divisor with 0 leading zeros"};
    test_vectors[10] = '{32'h12345678, 32'h00000001, 32'h12345678, 32'h00000000, "Divisor with 31 leading zeros"};
    test_vectors[11] = '{32'h12345678, 32'h00008000, 32'h000024C0, 32'h00005678, "Divisor with 16 leading zeros"};
  endfunction

  virtual task body();
    cv32e40p_enhanced_instruction_item item;
    
    `uvm_info("DIV_DIRECTED_SEQ", "Starting directed division edge case sequence", UVM_LOW)
    
    // Test each directed case
    foreach(test_vectors[i]) begin
      // Test signed division
      item = cv32e40p_enhanced_instruction_item::type_id::create("div_item");
      start_item(item);
      
      if (!item.randomize() with {
        instr_type == INSTR_DIV;
        operand_a == test_vectors[i].dividend;
        operand_b == test_vectors[i].divisor;
        alu_operator == 7'b0110001; // ALU_DIV (signed)
      }) begin
        `uvm_error("DIV_DIRECTED_SEQ", "Failed to randomize division instruction")
      end
      
      `uvm_info("DIV_DIRECTED_SEQ", $sformatf("DIV Test %0d: %s - 0x%08x / 0x%08x", 
                i, test_vectors[i].description, test_vectors[i].dividend, test_vectors[i].divisor), UVM_LOW)
      
      finish_item(item);
      
      // Test unsigned division for same operands
      item = cv32e40p_enhanced_instruction_item::type_id::create("divu_item");
      start_item(item);
      
      if (!item.randomize() with {
        instr_type == INSTR_DIV;
        operand_a == test_vectors[i].dividend;
        operand_b == test_vectors[i].divisor;
        alu_operator == 7'b0110000; // ALU_DIVU (unsigned)
      }) begin
        `uvm_error("DIV_DIRECTED_SEQ", "Failed to randomize unsigned division instruction")
      end
      
      `uvm_info("DIV_DIRECTED_SEQ", $sformatf("DIVU Test %0d: %s - 0x%08x / 0x%08x", 
                i, test_vectors[i].description, test_vectors[i].dividend, test_vectors[i].divisor), UVM_LOW)
      
      finish_item(item);
      
      // Test remainder operations
      item = cv32e40p_enhanced_instruction_item::type_id::create("rem_item");
      start_item(item);
      
      if (!item.randomize() with {
        instr_type == INSTR_DIV;
        operand_a == test_vectors[i].dividend;
        operand_b == test_vectors[i].divisor;
        alu_operator == 7'b0110011; // ALU_REM (signed remainder)
      }) begin
        `uvm_error("DIV_DIRECTED_SEQ", "Failed to randomize remainder instruction")
      end
      
      `uvm_info("DIV_DIRECTED_SEQ", $sformatf("REM Test %0d: %s - 0x%08x %% 0x%08x", 
                i, test_vectors[i].description, test_vectors[i].dividend, test_vectors[i].divisor), UVM_LOW)
      
      finish_item(item);
    end
    
    // Add some random division tests to complement directed ones
    `uvm_info("DIV_DIRECTED_SEQ", "Adding random division tests for coverage", UVM_LOW)
    repeat(20) begin
      item = cv32e40p_enhanced_instruction_item::type_id::create("div_random_item");
      start_item(item);
      
      if (!item.randomize() with {
        instr_type == INSTR_DIV;
        enable_corner_case == 0; // Use normal distribution
      }) begin
        `uvm_error("DIV_DIRECTED_SEQ", "Failed to randomize random division instruction")
      end
      
      finish_item(item);
    end
    
    `uvm_info("DIV_DIRECTED_SEQ", "Directed division sequence completed", UVM_LOW)
  endtask

endclass