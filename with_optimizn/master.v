`timescale 1ns/1ps
module axi4lite_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire ACLK,
    input wire ARESETN,

    // User interface
    input  wire                  start_write,
    input  wire                  start_read,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] write_data,
    input  wire [3:0]            write_strb,
    output reg  [DATA_WIDTH-1:0] read_data,
    output reg                   write_done,
    output reg                   read_done,
    output reg  [1:0]            write_resp,
    output reg  [1:0]            read_resp,

    // Write Address Channel
    output reg  [ADDR_WIDTH-1:0] M_AXI_AWADDR,
    output reg  [2:0]            M_AXI_AWPROT,
    output reg                   M_AXI_AWVALID,
    input  wire                  M_AXI_AWREADY,

    // Write Data Channel
    output reg  [DATA_WIDTH-1:0] M_AXI_WDATA,
    output reg  [DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output reg                   M_AXI_WVALID,
    input  wire                  M_AXI_WREADY,

    // Write Response Channel
    input  wire [1:0]            M_AXI_BRESP,
    input  wire                  M_AXI_BVALID,
    output reg                   M_AXI_BREADY,

    // Read Address Channel
    output reg  [ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output reg  [2:0]            M_AXI_ARPROT,
    output reg                   M_AXI_ARVALID,
    input  wire                  M_AXI_ARREADY,

    // Read Data Channel
    input  wire [DATA_WIDTH-1:0] M_AXI_RDATA,
    input  wire [1:0]            M_AXI_RRESP,
    input  wire                  M_AXI_RVALID,
    output reg                   M_AXI_RREADY
);

    // Write FSM states
    localparam W_IDLE = 3'd0;
    localparam W_ADDR = 3'd1;
    localparam W_DATA = 3'd2;
    localparam W_RESP = 3'd3;

    // Read FSM states
    localparam R_IDLE = 2'd0;
    localparam R_ADDR = 2'd1;
    localparam R_DATA = 2'd2;

    reg [2:0] write_state;
    reg [1:0] read_state;

    // internal flags to indicate whether AW/W handshake completed
    reg aw_accepted;
    reg w_accepted;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            write_state <= W_IDLE;
            M_AXI_AWADDR <= {ADDR_WIDTH{1'b0}};
            M_AXI_AWPROT <= 3'b000;
            M_AXI_AWVALID <= 1'b0;
            M_AXI_WDATA <= {DATA_WIDTH{1'b0}};
            M_AXI_WSTRB <= {(DATA_WIDTH/8){1'b0}};
            M_AXI_WVALID <= 1'b0;
            M_AXI_BREADY <= 1'b0;
            write_done <= 1'b0;
            write_resp <= {2{1'b0}};
            aw_accepted <= 1'b0;
            w_accepted <= 1'b0;
        end else begin
            // default single-cycle pulses zeroed
            write_done <= 1'b0;

            case (write_state)
                W_IDLE: begin
                    M_AXI_AWVALID <= 1'b0;
                    M_AXI_WVALID  <= 1'b0;
                    M_AXI_BREADY  <= 1'b0;
                    aw_accepted <= 1'b0;
                    w_accepted <= 1'b0;
                    if (start_write) begin
                        M_AXI_AWADDR <= addr;
                        M_AXI_AWPROT <= 3'b000;
                        M_AXI_AWVALID <= 1'b1;

                        M_AXI_WDATA <= write_data;
                        M_AXI_WSTRB <= write_strb;
                        M_AXI_WVALID <= 1'b1;

                        write_state <= W_ADDR;
                    end
                end

                W_ADDR: begin
                    // AW handshake
                    if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 1'b0;
                        aw_accepted <= 1'b1;
                    end

                    // W handshake
                    if (M_AXI_WVALID && M_AXI_WREADY) begin
                        M_AXI_WVALID <= 1'b0;
                        w_accepted <= 1'b1;
                    end

                    // if both accepted or both deasserted - move to response
                    if (aw_accepted && w_accepted) begin
                        M_AXI_BREADY <= 1'b1;
                        write_state <= W_RESP;
                    end
                end

                W_RESP: begin
                    if (M_AXI_BVALID) begin
                        write_resp <= M_AXI_BRESP;
                        M_AXI_BREADY <= 1'b0;
                        write_done <= 1'b1; // single-cycle pulse
                        write_state <= W_IDLE;
                        aw_accepted <= 1'b0;
                        w_accepted <= 1'b0;
                    end
                end

                default: write_state <= W_IDLE;
            endcase
        end
    end
    // READ FSM
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            read_state <= R_IDLE;
            M_AXI_ARADDR <= {ADDR_WIDTH{1'b0}};
            M_AXI_ARPROT <= 3'b000;
            M_AXI_ARVALID <= 1'b0;
            M_AXI_RREADY <= 1'b0;
            read_data <= {DATA_WIDTH{1'b0}};
            read_done <= 1'b0;
            read_resp <= {2{1'b0}};
        end else begin
            // default single-cycle pulse
            read_done <= 1'b0;

            case (read_state)
                R_IDLE: begin
                    M_AXI_ARVALID <= 1'b0;
                    M_AXI_RREADY <= 1'b0;
                    if (start_read) begin
                        M_AXI_ARADDR <= addr;
                        M_AXI_ARPROT <= 3'b000;
                        M_AXI_ARVALID <= 1'b1;
                        read_state <= R_ADDR;
                    end
                end

                R_ADDR: begin
                    if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 1'b0;
                        M_AXI_RREADY <= 1'b1; // accept read data
                        read_state <= R_DATA;
                    end
                end

                R_DATA: begin
                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        read_data <= M_AXI_RDATA;
                        read_resp <= M_AXI_RRESP;
                        M_AXI_RREADY <= 1'b0;
                        read_done <= 1'b1; // single-cycle pulse
                        read_state <= R_IDLE;
                    end
                end

                default: read_state <= R_IDLE;
            endcase
        end
    end

endmodule