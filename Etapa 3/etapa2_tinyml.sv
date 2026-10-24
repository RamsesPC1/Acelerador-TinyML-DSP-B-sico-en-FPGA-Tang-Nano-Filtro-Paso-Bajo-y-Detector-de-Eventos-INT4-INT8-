module etapa2_tinyml (
    input  wire signed [3:0] x0,
    input  wire signed [3:0] x1,
    input  wire signed [3:0] x2,
    input  wire signed [3:0] x3,

    output wire signed [9:0] y,
    output wire alerta
);

    // Coeficientes del filtro paso bajo
    `include "weights.vh"

    //Umbral de detección 
    localparam signed [9:0] UMBRAL = 10'sd32;

    wire signed [7:0] p0;
    wire signed [7:0] p1;
    wire signed [7:0] p2;
    wire signed [7:0] p3;

    wire signed [8:0] suma0;
    wire signed [8:0] suma1;

    // Núcleo MAC
    assign p0 = x0 * W0;
    assign p1 = x1 * W1;
    assign p2 = x2 * W2;
    assign p3 = x3 * W3;

    // Árbol balanceado de nivel 1
    assign suma0 = p0 + p1;
    assign suma1 = p2 + p3;

    // Árbol balanceado de nivel 2
    assign y = suma0 + suma1;

    
    assign alerta = (y > UMBRAL);

endmodule
