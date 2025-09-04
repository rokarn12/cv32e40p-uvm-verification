// Copyright 2024 ChipAgents
// Basic UVM Test for CV32E40P Core

class cv32e40p_basic_test extends uvm_test;
  `uvm_component_utils(cv32e40p_basic_test)

  // Test environment
  cv32e40p_env env;
  cv32e40p_config cfg;

  function new(string name = "cv32e40p_basic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create configuration
    cfg = cv32e40p_config::type_id::create("cfg");
    
    // Load configuration from environment (set by Python script from JSON)
    cfg.load_from_env();
    
    // Print configuration summary
    cfg.print_config();
    
    // Validate configuration
    if (!cfg.validate_config()) begin
      `uvm_fatal("CONFIG", "Configuration validation failed")
    end
    
    // Set configuration in database
    uvm_config_db#(cv32e40p_config)::set(this, "*", "cfg", cfg);
    
    // Create environment
    env = cv32e40p_env::type_id::create("env", this);
    
    `uvm_info("TEST", "Basic test build phase completed", UVM_LOW)
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("TEST", "Test topology:", UVM_LOW)
    print();
  endfunction

  task run_phase(uvm_phase phase);
    cv32e40p_basic_sequence basic_seq;
    
    phase.raise_objection(this, "Starting basic test");
    
    `uvm_info("TEST", "Starting basic test run phase", UVM_LOW)
    
    // Create and start basic sequence
    basic_seq = cv32e40p_basic_sequence::type_id::create("basic_seq");
    basic_seq.num_transactions = cfg.num_random_instructions;
    
    basic_seq.start(env.agent.sequencer);
    
    // Wait for some additional cycles
    repeat(100) @(posedge env.agent.monitor.vif.clk_i);
    
    `uvm_info("TEST", "Basic test run phase completed", UVM_LOW)
    
    phase.drop_objection(this, "Basic test completed");
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("TEST", "Basic test report phase", UVM_LOW)
  endfunction

endclass

// Edge case test
class cv32e40p_edge_test extends uvm_test;
  `uvm_component_utils(cv32e40p_edge_test)

  cv32e40p_env env;
  cv32e40p_config cfg;

  function new(string name = "cv32e40p_edge_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    cfg = cv32e40p_config::type_id::create("cfg");
    
    // Load configuration from environment (set by Python script from JSON)
    cfg.load_from_env();
    
    // Print configuration summary
    cfg.print_config();
    
    // Validate configuration
    if (!cfg.validate_config()) begin
      `uvm_fatal("CONFIG", "Configuration validation failed")
    end
    
    uvm_config_db#(cv32e40p_config)::set(this, "*", "cfg", cfg);
    env = cv32e40p_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    cv32e40p_edge_case_sequence edge_seq;
    
    phase.raise_objection(this, "Starting edge case test");
    
    `uvm_info("TEST", "Starting edge case test", UVM_LOW)
    
    edge_seq = cv32e40p_edge_case_sequence::type_id::create("edge_seq");
    edge_seq.start(env.agent.sequencer);
    
    repeat(50) @(posedge env.agent.monitor.vif.clk_i);
    
    phase.drop_objection(this, "Edge case test completed");
  endtask

endclass