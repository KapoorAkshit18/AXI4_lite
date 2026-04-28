`timescale 1ns/1ps

module tb_axi4lite;

    reg clk;
    reg resetn;

    // AXI signals
    reg  [31:0] s_axi_awaddr;
    reg         s_axi_awvalid;
    wire        s_axi_awready;

    reg  [31:0] s_axi_wdata;
    reg  [3:0]  s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;

    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    reg         s_axi_bready;

    reg  [31:0] s_axi_araddr;
    reg         s_axi_arvalid;
    wire        s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;

    wire [31:0] led_out;
    wire [31:0] control_out;

    // ============================
    // DUT
    // ============================
    top_axi4lite_system dut (
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

        .led_out(led_out),
        .control_out(control_out)
    );

    // ============================
    // Clock generation
    // ============================
    always #5 clk = ~clk; // 100 MHz

    // ============================
    // AXI WRITE TASK
    // ============================
    task axi_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge clk);

        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'hF;
        s_axi_wvalid  <= 1;
        s_axi_bready  <= 1;

        // wait handshake
        wait (s_axi_awready && s_axi_wready);

        @(posedge clk);
        s_axi_awvalid <= 0;
        s_axi_wvalid  <= 0;

        // wait response
        wait (s_axi_bvalid);
        @(posedge clk);

        s_axi_bready <= 0;
    end
    endtask

    // ============================
    // AXI READ TASK
    // ============================
    task axi_read(input [31:0] addr, output [31:0] data);
    begin
        @(posedge clk);

        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1;
        s_axi_rready  <= 1;

        // wait handshake
        wait (s_axi_arready);

        @(posedge clk);
        s_axi_arvalid <= 0;

        // wait data
        wait (s_axi_rvalid);
        data = s_axi_rdata;

        @(posedge clk);
        s_axi_rready <= 0;
    end
    endtask

    // ============================
    // Test sequence
    // ============================
    reg [31:0] read_data;

    initial begin
        // init
        clk = 0;
        resetn = 0;

        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wvalid = 0;
        s_axi_wstrb = 0;
        s_axi_bready = 0;

        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        #50;
        resetn = 1;

        #20;

        // ============================
        // WRITE TEST
        // ============================
        $display("WRITE TEST");

        axi_write(32'h00, 32'hAAAA5555);
        axi_write(32'h04, 32'h12345678);

        // ============================
        // READ BACK RW REGS
        // ============================
        $display("READ RW REGISTERS");

        axi_read(32'h00, read_data);
        $display("RW0 = %h", read_data);

        axi_read(32'h04, read_data);
        $display("RW1 = %h", read_data);

        // ============================
        // READ RO REG (counter)
        // ============================
        $display("READ RO REGISTER (counter)");

        axi_read(32'h10, read_data);
        $display("RO0 (counter) = %h", read_data);

        #100;

        $display("Simulation Finished");
        $stop;
    end

endmodule