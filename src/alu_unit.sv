module alu(
    input signed [31:0] A,
    input signed [31:0] B,
    input [3:0] aluctl,
    output reg [31:0] C
    // output reg ready
    );


    always @(*) begin
        case (aluctl)

            0:  C = A + B;
            1:  C = A - B;
            2:  C = A * B;
            3:  C = A / B;
            4:  C = A ^ B;
            5:  C = A & B;
            6:  C = A | B;
            7:  C = ~(A | B);
            8:  C = A >> B;
            9:  C = A << B;
            10: C = A >>> B;
            11: C = A <<< B;  
            12: C = (A == B)? 32'd1 : 32'd0;
            // 14: C = (A < B);
            // 15: C = (A > B);
            default: C = 32'bx;

        endcase
    end
     
endmodule
