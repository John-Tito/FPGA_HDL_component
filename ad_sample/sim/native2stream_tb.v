module native2stream_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;
    // Ports
    reg        clk = 0;
    reg        rstn = 0;
    reg  [8:0] fifo_data = 0;
    reg        fifo_empty = 0;
    wire       fifo_rd;
    reg        m_axis_tready = 0;
    wire       m_axis_tvalid;
    wire [7:0] m_axis_tdata;

    native2stream native2stream_inst (
        .clk          (clk),
        .rstn         (rstn),
        .fifo_data    (fifo_data),
        .fifo_empty   (fifo_empty),
        .fifo_rd      (fifo_rd),
        .m_axis_tready(m_axis_tready),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata (m_axis_tdata)
    );

    reg [7:0] rd_cnt;
    reg [7:0] wr_cnt;
    always @(posedge clk) begin
        if (!rstn) begin
            fifo_data <= 0;
        end else begin
            if (fifo_rd) begin
                if (rd_cnt > 0) begin
                    fifo_data <= fifo_data + 1;
                end
            end
        end
    end
    always @(posedge clk) begin
        if (!rstn) begin
            rd_cnt <= 5;
        end else begin
            if (fifo_rd) begin
                if (rd_cnt > 0) begin
                    rd_cnt <= rd_cnt - 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            fifo_empty <= 1'b1;
        end else begin
            if ((rd_cnt == 0) || ((rd_cnt == 1) && fifo_rd)) begin
                fifo_empty <= 1'b1;
            end else begin
                fifo_empty <= 1'b0;
            end
        end
    end

    wire data_read_out;
    assign data_read_out = m_axis_tvalid & m_axis_tready;
    always @(posedge clk) begin
        if (!rstn) begin
            wr_cnt <= 0;
        end else begin
            if (data_read_out) begin
                if (wr_cnt < 10) begin
                    wr_cnt <= wr_cnt + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tready <= 1'b0;
        end else begin
            if ((wr_cnt >= 8) || ((wr_cnt >= 7) && data_read_out)) begin
                m_axis_tready <= 1'b0;
            end else begin
                m_axis_tready <= 1'b1;
            end
        end
    end

    initial begin
        begin
            #40000;
            $finish;
        end
    end

    // ***********************************************************************************
    // clock block
    always #(TIMEPERIOD / 2) clk = !clk;

    // reset block
    initial begin
        begin
            rstn = 1'b0;
            #(TIMEPERIOD * 20);
            rstn = 1'b1;
        end
    end

    // record block
    initial begin
        begin
            $dumpfile("sim/test_tb.lxt");
            $dumpvars(0, native2stream_tb);
        end
    end
endmodule
