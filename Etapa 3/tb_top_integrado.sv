`timescale 1ns/1ps

module tb_top_integrado;

    localparam integer CLK_PERIOD = 10; // 100 MHz

    reg clk = 0;
    reg rst_n = 0;
    reg signed [3:0] data_in = 0;

    wire [5:0] led;

    top_integrado #(
        .WIDTH(4),
        .Y_WIDTH(10),
        .CLK_HZ(100),
        .OUT_HZ(10)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .led(led)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    integer i;

    initial begin
        $display("Inicio de testbench");

        // reset activo bajo
        rst_n = 0;
        data_in = 4'sd0;
        repeat (3) @(posedge clk);
        rst_n = 1;

        // Secuencia simple de prueba
        for (i = 0; i < 20; i = i + 1) begin
            data_in = $signed((i % 9) - 4); // valores entre -4 y 4
            repeat (5) @(posedge clk);
        end

        $display("Fin de testbench");
        $finish;
    end

endmodule
