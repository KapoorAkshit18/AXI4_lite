module axi4lite_master #
(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire                     ACLK,
    input  wire                     ARESETN,

    // Control signals
    input  wire                     start,
    input  wire [ADDR_WIDTH-1:0]    write_addr,
    input  wire [DATA_WIDTH-1:0]    write_data,
    input  wire [ADDR_WIDTH-1:0]    read_addr,

    output reg                      done,
    output reg [DATA_WIDTH-1:0]     read_data_out,

    // AXI Write Address Channel
    output reg [ADDR_WIDTH-1:0]     M_AXI_AWADDR,
    output reg                      M_AXI_AWVALID,
    input  wire                     M_AXI_AWREADY,

    // AXI Write Data Channel
    output reg [DATA_WIDTH-1:0]     M_AXI_WDATA,
    output reg [(DATA_WIDTH/8)-1:0] M_AXI_WSTRB,
    output reg                      M_AXI_WVALID,
    input  wire                     M_AXI_WREADY,

    // Write Response Channel
    input  wire [1:0]               M_AXI_BRESP,
    input  wire                     M_AXI_BVALID,
    output reg                      M_AXI_BREADY,

    // AXI Read Address Channel
    output reg [ADDR_WIDTH-1:0]     M_AXI_ARADDR,
    output reg                      M_AXI_ARVALID,
    input  wire                     M_AXI_ARREADY,

    // AXI Read Data Channel
    input  wire [DATA_WIDTH-1:0]    M_AXI_RDATA,
    input  wire [1:0]               M_AXI_RRESP,
    input  wire                     M_AXI_RVALID,
    output reg                      M_AXI_RREADY
);

    // FSM States
    localparam IDLE        = 0,
               WRITE_ADDR  = 1,
               WRITE_DATA  = 2,
               WRITE_RESP  = 3,
               READ_ADDR   = 4,
               READ_DATA   = 5,
               DONE        = 6;

    reg [2:0] state;

    always @(posedge ACLK) begin
        if (!ARESETN) begin
            state <= IDLE;

            M_AXI_AWVALID <= 0;
            M_AXI_WVALID  <= 0;
            M_AXI_BREADY  <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY  <= 0;

            done <= 0;
        end else begin
            case (state)

                IDLE: begin
                    done <= 0;
                    if (start) begin
                        // setup write
                        M_AXI_AWADDR  <= write_addr;
                        M_AXI_WDATA   <= write_data;
                        M_AXI_WSTRB   <= 4'b1111;

                        M_AXI_AWVALID <= 1;
                        state <= WRITE_ADDR;
                    end
                end

                WRITE_ADDR: begin
                    if (M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 0;
                        M_AXI_WVALID  <= 1;
                        state <= WRITE_DATA;
                    end
                end

                WRITE_DATA: begin
                    if (M_AXI_WREADY) begin
                        M_AXI_WVALID <= 0;
                        M_AXI_BREADY <= 1;
                        state <= WRITE_RESP;
                    end
                end

                WRITE_RESP: begin
                    if (M_AXI_BVALID) begin
                        M_AXI_BREADY <= 0;

                        // setup read
                        M_AXI_ARADDR  <= read_addr;
                        M_AXI_ARVALID <= 1;

                        state <= READ_ADDR;
                    end
                end

                READ_ADDR: begin
                    if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 0;
                        M_AXI_RREADY  <= 1;
                        state <= READ_DATA;
                    end
                end

                READ_DATA: begin
                    if (M_AXI_RVALID) begin
                        read_data_out <= M_AXI_RDATA;
                        M_AXI_RREADY  <= 0;
                        state <= DONE;
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule