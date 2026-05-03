/*
 * Module: axi4lite_slave
 * Author: controlpaths.com
 * Date: 4/27/2026
 * Description: 
 *   This module implements an AXI4-Lite slave interface with 4 read-write (RW) 
 *   registers and 4 read-only (RO) registers. The RW registers are writable 
 *   via the AXI4-Lite interface and accessible externally. The RO registers are 
 *   read-only from the AXI4-Lite interface and their values are driven externally.
 *
 * Features:
 *   - AXI4-Lite protocol compliance
 *   - Individual access to RW and RO registers
 *   - Address decoding for up to 8 registers
 *
 * Register Map:
 *   0x00     | RW Register 0
 *   0x04     | RW Register 1
 *   0x08     | RW Register 2
 *   0x0C     | RW Register 3
 *   0x10     | RO Register 0
 *   0x14     | RO Register 1
 *   0x18     | RO Register 2
 *   0x1C     | RO Register 3
 */

module axi4lite_slave (
    input wire          clk,
    input wire          resetn,
    input wire [31:0]   s_axi_awaddr,
    input wire          s_axi_awvalid,
    output wire         s_axi_awready,
    input wire [31:0]   s_axi_wdata,
    input wire [3:0]    s_axi_wstrb,
    input wire          s_axi_wvalid,
    output wire         s_axi_wready,
    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input wire          s_axi_bready,
    input wire [31:0]   s_axi_araddr,
    input wire          s_axi_arvalid,
    output wire         s_axi_arready,
    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input wire          s_axi_rready,
    output reg [31:0]   rw_reg0,
    output reg [31:0]   rw_reg1,
    output reg [31:0]   rw_reg2,
    output reg [31:0]   rw_reg3,
    input wire [31:0]   ro_reg0,
    input wire [31:0]   ro_reg1,
    input wire [31:0]   ro_reg2,
    input wire [31:0]   ro_reg3
);

// ports 


    // Internal signals
    reg [31:0] rdata_reg;
    reg rvalid_reg, bvalid_reg;
    reg s_axi_awready_reg, wready_reg, arready_reg;

    assign s_axi_awready = s_axi_awready_reg;

    assign s_axi_wready = wready_reg;

    assign s_axi_bresp = 2'b00; // OKAY response

    assign s_axi_bvalid = bvalid_reg;

    assign s_axi_arready = arready_reg;
  
  assign s_axi_rdata = rdata_reg;

    assign s_axi_rresp = 2'b00; // OKAY response

    assign s_axi_rvalid = rvalid_reg;

    localparam integer ADDR_LSB = 2; // 32-bit word aligned
    localparam integer OPT_MEM_ADDR_BITS = 3;

    // Write address handshake
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axi_awready_reg <= 1'b0;
        end else if (s_axi_awvalid && !s_axi_awready_reg) begin
            s_axi_awready_reg <= 1'b1;
        end else begin
            s_axi_awready_reg <= 1'b0;
        end
    end

    // Write data handshake
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            wready_reg <= 1'b0;
            bvalid_reg <= 1'b0;
        end else if (s_axi_wvalid && !wready_reg) begin
            wready_reg <= 1'b1;
            case (s_axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS-1:ADDR_LSB])
                3'd0: begin
                    if (s_axi_wstrb[0]) rw_reg0[7:0] <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) rw_reg0[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) rw_reg0[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) rw_reg0[31:24] <= s_axi_wdata[31:24];
                end
                3'd1: begin
                    if (s_axi_wstrb[0]) rw_reg1[7:0] <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) rw_reg1[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) rw_reg1[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) rw_reg1[31:24] <= s_axi_wdata[31:24];
                end
                3'd2: begin
                    if (s_axi_wstrb[0]) rw_reg2[7:0] <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) rw_reg2[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) rw_reg2[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) rw_reg2[31:24] <= s_axi_wdata[31:24];
                end
                3'd3: begin
                    if (s_axi_wstrb[0]) rw_reg3[7:0] <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) rw_reg3[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) rw_reg3[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) rw_reg3[31:24] <= s_axi_wdata[31:24];
                end
                default: begin
                    // Handle invalid addresses
                end
            endcase
            bvalid_reg <= 1'b1;
        end else if (s_axi_bready && bvalid_reg) begin
            bvalid_reg <= 1'b0;
        end else begin
            wready_reg <= 1'b0;
        end
    end

    // Read address handshake
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            arready_reg <= 1'b0;
            rvalid_reg <= 1'b0;
        end else if (s_axi_arvalid && !arready_reg) begin
            arready_reg <= 1'b1;
            case (s_axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS-1:ADDR_LSB])
                3'd0: rdata_reg <= rw_reg0;
                3'd1: rdata_reg <= rw_reg1;
                3'd2: rdata_reg <= rw_reg2;
                3'd3: rdata_reg <= rw_reg3;
                3'd4: rdata_reg <= ro_reg0;
                3'd5: rdata_reg <= ro_reg1;
                3'd6: rdata_reg <= ro_reg2;
                3'd7: rdata_reg <= ro_reg3;
                default: rdata_reg <= 32'h00000000; // Default value
            endcase
            rvalid_reg <= 1'b1;
        end else if (s_axi_rready && rvalid_reg) begin
            rvalid_reg <= 1'b0;
        end else begin
            arready_reg <= 1'b0;
        end
    end

endmodule
