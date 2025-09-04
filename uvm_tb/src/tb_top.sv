// Copyright 2024 ChipAgents
// Testbench Top Module for CV32E40P UVM Testbench

module tb_top;

  import uvm_pkg::*;
  import cv32e40p_uvm_pkg::*;
  `include "uvm_macros.svh"

  // Clock and reset generation
  logic clk;
  logic rst_n;

  // Clock generation
  initial begin
    clk = 0;
    forever #5ns clk = ~clk; // 100MHz clock
  end

  // Reset generation
  initial begin
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
    `uvm_info("TB_TOP", "Reset deasserted", UVM_LOW)
  end

  // Interface instantiation
  cv32e40p_if dut_if (
    .clk_i(clk),
    .rst_ni(rst_n)
  );

  // DUT instantiation
  cv32e40p_top dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .fetch_enable_i(dut_if.fetch_enable_i),
    .boot_addr_i(dut_if.boot_addr_i),
    .mtvec_addr_i(dut_if.mtvec_addr_i),
    .dm_halt_addr_i(dut_if.dm_halt_addr_i),
    .hart_id_i(dut_if.hart_id_i),
    .dm_exception_addr_i(dut_if.dm_exception_addr_i),
    .pulp_clock_en_i(dut_if.pulp_clock_en_i),
    .scan_cg_en_i(dut_if.scan_cg_en_i),
    .instr_req_o(dut_if.instr_req_o),
    .instr_gnt_i(dut_if.instr_gnt_i),
    .instr_rvalid_i(dut_if.instr_rvalid_i),
    .instr_addr_o(dut_if.instr_addr_o),
    .instr_rdata_i(dut_if.instr_rdata_i),
    .data_req_o(dut_if.data_req_o),
    .data_gnt_i(dut_if.data_gnt_i),
    .data_rvalid_i(dut_if.data_rvalid_i),
    .data_we_o(dut_if.data_we_o),
    .data_be_o(dut_if.data_be_o),
    .data_addr_o(dut_if.data_addr_o),
    .data_wdata_o(dut_if.data_wdata_o),
    .data_rdata_i(dut_if.data_rdata_i),
    .irq_i(dut_if.irq_i),
    .irq_ack_o(dut_if.irq_ack_o),
    .irq_id_o(dut_if.irq_id_o),
    .debug_req_i(dut_if.debug_req_i),
    .debug_havereset_o(dut_if.debug_havereset_o),
    .debug_running_o(dut_if.debug_running_o),
    .debug_halted_o(dut_if.debug_halted_o),
    .core_sleep_o(dut_if.core_sleep_o)
  );

  // Set interface in config database
  initial begin
    uvm_config_db#(virtual cv32e40p_if)::set(null, "*", "vif", dut_if);
  end

  // Timeout mechanism
  initial begin
    #1ms; // 1 millisecond timeout
    `uvm_error("TB_TOP", "Test timeout!")
    $finish;
  end

  // Waveform dumping
  initial begin
    if ($test$plusargs("DUMP_WAVES")) begin
      $dumpfile("cv32e40p_test.vcd");
      $dumpvars(0, tb_top);
      `uvm_info("TB_TOP", "Waveform dumping enabled", UVM_LOW)
    end
  end

  // Start UVM test
  initial begin
    `uvm_info("TB_TOP", "Starting UVM testbench", UVM_LOW)
    run_test();
  end

  // Monitor for basic functionality
  initial begin
    wait(rst_n);
    `uvm_info("TB_TOP", "Monitoring DUT signals", UVM_LOW)
    
    // Simple signal monitoring
    forever begin
      @(posedge clk);
      if (dut_if.instr_req_o) begin
        `uvm_info("TB_TOP", $sformatf("Instruction request at PC=0x%08x", dut_if.instr_addr_o), UVM_HIGH)
      end
      if (dut_if.data_req_o) begin
        `uvm_info("TB_TOP", $sformatf("Data request: addr=0x%08x, we=%b", dut_if.data_addr_o, dut_if.data_we_o), UVM_HIGH)
      end
    end
  end

endmodule