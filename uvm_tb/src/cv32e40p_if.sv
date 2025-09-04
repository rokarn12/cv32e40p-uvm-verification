// Copyright 2024 ChipAgents
// Virtual Interface for CV32E40P Core

interface cv32e40p_if (
  input logic clk_i,
  input logic rst_ni
);

  // Core control signals
  logic        fetch_enable_i;
  logic [31:0] boot_addr_i;
  logic [31:0] mtvec_addr_i;
  logic [31:0] dm_halt_addr_i;
  logic [31:0] hart_id_i;
  logic [31:0] dm_exception_addr_i;
  logic        pulp_clock_en_i;
  logic        scan_cg_en_i;

  // Instruction memory interface
  logic        instr_req_o;
  logic        instr_gnt_i;
  logic        instr_rvalid_i;
  logic [31:0] instr_addr_o;
  logic [31:0] instr_rdata_i;

  // Data memory interface
  logic        data_req_o;
  logic        data_gnt_i;
  logic        data_rvalid_i;
  logic        data_we_o;
  logic [ 3:0] data_be_o;
  logic [31:0] data_addr_o;
  logic [31:0] data_wdata_o;
  logic [31:0] data_rdata_i;

  // Interrupt interface
  logic [31:0] irq_i;
  logic        irq_ack_o;
  logic [ 4:0] irq_id_o;

  // Debug interface
  logic        debug_req_i;
  logic        debug_havereset_o;
  logic        debug_running_o;
  logic        debug_halted_o;

  // Core status
  logic        core_sleep_o;

  // Clocking blocks for synchronous operation
  clocking driver_cb @(posedge clk_i);
    default input #1step output #1step;
    output fetch_enable_i, boot_addr_i, mtvec_addr_i, dm_halt_addr_i;
    output hart_id_i, dm_exception_addr_i, pulp_clock_en_i, scan_cg_en_i;
    output instr_gnt_i, instr_rvalid_i, instr_rdata_i;
    output data_gnt_i, data_rvalid_i, data_rdata_i;
    output irq_i, debug_req_i;
    input  instr_req_o, instr_addr_o;
    input  data_req_o, data_we_o, data_be_o, data_addr_o, data_wdata_o;
    input  irq_ack_o, irq_id_o;
    input  debug_havereset_o, debug_running_o, debug_halted_o;
    input  core_sleep_o;
  endclocking

  clocking monitor_cb @(posedge clk_i);
    default input #1step;
    input fetch_enable_i, boot_addr_i, mtvec_addr_i, dm_halt_addr_i;
    input hart_id_i, dm_exception_addr_i, pulp_clock_en_i, scan_cg_en_i;
    input instr_gnt_i, instr_rvalid_i, instr_rdata_i;
    input data_gnt_i, data_rvalid_i, data_rdata_i;
    input irq_i, debug_req_i;
    input instr_req_o, instr_addr_o;
    input data_req_o, data_we_o, data_be_o, data_addr_o, data_wdata_o;
    input irq_ack_o, irq_id_o;
    input debug_havereset_o, debug_running_o, debug_halted_o;
    input core_sleep_o;
  endclocking

  // Modports for driver and monitor
  modport driver_mp (
    clocking driver_cb,
    input clk_i, rst_ni
  );

  modport monitor_mp (
    clocking monitor_cb,
    input clk_i, rst_ni
  );

endinterface