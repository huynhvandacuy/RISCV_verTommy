// tong cycle de thuc hien phep chia la 35 cycle
// IDLE: 1 cycle de setup, start = 1
// COMPUTE: 32 cycle de xu ly theo thuat toan
// DONE: 2 cycle, in ket qua 
module mul_div_unit(
    input         clk_i,
    input         rst_ni,
    input         start_i,
    input  [31:0] src_a_i,
    input  [31:0] src_b_i,
    input  [ 2:0] funct3_i,
    output reg [31:0] result_o,
    output        busy_o,
    output reg    done_o
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

    reg [ 2:0] state_q;
    reg [31:0] quotient_q, remainder_q, divisor_q;
    reg [ 5:0] cycle_count_q;
    reg [63:0] product_q;
    reg        src_a_neg_q, src_b_neg_q;

    wire is_mul = (funct3_i == MUL) || (funct3_i == MULH) || (funct3_i == MULHSU) || (funct3_i == MULHU);

    assign busy_o = (state_q != S_IDLE);

    always @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            state_q      <= S_IDLE;
            result_o     <= 32'b0;
            done_o       <= 1'b0;
            cycle_count_q      <= 6'b0;
            quotient_q   <= 32'b0;
            remainder_q  <= 32'b0;
            divisor_q    <= 32'b0;
            product_q <= 64'b0;
            src_a_neg_q  <= 1'b0;
            src_b_neg_q  <= 1'b0;
        end else begin
            done_o <= 1'b0;

            case(state_q)
                S_IDLE: begin
                    if(start_i) begin
                        if(is_mul) begin
                            state_q <= S_MUL;
                            cycle_count_q <= 6'd0;
                            if(funct3_i == MULHSU)
                                product_q <= $signed({src_a_i[31], src_a_i}) * $signed({1'b0, src_b_i});
                            else if(funct3_i == MULH)
                                product_q <= $signed(src_a_i) * $signed(src_b_i);
                            else
                                product_q <= src_a_i * src_b_i;
                        end else begin
                            state_q <= S_DIV;
                            cycle_count_q <= 6'd0;
                            src_a_neg_q <= (funct3_i == DIV || funct3_i == REM) && src_a_i[31];
                            src_b_neg_q <= (funct3_i == DIV || funct3_i == REM) && src_b_i[31];
                            if(funct3_i == DIV || funct3_i == REM) begin
                                quotient_q  <= src_a_i[31] ? -src_a_i : src_a_i;
                                divisor_q   <= src_b_i[31] ? -src_b_i : src_b_i;
                            end else begin
                                quotient_q  <= src_a_i;
                                divisor_q   <= src_b_i;
                            end
                            remainder_q <= 32'b0;
                        end
                    end
                end

                S_MUL: begin
                    if(cycle_count_q == 6'd1) begin
                        state_q <= S_IDLE;
                        done_o  <= 1'b1;
                        case(funct3_i)
                            MUL:    result_o <= product_q[31:0];
                            MULH:   result_o <= product_q[63:32];
                            MULHSU: result_o <= product_q[63:32];
                            MULHU:  result_o <= product_q[63:32];
                            default: result_o <= 32'b0;
                        endcase
                    end else
                        cycle_count_q <= cycle_count_q + 1;
                end

                S_DIV: begin
                    if(cycle_count_q == 6'd32) begin
                        state_q <= S_IDLE;
                        done_o  <= 1'b1;
                        case(funct3_i)
                            DIV: begin
                                if(src_b_i == 0)
                                    result_o <= 32'hFFFFFFFF;
                                else if(src_a_i == 32'h80000000 && src_b_i == 32'hFFFFFFFF)
                                    result_o <= 32'h80000000;
                                else
                                    result_o <= (src_a_neg_q != src_b_neg_q) ? -quotient_q : quotient_q;
                            end
                            DIVU: begin
                                if(src_b_i == 0)
                                    result_o <= 32'hFFFFFFFF;
                                else
                                    result_o <= quotient_q;
                            end
                            REM: begin
                                if(src_b_i == 0)
                                    result_o <= src_a_i;
                                else if(src_a_i == 32'h80000000 && src_b_i == 32'hFFFFFFFF)
                                    result_o <= 32'h0;
                                else
                                    result_o <= src_a_neg_q ? -remainder_q : remainder_q;
                            end
                            REMU: begin
                                if(src_b_i == 0)
                                    result_o <= src_a_i;
                                else
                                    result_o <= remainder_q;
                            end
                            default: result_o <= 32'b0;
                        endcase
                    end else begin
                        remainder_q <= {remainder_q[30:0], quotient_q[31]};
                        quotient_q  <= {quotient_q[30:0], 1'b0};
                        if({remainder_q[30:0], quotient_q[31]} >= divisor_q) begin
                            remainder_q <= {remainder_q[30:0], quotient_q[31]} - divisor_q;
                            quotient_q[0] <= 1'b1;
                        end
                        cycle_count_q <= cycle_count_q + 1;
                    end
                end

                default: state_q <= S_IDLE;
            endcase
        end
    end
endmodule
