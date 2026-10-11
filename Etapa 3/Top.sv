module etapa3_top #(
    parameter integer WIDTH   = 4,
    parameter integer Y_WIDTH = 2*WIDTH + 2,
    parameter integer CLK_HZ  = 27_000_000,
    parameter integer OUT_HZ  = 1
)(
    input  wire clk,
    input  wire rst_n,                     // botón, activo bajo
    input  wire signed [WIDTH-1:0] data_in, // switches/buttons
    input  wire signed [Y_WIDTH-1:0] y_in,  // desde Etapa 2
    input  wire event_in,                   // desde Etapa 2
    output wire [5:0] led                   // LEDs Tang Nano, activo bajo
);

    wire en;
    wire signed [WIDTH-1:0] x0, x1, x2, x3;
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

    output_sync #(
        .WIDTH(Y_WIDTH)
    ) u_sync (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .y_in(y_in),
        .event_in(event_in),
        .y_out(y_sync),
        .event_out(event_sync)
    );

    // LEDs activo bajo en Tang Nano.
    assign led[0] = ~event_sync;
    assign led[5:1] = ~y_sync[4:0];  // muestra bits bajos de y_sync

endmodule