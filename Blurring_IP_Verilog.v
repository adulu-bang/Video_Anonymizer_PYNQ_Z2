module sun_final_try1_resize(

    input wire aclk,
    input wire aresetn,

    input wire [31:0] s_axis_tdata, // input pixel data
    input wire s_axis_tvalid,
    output reg s_axis_tready,

    output reg [31:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready
);

////////////////////skin identify/////////////////////////////

wire [7:0] r_raw, g_raw, b_raw;
assign r_raw = s_axis_tdata[31:24];
assign g_raw = s_axis_tdata[23:16];
assign b_raw = s_axis_tdata[15:8];

wire [15:0] r_plus_g_plus_b;
assign r_plus_g_plus_b = r_raw + g_raw + b_raw;

wire [7:0] r_norm, g_norm, b_norm;
assign r_norm = (r_plus_g_plus_b > 0) ? ((r_raw * 100) / r_plus_g_plus_b) : 8'd0;
assign g_norm = (r_plus_g_plus_b > 0) ? ((g_raw * 100) / r_plus_g_plus_b) : 8'd0;
assign b_norm = (r_plus_g_plus_b > 0) ? ((b_raw * 100) / r_plus_g_plus_b) : 8'd0;

wire is_skin;
assign is_skin = (r_norm >= 35 && r_norm <= 45) &&
                 (g_norm >= 28 && g_norm <= 36) &&
                 (b_norm >= 23 && b_norm <= 31);

////////////////////blurring window///////////////////////////

reg [12:0] skin_window;                 // 13-bit window
reg [3:0] window_count;                // Enough to count up to 13
reg [23:0] pixel_buffer [5:0];         // 6-pixel buffer
reg [2:0] valid_pixel_count;           // Enough to count up to 6

integer i;
reg [19:0] sum_r, sum_g, sum_b;        // Enough for 8-bit * 6
reg [7:0] r_avg, g_avg, b_avg;
reg [23:0] avg_pixel;
integer j;
//reg proc;

///////////////////blurring average calc/////////////////////

always @(*) begin
    sum_r = 0;
    sum_g = 0;
    sum_b = 0;

    for (j = 0; j < 6; j = j + 1) begin
        sum_r = sum_r + pixel_buffer[j][23:16];
        sum_g = sum_g + pixel_buffer[j][15:8];
        sum_b = sum_b + pixel_buffer[j][7:0];
    end

    r_avg = sum_r / 6;
    g_avg = sum_g / 6;
    b_avg = sum_b / 6;
    avg_pixel = {r_avg, g_avg, b_avg};
end

///////////////////main processing block/////////////////////

always @(posedge aclk or negedge aresetn) begin
    if (~aresetn) begin
        m_axis_tdata <= 32'h0;
        m_axis_tvalid <= 1'b0;
        window_count <= 0;
        skin_window <= 0;
        valid_pixel_count <= 0;
        s_axis_tready <= 1;
        //proc <= 0;

        for (i = 0; i < 6; i = i + 1) begin
            pixel_buffer[i] <= 24'h0;
        end
    end else begin
        s_axis_tready <= m_axis_tready;

        if (s_axis_tvalid && s_axis_tready) begin
            skin_window <= {skin_window[11:0], is_skin};
            window_count <= window_count + is_skin - skin_window[12];

            for (i = 5; i > 0; i = i - 1) begin
                pixel_buffer[i] <= pixel_buffer[i - 1];
            end
            pixel_buffer[0] <= s_axis_tdata[31:8];
           // proc <= 1;
        end

        if (valid_pixel_count < 6) begin
            valid_pixel_count <= valid_pixel_count + 1;
        end

        m_axis_tvalid <= (valid_pixel_count >= 5);

        if ( m_axis_tvalid && m_axis_tready) begin
            if (window_count > 3) begin // more than half (7/2)
                m_axis_tdata <= {8'b0, avg_pixel};
            end else begin
                m_axis_tdata <= {8'b0, pixel_buffer[5]};
            end
           // proc <= 0;
        end
    end
end

