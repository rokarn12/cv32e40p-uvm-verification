// Copyright 2024 ChipAgents
// UVM Driver for CV32E40P Core

class cv32e40p_driver extends uvm_driver #(cv32e40p_enhanced_instruction_item);
  `uvm_component_utils(cv32e40p_driver)

  // Virtual interface handle
  virtual cv32e40p_if vif;
  
  // Configuration object
  cv32e40p_config cfg;

  function new(string name = "cv32e40p_driver", uvm_component parent = null);
    super.new(name, parent);
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
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    cv32e40p_enhanced_instruction_item req;
    
    // Initialize interface
    initialize_interface();
    
    // Wait for reset deassertion
    wait_for_reset();
    
    forever begin
      // Get next transaction from sequencer
      seq_item_port.get_next_item(req);
      
      `uvm_info("DRIVER", $sformatf("Driving transaction: %s", req.convert2string()), UVM_MEDIUM)
      
      // Drive the transaction
      drive_transaction(req);
      
      // Signal completion
      seq_item_port.item_done();
    end
  endtask

  // Initialize interface signals
  task initialize_interface();
    vif.fetch_enable_i <= 1'b0;
    vif.boot_addr_i <= 32'h00000180;
    vif.mtvec_addr_i <= 32'h00000000;
    vif.dm_halt_addr_i <= 32'h1A110800;
    vif.hart_id_i <= 32'h00000000;
    vif.dm_exception_addr_i <= 32'h00000000;
    vif.debug_req_i <= 1'b0;
    vif.irq_i <= 32'h00000000;
    vif.pulp_clock_en_i <= 1'b1;
    vif.scan_cg_en_i <= 1'b0;
    
    // Memory interface initialization
    vif.instr_gnt_i <= 1'b0;
    vif.instr_rvalid_i <= 1'b0;
    vif.instr_rdata_i <= 32'h00000000;
    vif.data_gnt_i <= 1'b0;
    vif.data_rvalid_i <= 1'b0;
    vif.data_rdata_i <= 32'h00000000;
  endtask

  // Wait for reset deassertion
  task wait_for_reset();
    @(posedge vif.rst_ni);
    repeat(5) @(posedge vif.clk_i);
    `uvm_info("DRIVER", "Reset deasserted, starting operation", UVM_LOW)
  endtask

  // Drive a single transaction
  task drive_transaction(cv32e40p_enhanced_instruction_item req);
    // Enable fetch
    vif.fetch_enable_i <= 1'b1;
    
    // Handle instruction fetch and data access concurrently
    fork
      handle_instruction_fetch(req);
      handle_data_access(req);
    join_none
    
    // Wait for instruction completion
    wait_for_instruction_completion();
  endtask

  // Handle instruction fetch interface
  task handle_instruction_fetch(cv32e40p_enhanced_instruction_item req);
    // Wait for instruction request
    wait(vif.instr_req_o);
    
    // Provide grant immediately
    @(posedge vif.clk_i);
    vif.instr_gnt_i <= 1'b1;
    
    @(posedge vif.clk_i);
    vif.instr_gnt_i <= 1'b0;
    
    // Provide instruction data after 1-3 cycles (realistic memory latency)
    repeat($urandom_range(1, 3)) @(posedge vif.clk_i);
    
    vif.instr_rvalid_i <= 1'b1;
    vif.instr_rdata_i <= req.instruction;
    
    @(posedge vif.clk_i);
    vif.instr_rvalid_i <= 1'b0;
    vif.instr_rdata_i <= 32'h00000000;
  endtask

  // Handle data memory access interface
  task handle_data_access(cv32e40p_enhanced_instruction_item req);
    // Monitor for data requests and respond
    forever begin
      @(posedge vif.clk_i);
      if (vif.data_req_o) begin
        // Provide grant
        vif.data_gnt_i <= 1'b1;
        @(posedge vif.clk_i);
        vif.data_gnt_i <= 1'b0;
        
        // Provide data response after delay
        repeat($urandom_range(1, 2)) @(posedge vif.clk_i);
        vif.data_rvalid_i <= 1'b1;
        
        // For loads, provide random data; for stores, just acknowledge
        if (!vif.data_we_o) begin
          vif.data_rdata_i <= $urandom();
        end
        
        @(posedge vif.clk_i);
        vif.data_rvalid_i <= 1'b0;
        vif.data_rdata_i <= 32'h00000000;
        break;
      end
    end
  endtask

  // Wait for instruction completion
  task wait_for_instruction_completion();
    // Simple completion detection - wait for core to be ready for next instruction
    repeat(10) @(posedge vif.clk_i);
  endtask

endclass