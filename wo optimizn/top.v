module top_axi4lite_system (

    input  wire         clk,
    input  wire         resetn,

    // AXI4-Lite interface (from master like CPU / testbench)
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,

    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,

    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,

    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,

    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,

    // Example external outputs (driven by RW regs)
    output wire [31:0]  led_out,
    output wire [31:0]  control_out
);

    // ============================
    // Internal Signals
    // ============================

    wire [31:0] rw_reg0;
    wire [31:0] rw_reg1;
    wire [31:0] rw_reg2;
    wire [31:0] rw_reg3;

    reg  [31:0] ro_reg0;
    reg  [31:0] ro_reg1;
    reg  [31:0] ro_reg2;
    reg  [31:0] ro_reg3;

    // ============================
    // Example Logic for RO registers
    // ============================

    reg [31:0] counter;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            counter <= 32'd0;
        end else begin
            counter <= counter + 1;
        end
    end

    always @(posedge clk) begin
        ro_reg0 <= counter;          // free-running counter
        ro_reg1 <= 32'h12345678;     // constant
        ro_reg2 <= rw_reg0 + rw_reg1; // dependent on RW regs
        ro_reg3 <= rw_reg2 ^ rw_reg3; // simple combinational relation
    end

    // ============================
    // Map RW registers to outputs
    // ============================

    assign led_out     = rw_reg0;   // e.g., LEDs
    assign control_out = rw_reg1;   // control signals

    // ============================
    // Instantiate AXI4-Lite Slave
    // ============================

    axi4lite_slave u_axi_slave (
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

endmodule