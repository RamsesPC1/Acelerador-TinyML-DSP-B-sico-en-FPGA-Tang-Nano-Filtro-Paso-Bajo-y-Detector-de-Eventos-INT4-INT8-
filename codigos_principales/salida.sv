module output_sync #(
    parameter integer WIDTH = 10
)(
    input  wire clk,
    input  wire rst_n,       // reset asíncrono, activo bajo
    input  wire en,          // habilitación visible, por ejemplo 1 Hz
    input  wire signed [WIDTH-1:0] y_in,
    input  wire event_in,
    output reg  signed [WIDTH-1:0] y_out,
    output reg  event_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= {WIDTH{1'b0}};
            event_out <= 1'b0;
        end else if (en) begin
            y_out <= y_in;
            event_out <= event_in;
        end
    end

endmodule