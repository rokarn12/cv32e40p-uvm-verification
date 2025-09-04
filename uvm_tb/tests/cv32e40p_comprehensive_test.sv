// Copyright 2024 ChipAgents
// Comprehensive CV32E40P Test - Stage 2 Implementation

class cv32e40p_comprehensive_test extends cv32e40p_basic_test;
  `uvm_component_utils(cv32e40p_comprehensive_test)

  function new(string name = "cv32e40p_comprehensive_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("COMP_TEST", "Building comprehensive test with enhanced sequences", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    cv32e40p_alu_random_sequence alu_seq;
    cv32e40p_division_directed_sequence div_seq;
    cv32e40p_hazard_injection_sequence hazard_seq;
    
    phase.raise_objection(this);
    
    `uvm_info("COMP_TEST", "Starting comprehensive CV32E40P verification", UVM_LOW)
    
    // Phase 1: Basic ALU operations with constrained random
    `uvm_info("COMP_TEST", "=== Phase 1: Constrained Random ALU Testing ===", UVM_LOW)
    alu_seq = cv32e40p_alu_random_sequence::type_id::create("alu_seq");
    if (!alu_seq.randomize() with {
      num_instructions == 50;
      enable_corner_cases == 1;
      enable_pulp_extensions == 1;
    }) begin
      `uvm_error("COMP_TEST", "Failed to randomize ALU sequence")
    end
    alu_seq.start(env.agent.sequencer);
    
    // Phase 2: Directed division edge cases
    `uvm_info("COMP_TEST", "=== Phase 2: Directed Division Edge Cases ===", UVM_LOW)
    div_seq = cv32e40p_division_directed_sequence::type_id::create("div_seq");
    div_seq.start(env.agent.sequencer);
    
    // Phase 3: Hazard injection testing
    `uvm_info("COMP_TEST", "=== Phase 3: Pipeline Hazard Injection ===", UVM_LOW)
    hazard_seq = cv32e40p_hazard_injection_sequence::type_id::create("hazard_seq");
    if (!hazard_seq.randomize() with {
      num_hazard_pairs == 15;
    }) begin
      `uvm_error("COMP_TEST", "Failed to randomize hazard sequence")
    end
    hazard_seq.start(env.agent.sequencer);
    
    // Phase 4: Mixed workload simulation
    `uvm_info("COMP_TEST", "=== Phase 4: Mixed Workload Simulation ===", UVM_LOW)
    repeat(3) begin
      // Alternate between different sequence types
      alu_seq = cv32e40p_alu_random_sequence::type_id::create("mixed_alu_seq");
      if (!alu_seq.randomize() with {
        num_instructions == 25;
        enable_corner_cases == 0; // Normal distribution
        enable_pulp_extensions == 1;
      }) begin
        `uvm_error("COMP_TEST", "Failed to randomize mixed ALU sequence")
      end
      alu_seq.start(env.agent.sequencer);
      
      // Add some hazards
      hazard_seq = cv32e40p_hazard_injection_sequence::type_id::create("mixed_hazard_seq");
      if (!hazard_seq.randomize() with {
        num_hazard_pairs == 5;
      }) begin
        `uvm_error("COMP_TEST", "Failed to randomize mixed hazard sequence")
      end
      hazard_seq.start(env.agent.sequencer);
    end
    
    // Phase 5: Performance characterization
    `uvm_info("COMP_TEST", "=== Phase 5: Performance Characterization ===", UVM_LOW)
    // High-IPC sequence (mostly single-cycle instructions)
    alu_seq = cv32e40p_alu_random_sequence::type_id::create("perf_seq");
    if (!alu_seq.randomize() with {
      num_instructions == 100;
      enable_corner_cases == 0;
      enable_pulp_extensions == 1;
    }) begin
      `uvm_error("COMP_TEST", "Failed to randomize performance sequence")
    end
    alu_seq.start(env.agent.sequencer);
    
    `uvm_info("COMP_TEST", "Comprehensive test completed successfully", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("COMP_TEST", "=== Comprehensive Test Summary ===", UVM_LOW)
    `uvm_info("COMP_TEST", "Test Phases Completed:", UVM_LOW)
    `uvm_info("COMP_TEST", "  1. Constrained Random ALU (50 instructions)", UVM_LOW)
    `uvm_info("COMP_TEST", "  2. Directed Division Edge Cases (36 test vectors)", UVM_LOW)
    `uvm_info("COMP_TEST", "  3. Pipeline Hazard Injection (15 hazard pairs)", UVM_LOW)
    `uvm_info("COMP_TEST", "  4. Mixed Workload Simulation (3 iterations)", UVM_LOW)
    `uvm_info("COMP_TEST", "  5. Performance Characterization (100 instructions)", UVM_LOW)
    `uvm_info("COMP_TEST", "Total estimated instructions: ~300+", UVM_LOW)
    `uvm_info("COMP_TEST", "Coverage areas tested:", UVM_LOW)
    `uvm_info("COMP_TEST", "  - Basic ALU operations with corner cases", UVM_LOW)
    `uvm_info("COMP_TEST", "  - Division edge cases and error handling", UVM_LOW)
    `uvm_info("COMP_TEST", "  - Pipeline hazards and forwarding", UVM_LOW)
    `uvm_info("COMP_TEST", "  - PULP extension instructions", UVM_LOW)
    `uvm_info("COMP_TEST", "  - Performance characteristics", UVM_LOW)
  endfunction

endclass