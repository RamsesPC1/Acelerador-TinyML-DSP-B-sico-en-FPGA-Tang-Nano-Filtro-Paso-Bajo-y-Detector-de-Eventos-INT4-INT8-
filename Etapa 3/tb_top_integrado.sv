`timescale 1ns/1ps

module tb_top_integrado;

    localparam integer CLK_PERIOD = 10; // Periodo de 10 ns (100 MHz virtual)

    reg clk = 0;
    reg rst_n = 0;
    wire [5:0] led;

    // Instancia del Top autonomo con parametros acelerados para simulacion
    top_integrado #(
        .WIDTH(4),
        .Y_WIDTH(10),
        .N_MUESTRAS(100),
        .CLK_HZ(100),
        .OUT_HZ(10)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .led(led)
    );

    // Generador de reloj continuo
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        // Generacion de archivo de ondas para VS Code
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_top_integrado);

        $display("Inicio de testbench: Procesando input_signal.mem");

        // Secuencia de reset activo en bajo
        rst_n = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;

        // Espera a que el circuito recorra de forma autonoma las 100 muestras
        // Cada muestra toma 10 ciclos de reloj (100 Hz / 10 Hz = 10)
        // 100 muestras * 10 ciclos = 1000 ciclos de reloj
        repeat (1050) @(posedge clk);

        $display("Fin de testbench: 100 muestras completadas con exito");
        $finish;
    end

    // Notificacion en consola cada vez que el LED de alerta se enciende (activo en bajo)
    always @(negedge led[0]) begin
        if (rst_n) begin
            $display("[ALERTA DETECTADA] Tiempo = %0t ns | Muestra #%0d | Salida Y = %0d", 
                     $time, dut.addr, dut.y_sync);
        end
    end

endmodule