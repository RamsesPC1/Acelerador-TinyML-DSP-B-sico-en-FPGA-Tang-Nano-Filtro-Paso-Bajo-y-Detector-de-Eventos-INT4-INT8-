module shift_register_4 #(
    parameter integer WIDTH = 4
)(
    input  wire clk,
    input  wire rst_n,       // reset asíncrono, activo bajo
    input  wire en,          // habilitación de desplazamiento
    input  wire signed [WIDTH-1:0] data_in,
    output reg  signed [WIDTH-1:0] x0,  // muestra más reciente
    output reg  signed [WIDTH-1:0] x1,  // x[n-1]
    output reg  signed [WIDTH-1:0] x2,  // x[n-2]
    output reg  signed [WIDTH-1:0] x3   // x[n-3]
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0 <= {WIDTH{1'b0}};
            x1 <= {WIDTH{1'b0}};
            x2 <= {WIDTH{1'b0}};
            x3 <= {WIDTH{1'b0}};
        end else if (en) begin
            x3 <= x2;
            x2 <= x1;
            x1 <= x0;
            x0 <= data_in;
        end
    end

endmodule