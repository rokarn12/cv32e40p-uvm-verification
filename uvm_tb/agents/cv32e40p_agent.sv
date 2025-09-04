// Copyright 2024 ChipAgents
// UVM Agent for CV32E40P Core

class cv32e40p_agent extends uvm_agent;
  `uvm_component_utils(cv32e40p_agent)

  // Agent components
  cv32e40p_driver driver;
  cv32e40p_monitor monitor;
  uvm_sequencer #(cv32e40p_enhanced_instruction_item) sequencer;
  
  // Configuration object
  cv32e40p_config cfg;
  
  // Analysis port from monitor
  uvm_analysis_port #(cv32e40p_enhanced_instruction_item) ap;

  function new(string name = "cv32e40p_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if (!uvm_config_db#(cv32e40p_config)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NOCFG", "Configuration object not found")
    end
    
    // Create monitor (always present)
    monitor = cv32e40p_monitor::type_id::create("monitor", this);
    
    // Create driver and sequencer only if agent is active
    if (get_is_active() == UVM_ACTIVE) begin
      driver = cv32e40p_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(cv32e40p_enhanced_instruction_item)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect analysis port
    ap = monitor.ap;
    
    // Connect driver and sequencer if active
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass