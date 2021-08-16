`timescale 1ns / 1ns

module Harness(
    input clk,
    input rst
);

    localparam IW = 64;
    localparam OW = 32;

    reg [IW-1:0] idata;
    wire [OW-1:0] odata;
    wire ivalid, iready, ovalid, oready;

    WidthAdapter #(.IW(IW), .OW(OW)) u_adapter(
        .clk(clk),
        .rst(rst),
        .idata(idata),
        .ivalid(ivalid),
        .iready(iready),
        .odata(odata),
        .ovalid(ovalid),
        .oready(oready)
    );

    always @(posedge clk) idata <= {$random, $random};

    reg ivalid_mask, oready_mask;
    reg stop_input;

    always @(posedge clk) begin
        if (rst) ivalid_mask <= 1'b0;
        else ivalid_mask <= {$random}[0];
    end

    always @(posedge clk) begin
        if (rst) oready_mask <= 1'b0;
        else oready_mask <= {$random}[0];
    end

    assign ivalid = ivalid_mask && !stop_input;
    assign oready = oready_mask;

    initial begin
        if ($test$plusargs("trace") != 0) begin
            $dumpfile("logs/dump.vcd");
            $dumpvars();
        end
    end

    reg [IW*OW-1:0] idatarec, odatarec;
    integer icnt, ocnt, totalcnt;

    always @(posedge clk) begin
        if (rst) begin
            icnt = 0;
            ocnt = 0;
            idatarec = 0;
            odatarec = 0;
            totalcnt = 0;
            stop_input = 0;
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
            if (icnt == OW) stop_input = 1;
            if (ocnt == IW) begin
                if (icnt != OW) begin
                    $display("[%dns] ERROR: input/output count mismatch", $time);
                    $finish;
                end
                else if (idatarec != odatarec) begin
                    $display("[%dns] ERROR: input/output data mismatch", $time);
                    $finish;
                end
                else begin
                    icnt = 0;
                    ocnt = 0;
                    idatarec = 0;
                    odatarec = 0;
                    totalcnt = totalcnt + 1;
                    stop_input = 0;
                    if (totalcnt >= 100) begin
                        $finish;
                    end
                end
            end
        end
    end

endmodule
