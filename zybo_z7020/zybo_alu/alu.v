`timescale 1ns / 1ps

module alu(
    input [7:0] a,
    input [7:0] b,
    input enable,
    input [2:0] opcode,
    output reg [15:0] result

);

    always @(*) begin
        if (enable) begin
            case(opcode)
              3'b000: begin
                result <= a + b; //add   
              end
              3'b001: begin
                result <= a - b; //sub
              end
              3'b010: begin
                result <= a * b; //mul
              end
              3'b011: begin
                result <= (b != 0) ? a / b : 16'hffff; //div
              end
              3'b100: begin
                result <= a & b; // and
              end
              3'b101: begin
                result <= a | b; // or
              end
              3'b110: begin
                result <= a ^ b; // xor
              end
              3'b111: begin
                result <= ~a; // not a
              end

                           
              default: begin
                result <= 16'h0000;
              end
            endcase
            
        end else begin
            result <= 16'h0000;
        end
    end

    
endmodule
