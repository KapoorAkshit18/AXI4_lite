`timescale 1ns/1ps
module axi4lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS = 16
)(
    input wire ACLK,
    input wire ARESETN,

    // Write Address Channel
    input  wire [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [2:0]            S_AXI_AWPROT,
    input  wire                  S_AXI_AWVALID,
    output reg                   S_AXI_AWREADY,

    // Write Data Channel
    input  wire [DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input  wire                  S_AXI_WVALID,
    output reg                   S_AXI_WREADY,

    // Write Response Channel
    output reg  [1:0]            S_AXI_BRESP,
    output reg                   S_AXI_BVALID,
    input  wire                  S_AXI_BREADY,

    // Read Address Channel
    input  wire [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire [2:0]            S_AXI_ARPROT,
    input  wire                  S_AXI_ARVALID,
    output reg                   S_AXI_ARREADY,

    // Read Data Channel
    output reg  [DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg  [1:0]            S_AXI_RRESP,
    output reg                   S_AXI_RVALID,
    input  wire                  S_AXI_RREADY
);

    // Response types
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;

    // Internal register file
    reg [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];

    // Internal address/data latches and flags
    reg [ADDR_WIDTH-1:0] aw_addr_latch;
    reg aw_valid_latched;    // true when AW handshake accepted and awaiting W
    reg w_valid_latched;     // true when W handshake accepted and awaiting AW
    reg [DATA_WIDTH-1:0]  wdata_latch;
    reg [DATA_WIDTH/8-1:0] wstrb_latch;

    // Read address latch
    reg [ADDR_WIDTH-1:0] ar_addr_latch;
    reg ar_valid_latched;    // true when AR handshake accepted and R not yet returned

    integer i;

    // reset init
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}};
            end
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b0;
            S_AXI_BRESP   <= RESP_OKAY;
            aw_addr_latch <= {ADDR_WIDTH{1'b0}};
            aw_valid_latched <= 1'b0;
            wdata_latch <= {DATA_WIDTH{1'b0}};
            wstrb_latch <= {(DATA_WIDTH/8){1'b0}};
            w_valid_latched <= 1'b0;
            S_AXI_ARREADY <= 1'b0;
            ar_addr_latch <= {ADDR_WIDTH{1'b0}};
            ar_valid_latched <= 1'b0;
            S_AXI_RVALID <= 1'b0;
            S_AXI_RDATA  <= {DATA_WIDTH{1'b0}};
            S_AXI_RRESP  <= RESP_OKAY;
        end else begin
            // -----------------------
            // WRITE ADDRESS HANDSHAKE
            // Accept AW when AWVALID asserted and previous AW not latched
            // -----------------------
            if (!aw_valid_latched) begin
                if (S_AXI_AWVALID) begin
                    S_AXI_AWREADY <= 1'b1;
                    if (S_AXI_AWREADY && S_AXI_AWVALID) begin
                        aw_addr_latch <= S_AXI_AWADDR;
                        aw_valid_latched <= 1'b1;
                        S_AXI_AWREADY <= 1'b0; // deassert after accept
                    end
                end else begin
                    S_AXI_AWREADY <= 1'b0;
                end
            end else begin
                // if already latched, keep AWREADY low
                S_AXI_AWREADY <= 1'b0;
            end

            // WRITE DATA HANDSHAKE
            // Accept W when WVALID asserted and previous W not latched
            if (!w_valid_latched) begin
                if (S_AXI_WVALID) begin
                    S_AXI_WREADY <= 1'b1;
                    if (S_AXI_WREADY && S_AXI_WVALID) begin
                        wdata_latch <= S_AXI_WDATA;
                        wstrb_latch <= S_AXI_WSTRB;
                        w_valid_latched <= 1'b1;
                        S_AXI_WREADY <= 1'b0; // deassert after accept
                    end
                end else begin
                    S_AXI_WREADY <= 1'b0;
                end
            end else begin
                S_AXI_WREADY <= 1'b0;
            end

            // PERFORM WRITE when both AW and W latched
            // then assert BVALID until master accepts with BREADY
            if (aw_valid_latched && w_valid_latched && !S_AXI_BVALID) begin
                // address -> index (word addressing, address[1:0] ignored)
                if ((aw_addr_latch >> 2) < NUM_REGS) begin
                    // apply byte strobes
                    if (wstrb_latch[0]) registers[aw_addr_latch >> 2][7:0]   <= wdata_latch[7:0];
                    if (wstrb_latch[1]) registers[aw_addr_latch >> 2][15:8]  <= wdata_latch[15:8];
                    if (wstrb_latch[2]) registers[aw_addr_latch >> 2][23:16] <= wdata_latch[23:16];
                    if (wstrb_latch[3]) registers[aw_addr_latch >> 2][31:24] <= wdata_latch[31:24];
                    S_AXI_BRESP <= RESP_OKAY;
                end else begin
                    // invalid address
                    S_AXI_BRESP <= RESP_SLVERR;
                end
                // mark response valid and clear latched flags (response waits for BREADY)
                S_AXI_BVALID <= 1'b1;
                aw_valid_latched <= 1'b0;
                w_valid_latched <= 1'b0;
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                // master accepted B, deassert
                S_AXI_BVALID <= 1'b0;
            end

            // READ ADDRESS HANDSHAKE
            if (!ar_valid_latched) begin
                if (S_AXI_ARVALID) begin
                    S_AXI_ARREADY <= 1'b1;
                    if (S_AXI_ARREADY && S_AXI_ARVALID) begin
                        ar_addr_latch <= S_AXI_ARADDR;
                        ar_valid_latched <= 1'b1;
                        S_AXI_ARREADY <= 1'b0;
                    end
                end else begin
                    S_AXI_ARREADY <= 1'b0;
                end
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end
            // READ DATA CHANNEL
            // when AR latched and R not yet valid -> present data
            if (ar_valid_latched && !S_AXI_RVALID) begin
                if ((ar_addr_latch >> 2) < NUM_REGS) begin
                    S_AXI_RDATA <= registers[ar_addr_latch >> 2];
                    S_AXI_RRESP <= RESP_OKAY;
                end else begin
                    S_AXI_RDATA <= {DATA_WIDTH{1'b0}} ^ 32'hDEADBEEF; // sentinel
                    S_AXI_RRESP <= RESP_SLVERR;
                end
                S_AXI_RVALID <= 1'b1;
                ar_valid_latched <= 1'b0; // R now being presented
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule