`timescale 1ns / 1ns

`ifndef IWIDTH
`error "`IWIDTH not defined"
`endif

`ifndef OWIDTH
`error "`OWIDTH not defined"
`endif

`ifndef DUMPFILE
`error "`DUMPFILE not defined"
`endif

module Harness(
    input clk,
    input rst
);

    localparam IW = `IWIDTH;
    localparam OW = `OWIDTH;

    reg [IW-1:0] idata;
    wire [OW-1:0] odata;
    wire ivalid, iready, ovalid, oready;
    reg adapter_rst, flush;

    WidthAdapter #(.IW(IW), .OW(OW)) u_adapter(
        .clk(clk),
        .rst(adapter_rst),
        .idata(idata),
        .ivalid(ivalid),
        .iready(iready),
        .odata(odata),
        .ovalid(ovalid),
        .oready(oready),
        .flush(flush)
    );

    integer i;
    always @(posedge clk) for (i=0; i<IW; i=i+1) idata[i] <= {$random}[0];

    reg ivalid_mask, oready_mask;

    always @(posedge clk) begin
        if (adapter_rst) ivalid_mask <= 1'b0;
        else ivalid_mask <= {$random}[0];
    end

    always @(posedge clk) begin
        if (adapter_rst) oready_mask <= 1'b0;
        else oready_mask <= {$random}[0];
    end

    assign ivalid = ivalid_mask && !flush;
    assign oready = oready_mask;

    initial begin
        if ($test$plusargs("trace") != 0) begin
            $dumpfile(`DUMPFILE);
            $dumpvars();
        end
    end

    reg [IW*OW-1:0] idatarec, odatarec;
    integer icnt, ocnt, icnt_max, ocnt_max, totalcnt;
    reg finished;

    always @(posedge clk) begin
        if (rst) begin
            adapter_rst <= 1;
            finished <= 0;
            totalcnt = 0;
        end
        else if (finished) $finish;
        else if (adapter_rst) begin
            adapter_rst <= 0;
            flush <= 0;
            idatarec = 0;
            odatarec = 0;
            icnt = 0;
            ocnt = 0;
            icnt_max = $unsigned($random) % OW + 1;
            ocnt_max = (icnt_max * IW + OW - 1) / OW;
            totalcnt = totalcnt + 1;
            if (totalcnt > 100) finished <= 1;
        end
        else begin
            if (ivalid && iready) begin
                idatarec[(OW-1-icnt)*IW +: IW] = idata;
                icnt = icnt + 1;
            end
            if (ovalid && oready) begin
                odatarec[(IW-1-ocnt)*OW +: OW] = odata;
                ocnt = ocnt + 1;
            end
            if (icnt == icnt_max) flush <= 1;
            if (ocnt == ocnt_max) begin
                if (icnt != icnt_max) begin
                    $display("[%dns] ERROR: input/output count mismatch", $time);
                    finished <= 1;
                end
                else if (idatarec != odatarec) begin
                    $display("[%dns] ERROR: input/output data mismatch", $time);
                    finished <= 1;
                end
                else begin
                    adapter_rst <= 1;
                end
            end
        end
    end

endmodule
