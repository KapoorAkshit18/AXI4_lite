`timescale 1ns/1ps
module axi4lite_system #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire ACLK,
    input wire ARESETN,

    // Master user interface
    input  wire                  start_write,
    input  wire                  start_read,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] write_data,
    input  wire [3:0]            write_strb,
    output wire [DATA_WIDTH-1:0] read_data,
    output wire                  write_done,
    output wire                  read_done,
    output wire [1:0]            write_resp,
    output wire [1:0]            read_resp
);

    // AXI4-Lite interface wires
    wire [ADDR_WIDTH-1:0] axi_awaddr;
    wire [2:0]            axi_awprot;
    wire                  axi_awvalid;
    wire                  axi_awready;

    wire [DATA_WIDTH-1:0] axi_wdata;
    wire [DATA_WIDTH/8-1:0] axi_wstrb;
    wire                  axi_wvalid;
    wire                  axi_wready;

    wire [1:0]            axi_bresp;
    wire                  axi_bvalid;
    wire                  axi_bready;

    wire [ADDR_WIDTH-1:0] axi_araddr;
    wire [2:0]            axi_arprot;
    wire                  axi_arvalid;
    wire                  axi_arready;

    wire [DATA_WIDTH-1:0] axi_rdata;
    wire [1:0]            axi_rresp;
    wire                  axi_rvalid;
    wire                  axi_rready;

    // Master instantiation
    axi4lite_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) master (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        .start_write(start_write),
        .start_read(start_read),
        .addr(addr),
        .write_data(write_data),
        .write_strb(write_strb),
        .read_data(read_data),
        .write_done(write_done),
        .read_done(read_done),
        .write_resp(write_resp),
        .read_resp(read_resp),
        .M_AXI_AWADDR(axi_awaddr),
        .M_AXI_AWPROT(axi_awprot),
        .M_AXI_AWVALID(axi_awvalid),
        .M_AXI_AWREADY(axi_awready),
        .M_AXI_WDATA(axi_wdata),
        .M_AXI_WSTRB(axi_wstrb),
        .M_AXI_WVALID(axi_wvalid),
        .M_AXI_WREADY(axi_wready),
        .M_AXI_BRESP(axi_bresp),
        .M_AXI_BVALID(axi_bvalid),
        .M_AXI_BREADY(axi_bready),
        .M_AXI_ARADDR(axi_araddr),
        .M_AXI_ARPROT(axi_arprot),
        .M_AXI_ARVALID(axi_arvalid),
        .M_AXI_ARREADY(axi_arready),
        .M_AXI_RDATA(axi_rdata),
        .M_AXI_RRESP(axi_rresp),
        .M_AXI_RVALID(axi_rvalid),
        .M_AXI_RREADY(axi_rready)
    );

    // Slave instantiation
    axi4lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS(16)
    ) slave (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        .S_AXI_AWADDR(axi_awaddr),
        .S_AXI_AWPROT(axi_awprot),
        .S_AXI_AWVALID(axi_awvalid),
        .S_AXI_AWREADY(axi_awready),
        .S_AXI_WDATA(axi_wdata),
        .S_AXI_WSTRB(axi_wstrb),
        .S_AXI_WVALID(axi_wvalid),
        .S_AXI_WREADY(axi_wready),
        .S_AXI_BRESP(axi_bresp),
        .S_AXI_BVALID(axi_bvalid),
        .S_AXI_BREADY(axi_bready),
        .S_AXI_ARADDR(axi_araddr),
        .S_AXI_ARPROT(axi_arprot),
        .S_AXI_ARVALID(axi_arvalid),
        .S_AXI_ARREADY(axi_arready),
        .S_AXI_RDATA(axi_rdata),
        .S_AXI_RRESP(axi_rresp),
        .S_AXI_RVALID(axi_rvalid),
        .S_AXI_RREADY(axi_rready)
    );

endmodule