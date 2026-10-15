module top_integrado #(
    parameter integer WIDTH   = 4,
    parameter integer Y_WIDTH = 10,
    parameter integer CLK_HZ  = 100,
    parameter integer OUT_HZ  = 10
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [WIDTH-1:0] data_in,
    output wire [5:0] led
);

    wire en;
    wire signed [WIDTH-1:0] x0, x1, x2, x3;
    wire signed [Y_WIDTH-1:0] y_stage2;
    wire event_stage2;
    wire signed [Y_WIDTH-1:0] y_sync;
    wire event_sync;

    clock_divider #(
        .CLK_HZ(CLK_HZ),
        .OUT_HZ(OUT_HZ)
    ) u_div (
        .clk(clk),
        .rst_n(rst_n),
        .pulse(en)
    );

    shift_register_4 #(
        .WIDTH(WIDTH)
    ) u_sr (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(data_in),
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .x3(x3)
    );

    etapa2_tinyml u_etapa2 (
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .x3(x3),
        .y(y_stage2),
        .alerta(event_stage2)
    );

    output_sync #(
        .WIDTH(Y_WIDTH)
    ) u_sync (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .y_in(y_stage2),
        .event_in(event_stage2),
        .y_out(y_sync),
        .event_out(event_sync)
    );

    // Salida LED: bit 0 indica alerta; bits 1..5 muestran parte del valor y
    assign led[0] = ~event_sync;
    assign led[5:1] = ~y_sync[4:0];

endmodule
