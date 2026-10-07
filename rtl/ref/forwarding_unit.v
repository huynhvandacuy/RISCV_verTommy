module forwarding_unit (
    input      [4:0] EX_rs1,
    input      [4:0] EX_rs2,
    input      [4:0] MEM_rd,
    input      [4:0] WB_rd,
    input            MEM_regWrite,
    input            WB_regWrite,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);
    always @(*) begin
        ForwardA = 2'b00;
        ForwardB = 2'b00;

        // MEM -> EX forwarding (priority cao hơn)
        if(MEM_regWrite && (MEM_rd != 5'd0) && (MEM_rd == EX_rs1)) begin
            ForwardA = 2'b10;
        end else if(WB_regWrite && (WB_rd != 5'd0) && (WB_rd == EX_rs1)) begin
            ForwardA = 2'b01;
        end

        if (MEM_regWrite && (MEM_rd != 5'd0) && (MEM_rd == EX_rs2)) begin
            ForwardB = 2'b10;
        end else if (WB_regWrite && (WB_rd != 5'd0) && (WB_rd == EX_rs2)) begin
            ForwardB = 2'b01;
        end
    end
endmodule
