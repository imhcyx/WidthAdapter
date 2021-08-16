`timescale 1ns / 1ns

module WidthAdapter
#(
    parameter IW = 64,
    parameter OW = 32
)
(
    input               clk,
    input               rst,
    input  [IW - 1 : 0] idata,
    input               ivalid,
    output              iready,
    output [OW - 1 : 0] odata,
    output              ovalid,
    input               oready
);

    generate
        if (IW == OW) begin
            // trivial case
            assign iready = oready;
            assign ovalid = ivalid;
            assign odata = idata;
        end
        else begin
            localparam BUFLEN = IW + OW;
            localparam MAX_WIDTH = IW > OW ? IW : OW;
            localparam CNTLEN = $clog2(MAX_WIDTH+1);

            // buffer for storing data
            reg [BUFLEN-1:0] buffer;

            // input/output pointers
            reg [CNTLEN-1:0] iptr;
            reg [CNTLEN-1:0] optr;

            assign iready = iptr == IW;
            assign ovalid = optr == OW;
            assign odata = buffer[BUFLEN-1:IW];

            // indication for handshake
            wire ifire = ivalid && iready;
            wire ofire = ovalid && oready;

            // shift operand
            wire [BUFLEN-1:0] shift_in = ifire ? {odata, idata} : buffer;

            // available shift amoount for iptr and optr respectively
            wire [CNTLEN-1:0] iavail = ifire ? IW : IW - iptr;
            wire [CNTLEN-1:0] oavail = ofire ? OW : OW - optr;

            // the final shift amount
            wire [CNTLEN-1:0] sa = iavail < oavail ? iavail : oavail;

            always @(posedge clk) begin
                if (rst) iptr <= IW;
                else iptr <= (ifire ? 0 : iptr) + sa;
            end

            always @(posedge clk) begin
                if (rst) optr <= 0;
                else optr <= (ofire ? 0 : optr) + sa;
            end

            always @(posedge clk) buffer <= shift_in << sa;
        end
    endgenerate

endmodule
