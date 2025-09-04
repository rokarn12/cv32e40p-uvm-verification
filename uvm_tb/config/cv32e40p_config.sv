// Copyright 2024 ChipAgents
// UVM Configuration Class for CV32E40P Testbench

class cv32e40p_config extends uvm_object;
  `uvm_object_utils(cv32e40p_config)

  // Test identification
  string test_name = "cv32e40p_basic_test";
  string description = "";
  string test_class = "";
  string sequence_name = "";
  
  // Test configuration parameters
  bit enable_coverage = 1;
  bit enable_assertions = 1;
  bit enable_scoreboard = 1;
  bit enable_logging = 1;
  string verbosity = "UVM_LOW";
  
  // DUT configuration parameters
  bit COREV_PULP = 0;
  bit COREV_CLUSTER = 0;
  bit FPU = 0;
  bit ZFINX = 0;
  int NUM_MHPMCOUNTERS = 1;
  int FPU_ADDMUL_LAT = 0;
  int FPU_OTHERS_LAT = 0;
  
  // Simulation parameters
  int max_cycles = 10000;
  int timeout_cycles = 50000;
  
  // ALU-specific test parameters
  bit focus_alu_testing = 1;
  bit enable_vector_ops = 1;
  bit enable_div_ops = 1;
  bit enable_bit_manip = 1;
  
  // Stimulus configuration
  int num_random_instructions = 1000;
  int directed_test_iterations = 100;
  
  // Build options
  bit enable_waves = 0;
  bit enable_debug = 1;
  string optimization_level = "none";
  
  function new(string name = "cv32e40p_config");
    super.new(name);
  endfunction

  // Load configuration from environment variables (set by Python script)
  function void load_from_env();
    string env_val;
    
    // Test parameters
    if ($value$plusargs("TEST_NAME=%s", env_val)) test_name = env_val;
    if ($value$plusargs("DESCRIPTION=%s", env_val)) description = env_val;
    if ($value$plusargs("TEST_CLASS=%s", env_val)) test_class = env_val;
    if ($value$plusargs("SEQUENCE=%s", env_val)) sequence_name = env_val;
    if ($value$plusargs("VERBOSITY=%s", env_val)) verbosity = env_val;
    
    // Boolean flags
    enable_coverage = $test$plusargs("ENABLE_COVERAGE");
    enable_assertions = $test$plusargs("ENABLE_ASSERTIONS");
    enable_scoreboard = $test$plusargs("ENABLE_SCOREBOARD");
    enable_logging = $test$plusargs("ENABLE_LOGGING");
    enable_waves = $test$plusargs("ENABLE_WAVES");
    enable_debug = $test$plusargs("ENABLE_DEBUG");
    
    // DUT configuration
    if ($value$plusargs("COREV_PULP=%d", COREV_PULP)) ;
    if ($value$plusargs("COREV_CLUSTER=%d", COREV_CLUSTER)) ;
    if ($value$plusargs("FPU=%d", FPU)) ;
    if ($value$plusargs("ZFINX=%d", ZFINX)) ;
    if ($value$plusargs("NUM_MHPMCOUNTERS=%d", NUM_MHPMCOUNTERS)) ;
    if ($value$plusargs("FPU_ADDMUL_LAT=%d", FPU_ADDMUL_LAT)) ;
    if ($value$plusargs("FPU_OTHERS_LAT=%d", FPU_OTHERS_LAT)) ;
    
    // Simulation parameters
    if ($value$plusargs("MAX_CYCLES=%d", max_cycles)) ;
    if ($value$plusargs("TIMEOUT_CYCLES=%d", timeout_cycles)) ;
    if ($value$plusargs("NUM_RANDOM_INSTRUCTIONS=%d", num_random_instructions)) ;
    
    // ALU configuration
    focus_alu_testing = $test$plusargs("FOCUS_ALU_TESTING");
    enable_vector_ops = $test$plusargs("ENABLE_VECTOR_OPS");
    enable_div_ops = $test$plusargs("ENABLE_DIV_OPS");
    enable_bit_manip = $test$plusargs("ENABLE_BIT_MANIP");
    
    if ($value$plusargs("OPTIMIZATION_LEVEL=%s", env_val)) optimization_level = env_val;
    
    `uvm_info("CONFIG", $sformatf("Loaded configuration for test: %s", test_name), UVM_LOW)
  endfunction

  // Configuration validation
  function bit validate_config();
    if (max_cycles <= 0) begin
      `uvm_error("CONFIG", "max_cycles must be positive")
      return 0;
    end
    if (timeout_cycles <= max_cycles) begin
      `uvm_error("CONFIG", "timeout_cycles must be greater than max_cycles")
      return 0;
    end
    if (test_name == "") begin
      `uvm_error("CONFIG", "test_name cannot be empty")
      return 0;
    end
    return 1;
  endfunction

  // Print configuration summary
  function void print_config();
    `uvm_info("CONFIG", "=== CV32E40P Test Configuration ===", UVM_LOW)
    `uvm_info("CONFIG", $sformatf("Test Name: %s", test_name), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("Description: %s", description), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("Test Class: %s", test_class), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("Sequence: %s", sequence_name), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("Verbosity: %s", verbosity), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("Coverage: %b, Scoreboard: %b, Waves: %b", 
              enable_coverage, enable_scoreboard, enable_waves), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("DUT Config: PULP=%b, FPU=%b, ZFINX=%b", 
              COREV_PULP, FPU, ZFINX), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("Cycles: max=%0d, timeout=%0d, instructions=%0d", 
              max_cycles, timeout_cycles, num_random_instructions), UVM_LOW)
    `uvm_info("CONFIG", "===================================", UVM_LOW)
  endfunction

endclass