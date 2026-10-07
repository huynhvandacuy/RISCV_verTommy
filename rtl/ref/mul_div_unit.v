// tong cycle de thuc hien phep chia la 35 cycle
// IDLE: 1 cycle de setup, start = 1
// COMPUTE: 32 cycle de xu ly theo thuat toan
// DONE: 2 cycle, in ket qua 
module mul_div_unit (
    input         clk,
    input         rst_n,
    input         start,
    input  [31:0] src_a,
    input  [31:0] src_b,
    input  [ 2:0] funct3,
    output reg [31:0] result,
    output        busy,
    output reg    done
);
    localparam MUL    = 3'b000;
    localparam MULH   = 3'b001;
    localparam MULHSU = 3'b010;
    localparam MULHU  = 3'b011;
    localparam DIV    = 3'b100;
    localparam DIVU   = 3'b101;
    localparam REM    = 3'b110;
    localparam REMU   = 3'b111;

    localparam S_IDLE = 3'b000;
    localparam S_MUL  = 3'b001;
    localparam S_DIV  = 3'b010;

    reg [ 2:0] state;
    reg [31:0] quotient, remainder, divisor;
    reg [ 5:0] count;
    reg [63:0] mul_result;
    reg        src_a_neg, src_b_neg;

    wire is_mul = (funct3 == MUL) || (funct3 == MULH) || (funct3 == MULHSU) || (funct3 == MULHU);

    assign busy = (state != S_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state      <= S_IDLE;
            result     <= 32'b0;
            done       <= 1'b0;
            count      <= 6'b0;
            quotient   <= 32'b0;
            remainder  <= 32'b0;
            divisor    <= 32'b0;
            mul_result <= 64'b0;
            src_a_neg  <= 1'b0;
            src_b_neg  <= 1'b0;
        end else begin
            done <= 1'b0;

            case(state)
                S_IDLE: begin
                    if(start) begin
                        if(is_mul) begin
                            state <= S_MUL;
                            count <= 6'd0;
                            if(funct3 == MULHSU)
                                mul_result <= $signed({src_a[31], src_a}) * $signed({1'b0, src_b});
                            else if(funct3 == MULH)
                                mul_result <= $signed(src_a) * $signed(src_b);
                            else
                                mul_result <= src_a * src_b;
                        end else begin
                            state <= S_DIV;
                            count <= 6'd0;
                            src_a_neg <= (funct3 == DIV || funct3 == REM) && src_a[31];
                            src_b_neg <= (funct3 == DIV || funct3 == REM) && src_b[31];
                            if(funct3 == DIV || funct3 == REM) begin
                                quotient  <= src_a[31] ? -src_a : src_a;
                                divisor   <= src_b[31] ? -src_b : src_b;
                            end else begin
                                quotient  <= src_a;
                                divisor   <= src_b;
                            end
                            remainder <= 32'b0;
                        end
                    end
                end

                S_MUL: begin
                    if(count == 6'd1) begin
                        state <= S_IDLE;
                        done  <= 1'b1;
                        case(funct3)
                            MUL:    result <= mul_result[31:0];
                            MULH:   result <= mul_result[63:32];
                            MULHSU: result <= mul_result[63:32];
                            MULHU:  result <= mul_result[63:32];
                            default: result <= 32'b0;
                        endcase
                    end else
                        count <= count + 1;
                end

                S_DIV: begin
                    if(count == 6'd32) begin
                        state <= S_IDLE;
                        done  <= 1'b1;
                        case(funct3)
                            DIV: begin
                                if(src_b == 0)
                                    result <= 32'hFFFFFFFF;
                                else if(src_a == 32'h80000000 && src_b == 32'hFFFFFFFF)
                                    result <= 32'h80000000;
                                else
                                    result <= (src_a_neg != src_b_neg) ? -quotient : quotient;
                            end
                            DIVU: begin
                                if(src_b == 0)
                                    result <= 32'hFFFFFFFF;
                                else
                                    result <= quotient;
                            end
                            REM: begin
                                if(src_b == 0)
                                    result <= src_a;
                                else if(src_a == 32'h80000000 && src_b == 32'hFFFFFFFF)
                                    result <= 32'h0;
                                else
                                    result <= src_a_neg ? -remainder : remainder;
                            end
                            REMU: begin
                                if(src_b == 0)
                                    result <= src_a;
                                else
                                    result <= remainder;
                            end
                            default: result <= 32'b0;
                        endcase
                    end else begin
                        remainder <= {remainder[30:0], quotient[31]};
                        quotient  <= {quotient[30:0], 1'b0};
                        if({remainder[30:0], quotient[31]} >= divisor) begin
                            remainder <= {remainder[30:0], quotient[31]} - divisor;
                            quotient[0] <= 1'b1;
                        end
                        count <= count + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
