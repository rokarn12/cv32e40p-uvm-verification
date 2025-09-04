// Copyright 2024 ChipAgents
// Basic UVM Sequence for CV32E40P Testing

class cv32e40p_basic_sequence extends uvm_sequence #(cv32e40p_enhanced_instruction_item);
  `uvm_object_utils(cv32e40p_basic_sequence)

  // Number of transactions to generate
  int num_transactions = 10;

  function new(string name = "cv32e40p_basic_sequence");
    super.new(name);
  endfunction

  task body();
    cv32e40p_enhanced_instruction_item req;
    
    `uvm_info("SEQUENCE", $sformatf("Starting basic sequence with %0d transactions", num_transactions), UVM_LOW)
    
    for (int i = 0; i < num_transactions; i++) begin
      req = cv32e40p_enhanced_instruction_item::type_id::create("req");
      
      start_item(req);
      
      // Simple directed stimulus for basic ALU operations
      if (!req.randomize() with {
        instr_type == INSTR_ALU;
        alu_operator inside {
          7'b0011000, // ALU_ADD
          7'b0011001, // ALU_SUB
          7'b0101111, // ALU_XOR
          7'b0101110, // ALU_OR
          7'b0010101  // ALU_AND
        };
        operand_a inside {[32'h00000001:32'h0000FFFF]};
        operand_b inside {[32'h00000001:32'h0000FFFF]};
        enable_corner_case == 0;
      }) begin
        `uvm_error("SEQUENCE", $sformatf("Randomization failed for transaction %0d", i))
      end
      
      // Set PC value
      req.pc = 32'h00000180 + (i * 4); // Sequential PC values
      
      `uvm_info("SEQUENCE", $sformatf("Transaction %0d: %s", i, req.convert2string()), UVM_MEDIUM)
      
      finish_item(req);
    end
    
    `uvm_info("SEQUENCE", "Basic sequence completed", UVM_LOW)
  endtask

  // Generate a simple instruction encoding for ALU operations
  function bit [31:0] generate_alu_instruction(bit [6:0] alu_op, bit [31:0] op_a, bit [31:0] op_b);
    bit [31:0] instr;
    
    // This is a simplified instruction generation
    // In a real implementation, this would follow RISC-V encoding
    case (alu_op)
      7'b0011000: instr = 32'h00000033; // ADD rd, rs1, rs2 (simplified)
      7'b0011001: instr = 32'h40000033; // SUB rd, rs1, rs2 (simplified)
      7'b0101111: instr = 32'h00004033; // XOR rd, rs1, rs2 (simplified)
      7'b0101110: instr = 32'h00006033; // OR rd, rs1, rs2 (simplified)
      7'b0010101: instr = 32'h00007033; // AND rd, rs1, rs2 (simplified)
      default:    instr = 32'h00000013; // NOP (ADDI x0, x0, 0)
    endcase
    
    return instr;
  endfunction

endclass

// Directed test sequence for edge cases
class cv32e40p_edge_case_sequence extends uvm_sequence #(cv32e40p_enhanced_instruction_item);
  `uvm_object_utils(cv32e40p_edge_case_sequence)

  function new(string name = "cv32e40p_edge_case_sequence");
    super.new(name);
  endfunction

  task body();
    cv32e40p_enhanced_instruction_item req;
    
    `uvm_info("SEQUENCE", "Starting edge case sequence", UVM_LOW)
    
    // Test zero operands
    req = cv32e40p_enhanced_instruction_item::type_id::create("req");
    start_item(req);
    req.instr_type = INSTR_ALU;
    req.alu_operator = 7'b0011000; // ADD
    req.operand_a = 32'h00000000;
    req.operand_b = 32'h00000000;
    req.instruction = 32'h00000033;
    req.pc = 32'h00000180;
    finish_item(req);
    
    // Test maximum values
    req = cv32e40p_enhanced_instruction_item::type_id::create("req");
    start_item(req);
    req.instr_type = INSTR_ALU;
    req.alu_operator = 7'b0011000; // ADD
    req.operand_a = 32'hFFFFFFFF;
    req.operand_b = 32'hFFFFFFFF;
    req.instruction = 32'h00000033;
    req.pc = 32'h00000184;
    finish_item(req);
    
    // Test overflow case
    req = cv32e40p_enhanced_instruction_item::type_id::create("req");
    start_item(req);
    req.instr_type = INSTR_ALU;
    req.alu_operator = 7'b0011000; // ADD
    req.operand_a = 32'h7FFFFFFF;
    req.operand_b = 32'h00000001;
    req.instruction = 32'h00000033;
    req.pc = 32'h00000188;
    finish_item(req);
    
    `uvm_info("SEQUENCE", "Edge case sequence completed", UVM_LOW)
  endtask

endclass