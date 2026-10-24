module top_integrado #(
    parameter integer WIDTH       = 4,           // INT4 (con signo)
    parameter integer Y_WIDTH     = 10,          // Salida de 10 bits del acelerador
    parameter integer N_MUESTRAS  = 100,         // Tus 100 muestras de Python
    parameter integer CLK_HZ      = 27_000_000,  // Reloj de la Tang Nano (27 MHz)
    parameter integer OUT_HZ      = 2            // Tasa visible (2 muestras por segundo)
)(
    input  wire clk,
    input  wire rst_n,
    output wire [5:0] led
);

    
    // Memoria ROM interna para tu señal (Etapa 1 en hardware)
    
    reg signed [WIDTH-1:0] rom_signal [0:N_MUESTRAS-1];
    reg [6:0] addr; // 7 bits alcanzan de 0 a 127 (cubre las 100 muestras)

    initial begin
        // Carga tus muestras cuantizadas directamente en la FPGA
        $readmemh("input_signal.mem", rom_signal);
    end

    
    // Cables internos de interconexión
    
    wire en;
    wire signed [WIDTH-1:0] data_in;
    wire signed [WIDTH-1:0] x0, x1, x2, x3;
    wire signed [Y_WIDTH-1:0] y_stage2;
    wire event_stage2;
    wire signed [Y_WIDTH-1:0] y_sync;
    wire event_sync;

    
    // Divisor de frecuencia
   
    clock_divider #(
        .CLK_HZ(CLK_HZ),
        .OUT_HZ(OUT_HZ)
    ) u_div (
        .clk(clk),
        .rst_n(rst_n),
        .pulse(en)
    );

    
    // Puntero / Contador que recorre tus 100 muestras en bucle
   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= 7'd0;
        end else if (en) begin
            if (addr == N_MUESTRAS - 1)
                addr <= 7'd0; // Reinicia el ciclo continuo de la señal
            else
                addr <= addr + 1'b1;
        end
    end

    // El dato actual de la ROM se envía al registro de desplazamiento
    assign data_in = rom_signal[addr];

    
    // Registro de desplazamiento (Ventana deslizante de 4 muestras)
    
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

    
    // Etapa 2: Acelerador TinyML (MAC + Árbol sumador + Umbral)
   
    etapa2_tinyml u_etapa2 (
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .x3(x3),
        .y(y_stage2),
        .alerta(event_stage2)
    );

    
    // Sincronización de Salida
   
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

    
    // Salida hacia los LEDs de la Tang Nano (Activos en bajo)
   
    assign led[0]   = ~event_sync;   // LED 0 enciende si hay ALERTA
    assign led[5:1] = ~y_sync[4:0];  // LEDs 1 al 5 muestran el valor filtrado

endmodule