// Copyright 2024 ChipAgents
// Constrained Random ALU Operations Sequence

class cv32e40p_alu_random_sequence extends uvm_sequence #(cv32e40p_enhanced_instruction_item);
  `uvm_object_utils(cv32e40p_alu_random_sequence)

  // Configuration parameters
  rand int unsigned num_instructions;
  rand bit enable_corner_cases;
  rand bit enable_pulp_extensions;
  
  constraint num_instr_c {
    num_instructions inside {[10:100]};
  }

  function new(string name = "cv32e40p_alu_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    cv32e40p_enhanced_instruction_item item;
    
    `uvm_info("ALU_RANDOM_SEQ", $sformatf("Starting ALU random sequence with %0d instructions", num_instructions), UVM_LOW)
    
    repeat(num_instructions) begin
      item = cv32e40p_enhanced_instruction_item::type_id::create("alu_item");
      
      start_item(item);
      
      // Constrain to ALU operations only
      if (!item.randomize() with {
        instr_type inside {INSTR_ALU, enable_pulp_extensions ? INSTR_PULP_ALU : INSTR_ALU};
        enable_corner_case == enable_corner_cases;
        enable_hazard_injection == 0; // No hazards in this sequence
      }) begin
        `uvm_error("ALU_RANDOM_SEQ", "Failed to randomize ALU instruction")
      end
      
      `uvm_info("ALU_RANDOM_SEQ", $sformatf("Generated: %s", item.convert2string()), UVM_HIGH)
      
      finish_item(item);
    end
    
    `uvm_info("ALU_RANDOM_SEQ", "ALU random sequence completed", UVM_LOW)
  endtask

endclass