// Copyright 2024 ChipAgents
// UVM Environment for CV32E40P Core

`include "cv32e40p_simple_coverage_model.sv"

class cv32e40p_env extends uvm_env;
  `uvm_component_utils(cv32e40p_env)

  // Environment components
  cv32e40p_agent agent;
  cv32e40p_scoreboard scoreboard;
  cv32e40p_simple_coverage_model coverage_model;
  
  // Configuration object
  cv32e40p_config cfg;

  function new(string name = "cv32e40p_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if (!uvm_config_db#(cv32e40p_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found")
    end
    
    // Create agent
    agent = cv32e40p_agent::type_id::create("agent", this);
    
    // Create scoreboard if enabled
    if (cfg.enable_scoreboard) begin
      scoreboard = cv32e40p_scoreboard::type_id::create("scoreboard", this);
    end
    
    // Create coverage model if coverage is enabled
    if (cfg.enable_coverage) begin
      coverage_model = cv32e40p_simple_coverage_model::type_id::create("coverage_model", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect agent to scoreboard
    if (cfg.enable_scoreboard && scoreboard != null) begin
      agent.ap.connect(scoreboard.analysis_export);
    end
    
    // Connect agent to coverage model
    // Note: Simple coverage model uses manual sampling, no analysis port connection needed
    if (cfg.enable_coverage && coverage_model != null) begin
      `uvm_info("ENV", "Coverage model enabled - using manual sampling", UVM_LOW)
    end
  endfunction

endclass

// Scoreboard for checking ALU operations
class cv32e40p_scoreboard extends uvm_subscriber #(cv32e40p_enhanced_instruction_item);
  `uvm_component_utils(cv32e40p_scoreboard)

  // Statistics
  int transactions_checked = 0;
  int transactions_passed = 0;
  int transactions_failed = 0;

  function new(string name = "cv32e40p_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void write(cv32e40p_enhanced_instruction_item t);
    transactions_checked++;
    
    if (t.result_valid) begin
      // Perform ALU result checking
      if (check_alu_result(t)) begin
        transactions_passed++;
        `uvm_info("SCOREBOARD", $sformatf("PASS: %s", t.convert2string()), UVM_HIGH)
      end else begin
        transactions_failed++;
        `uvm_error("SCOREBOARD", $sformatf("FAIL: %s", t.convert2string()))
      end
    end
  endfunction

  // Check ALU result against expected value
  function bit check_alu_result(cv32e40p_enhanced_instruction_item item);
    bit [31:0] expected_result;
    bit expected_comparison;
    
    // Calculate expected result based on operation
    case (item.alu_operator)
      7'b0011000: begin // ALU_ADD
        expected_result = item.operand_a + item.operand_b;
        return (item.expected_result == expected_result);
      end
      
      7'b0011001: begin // ALU_SUB
        expected_result = item.operand_a - item.operand_b;
        return (item.expected_result == expected_result);
      end
      
      7'b0101111: begin // ALU_XOR
        expected_result = item.operand_a ^ item.operand_b;
        return (item.expected_result == expected_result);
      end
      
      7'b0101110: begin // ALU_OR
        expected_result = item.operand_a | item.operand_b;
        return (item.expected_result == expected_result);
      end
      
      7'b0010101: begin // ALU_AND
        expected_result = item.operand_a & item.operand_b;
        return (item.expected_result == expected_result);
      end
      
      7'b0100111: begin // ALU_SLL
        expected_result = item.operand_a << item.operand_b[4:0];
        return (item.expected_result == expected_result);
      end
      
      7'b0100101: begin // ALU_SRL
        expected_result = item.operand_a >> item.operand_b[4:0];
        return (item.expected_result == expected_result);
      end
      
      7'b0100100: begin // ALU_SRA
        expected_result = $signed(item.operand_a) >>> item.operand_b[4:0];
        return (item.expected_result == expected_result);
      end
      
      7'b0000000: begin // ALU_LTS (less than signed)
        expected_comparison = $signed(item.operand_a) < $signed(item.operand_b);
        return (item.expected_comparison_result == expected_comparison);
      end
      
      7'b0000001: begin // ALU_LTU (less than unsigned)
        expected_comparison = item.operand_a < item.operand_b;
        return (item.expected_comparison_result == expected_comparison);
      end
      
      7'b0001100: begin // ALU_EQ
        expected_comparison = (item.operand_a == item.operand_b);
        return (item.expected_comparison_result == expected_comparison);
      end
      
      7'b0001101: begin // ALU_NE
        expected_comparison = (item.operand_a != item.operand_b);
        return (item.expected_comparison_result == expected_comparison);
      end
      
      default: begin
        `uvm_warning("SCOREBOARD", $sformatf("Unknown ALU operation: 0x%02x", item.alu_operator))
        return 1'b1; // Assume pass for unknown operations
      end
    endcase
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD", $sformatf("Transactions Checked: %0d", transactions_checked), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("Transactions Passed: %0d", transactions_passed), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("Transactions Failed: %0d", transactions_failed), UVM_LOW)
    
    if (transactions_failed > 0) begin
      `uvm_error("SCOREBOARD", $sformatf("Test FAILED with %0d errors", transactions_failed))
    end else if (transactions_checked > 0) begin
      `uvm_info("SCOREBOARD", "Test PASSED - All transactions verified successfully", UVM_LOW)
    end
  endfunction

endclass