`timescale 1ns / 1ps

module tb_reset;

  // Parameters
  parameter BASE_ADDR = 8'h00;

  // Inputs
  reg nrst;
  reg clk_in;
  reg [7:0] abus;
  reg wr_en;
  reg rd_en;

  // Bidirs
  wire [7:0] dbus;
  wire [7:0] port_io;

  // Instantiate the Unit Under Test (UUT)
  port_io #(
    .base_addr(BASE_ADDR)
  ) uut (
    .nrst(nrst), 
    .clk_in(clk_in), 
    .abus(abus), 
    .dbus(dbus), 
    .wr_en(wr_en), 
    .rd_en(rd_en), 
    .port_io(port_io)
  );

  // Clock generation
  initial begin
    clk_in = 0;
    forever #5 clk_in = ~clk_in; // Clock period is 10ns
  end

  // Stimulus process
  initial begin
    // Initialize Inputs
    nrst = 1;
    abus = 0;
    wr_en = 0;
    rd_en = 0;

    // Hold reset state for 20 ns
    nrst = 0;
    #20;
    nrst = 1;

    // Wait for 20 ns to observe the reset effect
    #20;

    // Stop simulation
    $stop;
  end
      
endmodule
