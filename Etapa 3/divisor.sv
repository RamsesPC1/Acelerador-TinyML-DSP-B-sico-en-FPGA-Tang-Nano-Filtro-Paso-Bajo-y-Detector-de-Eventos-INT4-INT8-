module clock_divider #(
    parameter integer CLK_HZ = 27_000_000,
    parameter integer OUT_HZ = 1
)(
    input  wire clk,
    input  wire rst_n,       // reset asíncrono, activo bajo
    output reg  pulse        // un pulso de 1 ciclo de clk
);

    localparam integer COUNT_MAX = CLK_HZ / OUT_HZ;
    reg [31:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            pulse <= 1'b0;
        end else begin
            if (count >= COUNT_MAX - 1) begin
                count <= 32'd0;
                pulse <= 1'b1;
            end else begin
                count <= count + 1'b1;
                pulse <= 1'b0;
            end
        end
    end

endmodule