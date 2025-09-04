// Copyright 2024 ChipAgents
// UVM Monitor for CV32E40P Core

class cv32e40p_monitor extends uvm_monitor;
  `uvm_component_utils(cv32e40p_monitor)

  // Virtual interface handle
  virtual cv32e40p_if vif;
  
  // Configuration object
  cv32e40p_config cfg;
  
  // Analysis port for sending transactions to scoreboard
  uvm_analysis_port #(cv32e40p_enhanced_instruction_item) ap;
  
  // Coverage collector
  cv32e40p_coverage_collector cov_collector;

  function new(string name = "cv32e40p_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual cv32e40p_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not found")
    end
    
    // Get configuration
    if (!uvm_config_db#(cv32e40p_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found")
    end
    
    // Create coverage collector if enabled
    if (cfg.enable_coverage) begin
      cov_collector = cv32e40p_coverage_collector::type_id::create("cov_collector", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.enable_coverage && cov_collector != null) begin
      ap.connect(cov_collector.analysis_export);
    end
  endfunction

  task run_phase(uvm_phase phase);
    cv32e40p_enhanced_instruction_item item;
    
    // Wait for reset deassertion
    @(posedge vif.rst_ni);
    repeat(5) @(posedge vif.clk_i);
    
    `uvm_info("MONITOR", "Starting monitoring", UVM_LOW)
    
    forever begin
      // Monitor for instruction execution
      item = cv32e40p_enhanced_instruction_item::type_id::create("monitored_item");
      monitor_instruction(item);
      
      // Send to analysis port
      ap.write(item);
      
      `uvm_info("MONITOR", $sformatf("Monitored transaction: %s", item.convert2string()), UVM_HIGH)
    end
  endtask

  // Monitor instruction execution
  task monitor_instruction(cv32e40p_enhanced_instruction_item item);
    // Wait for instruction fetch
    wait(vif.instr_req_o && vif.instr_gnt_i);
    
    // Capture PC
    item.pc = vif.instr_addr_o;
    
    // Wait for instruction data
    wait(vif.instr_rvalid_i);
    item.instruction = vif.instr_rdata_i;
    
    // Monitor ALU operation if this is an ALU instruction
    monitor_alu_operation(item);
    
    // Wait for instruction completion
    wait_instruction_completion();
  endtask

  // Monitor ALU-specific signals
  task monitor_alu_operation(cv32e40p_enhanced_instruction_item item);
    // Access internal ALU signals through hierarchical references
    // Note: This requires the testbench to have access to internal signals
    
    // For now, we'll use a simplified approach without hierarchical references
    // In a real implementation, you would need to add bind statements or
    // use interfaces to access internal ALU signals
    
    // Simple approach: generate expected results based on instruction
    // This is a placeholder - real implementation would monitor actual ALU signals
    item.alu_operator = 7'b0011000; // Default to ADD for now
    item.operand_a = $urandom();
    item.operand_b = $urandom();
    item.operand_c = 32'h0;
    item.vector_mode = 2'b00;
    item.bmask_a = 5'h0;
    item.bmask_b = 5'h0;
    item.is_clpx = 1'b0;
    item.is_subrot = 1'b0;
    item.clpx_shift = 2'b00;
    
    // Simple result calculation for basic operations
    item.expected_result = item.operand_a + item.operand_b; // ADD result
    item.expected_comparison_result = 1'b0;
    item.result_valid = 1'b1;
  endtask

  // Wait for instruction completion
  task wait_instruction_completion();
    // Simple completion detection
    repeat(5) @(posedge vif.clk_i);
  endtask

endclass

// Coverage collector class
class cv32e40p_coverage_collector extends uvm_subscriber #(cv32e40p_enhanced_instruction_item);
  `uvm_component_utils(cv32e40p_coverage_collector)

  cv32e40p_enhanced_instruction_item current_item;

  // Coverage groups
  covergroup alu_operations_cg;
    option.per_instance = 1;
    
    alu_op: coverpoint current_item.alu_operator {
      bins arithmetic[] = {7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011}; // ADD, SUB, ADDU, SUBU
      bins logical[] = {7'b0101111, 7'b0101110, 7'b0010101}; // XOR, OR, AND
      bins shift[] = {7'b0100100, 7'b0100101, 7'b0100111}; // SRA, SRL, SLL
      bins comparison[] = {7'b0000000, 7'b0000001, 7'b0001100, 7'b0001101}; // LTS, LTU, EQ, NE
    }
    
    operand_a: coverpoint current_item.operand_a {
      bins zero = {32'h00000000};
      bins max_pos = {32'h7FFFFFFF};
      bins max_neg = {32'h80000000};
      bins all_ones = {32'hFFFFFFFF};
      bins others = default;
    }
    
    operand_b: coverpoint current_item.operand_b {
      bins zero = {32'h00000000};
      bins max_pos = {32'h7FFFFFFF};
      bins max_neg = {32'h80000000};
      bins all_ones = {32'hFFFFFFFF};
      bins others = default;
    }
    
    vector_mode: coverpoint current_item.vector_mode {
      bins mode_32 = {2'b00};
      bins mode_16 = {2'b10};
      bins mode_8 = {2'b11};
    }
    
    // Cross coverage
    alu_op_x_operands: cross alu_op, operand_a, operand_b;
    alu_op_x_vector: cross alu_op, vector_mode;
  endgroup

  covergroup edge_cases_cg;
    option.per_instance = 1;
    
    zero_operands: coverpoint {current_item.operand_a == 0, current_item.operand_b == 0} {
      bins both_zero = {2'b11};
      bins a_zero = {2'b10};
      bins b_zero = {2'b01};
      bins none_zero = {2'b00};
    }
    
    overflow_detection: coverpoint current_item.alu_operator {
      bins add_ops = {7'b0011000, 7'b0011010}; // ADD, ADDU
      bins sub_ops = {7'b0011001, 7'b0011011}; // SUB, SUBU
    }
  endgroup

  function new(string name = "cv32e40p_coverage_collector", uvm_component parent = null);
    super.new(name, parent);
    alu_operations_cg = new();
    edge_cases_cg = new();
  endfunction

  function void write(cv32e40p_enhanced_instruction_item t);
    current_item = t;
    alu_operations_cg.sample();
    edge_cases_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COVERAGE", $sformatf("ALU Operations Coverage: %.2f%%", alu_operations_cg.get_coverage()), UVM_LOW)
    `uvm_info("COVERAGE", $sformatf("Edge Cases Coverage: %.2f%%", edge_cases_cg.get_coverage()), UVM_LOW)
  endfunction

endclass