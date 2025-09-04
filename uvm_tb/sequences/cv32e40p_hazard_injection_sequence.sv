// Copyright 2024 ChipAgents
// Directed Hazard Injection Sequence

class cv32e40p_hazard_injection_sequence extends uvm_sequence #(cv32e40p_enhanced_instruction_item);
  `uvm_object_utils(cv32e40p_hazard_injection_sequence)

  // Hazard types to test
  typedef enum {
    HAZARD_LOAD_USE,      // Load followed by use of loaded data
    HAZARD_JALR_DATA,     // JALR dependent on preceding instruction
    HAZARD_FPU_DATA,      // FPU result used immediately
    HAZARD_WAW,           // Write-after-write
    HAZARD_RAW,           // Read-after-write
    HAZARD_BRANCH_DATA    // Branch condition dependent on preceding instruction
  } hazard_type_e;

  rand int unsigned num_hazard_pairs;
  rand hazard_type_e hazard_types[];

  constraint hazard_config_c {
    num_hazard_pairs inside {[5:20]};
    hazard_types.size() == num_hazard_pairs;
    foreach(hazard_types[i]) {
      hazard_types[i] inside {HAZARD_LOAD_USE, HAZARD_JALR_DATA, HAZARD_RAW, HAZARD_BRANCH_DATA};
    }
  }

  function new(string name = "cv32e40p_hazard_injection_sequence");
    super.new(name);
  endfunction

  virtual task body();
    cv32e40p_enhanced_instruction_item producer, consumer;
    
    `uvm_info("HAZARD_SEQ", $sformatf("Starting hazard injection sequence with %0d hazard pairs", num_hazard_pairs), UVM_LOW)
    
    foreach(hazard_types[i]) begin
      case(hazard_types[i])
        
        HAZARD_LOAD_USE: begin
          `uvm_info("HAZARD_SEQ", "Injecting Load-Use hazard", UVM_MEDIUM)
          
          // Producer: Load instruction
          producer = cv32e40p_enhanced_instruction_item::type_id::create("load_producer");
          start_item(producer);
          if (!producer.randomize() with {
            instr_type == INSTR_LOAD;
            rd inside {[1:31]}; // Don't use x0
            mem_addr[1:0] == 2'b00; // Aligned for predictable timing
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize load instruction")
          end
          finish_item(producer);
          
          // Consumer: ALU instruction using loaded data
          consumer = cv32e40p_enhanced_instruction_item::type_id::create("alu_consumer");
          start_item(consumer);
          if (!consumer.randomize() with {
            instr_type == INSTR_ALU;
            rs1 == producer.rd; // Use the loaded register
            alu_operator inside {7'b0011000, 7'b0011001}; // ADD or SUB
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize ALU consumer instruction")
          end
          finish_item(consumer);
        end
        
        HAZARD_JALR_DATA: begin
          `uvm_info("HAZARD_SEQ", "Injecting JALR data hazard", UVM_MEDIUM)
          
          // Producer: ALU instruction computing jump target
          producer = cv32e40p_enhanced_instruction_item::type_id::create("addr_producer");
          start_item(producer);
          if (!producer.randomize() with {
            instr_type == INSTR_ALU;
            rd inside {[1:31]};
            alu_operator == 7'b0011000; // ADD to compute address
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize address producer instruction")
          end
          finish_item(producer);
          
          // Consumer: ALU instruction using computed address as operand
          consumer = cv32e40p_enhanced_instruction_item::type_id::create("addr_consumer");
          start_item(consumer);
          if (!consumer.randomize() with {
            instr_type == INSTR_ALU;
            rs1 == producer.rd; // Use computed address as source
            alu_operator inside {7'b0011000, 7'b0011001}; // ADD or SUB
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize address consumer instruction")
          end
          finish_item(consumer);
        end
        
        HAZARD_RAW: begin
          `uvm_info("HAZARD_SEQ", "Injecting Read-After-Write hazard", UVM_MEDIUM)
          
          // Producer: Any instruction writing to register
          producer = cv32e40p_enhanced_instruction_item::type_id::create("raw_producer");
          start_item(producer);
          if (!producer.randomize() with {
            instr_type inside {INSTR_ALU, INSTR_MUL};
            rd inside {[1:31]};
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize RAW producer instruction")
          end
          finish_item(producer);
          
          // Consumer: Instruction immediately reading the written register
          consumer = cv32e40p_enhanced_instruction_item::type_id::create("raw_consumer");
          start_item(consumer);
          if (!consumer.randomize() with {
            instr_type == INSTR_ALU;
            rs1 == producer.rd || rs2 == producer.rd; // Read the written register
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize RAW consumer instruction")
          end
          finish_item(consumer);
        end
        
        HAZARD_BRANCH_DATA: begin
          `uvm_info("HAZARD_SEQ", "Injecting Branch data hazard", UVM_MEDIUM)
          
          // Producer: Instruction setting branch condition
          producer = cv32e40p_enhanced_instruction_item::type_id::create("branch_producer");
          start_item(producer);
          if (!producer.randomize() with {
            instr_type == INSTR_ALU;
            rd inside {[1:31]};
            alu_operator inside {7'b0011000, 7'b0011001}; // ADD or SUB
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize branch producer instruction")
          end
          finish_item(producer);
          
          // Consumer: Branch instruction using the result
          consumer = cv32e40p_enhanced_instruction_item::type_id::create("branch_consumer");
          start_item(consumer);
          if (!consumer.randomize() with {
            instr_type == INSTR_BRANCH;
            rs1 == producer.rd; // Branch condition depends on producer
            branch_target inside {[pc + 4:pc + 1024]}; // Forward branch
          }) begin
            `uvm_error("HAZARD_SEQ", "Failed to randomize branch consumer instruction")
          end
          finish_item(consumer);
        end
        
        default: begin
          `uvm_warning("HAZARD_SEQ", $sformatf("Unsupported hazard type: %s", hazard_types[i].name()))
        end
      endcase
      
      // Add a few independent instructions to separate hazard pairs
      repeat($urandom_range(1,3)) begin
        cv32e40p_enhanced_instruction_item filler;
        filler = cv32e40p_enhanced_instruction_item::type_id::create("filler");
        start_item(filler);
        if (!filler.randomize() with {
          instr_type == INSTR_ALU;
          // Use different registers to avoid interference
          rd != producer.rd;
          rs1 != producer.rd;
          rs2 != producer.rd;
        }) begin
          `uvm_warning("HAZARD_SEQ", "Failed to randomize filler instruction")
        end
        finish_item(filler);
      end
    end
    
    `uvm_info("HAZARD_SEQ", "Hazard injection sequence completed", UVM_LOW)
  endtask

endclass