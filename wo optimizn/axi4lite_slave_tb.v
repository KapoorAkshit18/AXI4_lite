`timescale 1ns / 1ps

module axi4lite_slave_tb();

    // Parameters
    parameter CLK_PERIOD = 10;

    // DUT Signals
    reg clk;
    reg resetn;
    reg [31:0] s_axi_awaddr;
    reg s_axi_awvalid;
    wire s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg [3:0] s_axi_wstrb;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_bready;
    reg [31:0] s_axi_araddr;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    reg s_axi_rready;

    wire [31:0] rw_reg0, rw_reg1, rw_reg2, rw_reg3;
    reg [31:0] ro_reg0, ro_reg1, ro_reg2, ro_reg3;

    // Instantiate DUT
    axi4lite_slave dut (
        .clk(clk),
        .resetn(resetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .rw_reg0(rw_reg0),
        .rw_reg1(rw_reg1),
        .rw_reg2(rw_reg2),
        .rw_reg3(rw_reg3),
        .ro_reg0(ro_reg0),
        .ro_reg1(ro_reg1),
        .ro_reg2(ro_reg2),
        .ro_reg3(ro_reg3)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task for AXI Lite Write
    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            s_axi_awaddr = addr;
            s_axi_awvalid = 1;
            s_axi_wdata = data;
            s_axi_wstrb = 4'hf; // Write all bytes
            s_axi_wvalid = 1;
            s_axi_bready = 1;

            // Wait for Ready signals
            wait(s_axi_awready && s_axi_wready);
            @(posedge clk);
            s_axi_awvalid = 0;
            s_axi_wvalid = 0;

            // Wait for Response
            wait(s_axi_bvalid);
            @(posedge clk);
            s_axi_bready = 0;
            $display("[WRITE] Addr: 0x%h, Data: 0x%h", addr, data);
        end
    endtask

    // Task for AXI Lite Read
    task axi_read(input [31:0] addr);
        begin
            @(posedge clk);
            s_axi_araddr = addr;
            s_axi_arvalid = 1;
            s_axi_rready = 1;

            wait(s_axi_arready);
            @(posedge clk);
            s_axi_arvalid = 0;

            wait(s_axi_rvalid);
            $display("[READ]  Addr: 0x%h, Data: 0x%h", addr, s_axi_rdata);
            @(posedge clk);
            s_axi_rready = 0;
        end
    endtask

    // Main Test Sequence
    initial begin
        // Initialize inputs
        resetn = 0;
        s_axi_awaddr = 0; s_axi_awvalid = 0;
        s_axi_wdata = 0; s_axi_wstrb = 0; s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0; s_axi_rready = 0;
        ro_reg0 = 32'hDEADBEEF; // Set a value for RO reg
        ro_reg1 = 32'hCAFEBABE;

        // Reset
        #(CLK_PERIOD * 5);
        resetn = 1;
        #(CLK_PERIOD * 5);

        // Test Cases
        axi_write(32'h00, 32'h12345678); // Write to rw_reg0
        axi_write(32'h04, 32'hAAAA5555); // Write to rw_reg1
        
        axi_read(32'h00);  // Should read back 12345678
        axi_read(32'h10);  // Should read DEADBEEF (ro_reg0)
        
        #(CLK_PERIOD * 10);
        $display("Simulation Finished");
        $finish;
    end

endmodule