module SP_pipeline(
    // INPUT SIGNAL
	clk,
	rst_n,
	in_valid,
	inst,
	mem_dout,
	// OUTPUT SIGNAL
	out_valid,
	inst_addr,
	mem_wen,
	mem_addr,
	mem_din
);

//------------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//------------------------------------------------------------------------

input                    clk, rst_n, in_valid;
input             [31:0] inst;
input  signed     [31:0] mem_dout;
output reg               out_valid;
output reg        [31:0] inst_addr;
output reg               mem_wen;
output reg        [11:0] mem_addr;
output reg signed [31:0] mem_din;
 
//------------------------------------------------------------------------
//   DECLARATION
//------------------------------------------------------------------------
// REGISTER FILE, DO NOT EDIT THE NAME.
reg	signed [31:0] r [0:31]; 

reg in_valid_ID, in_valid_EX, in_valid_WB;
reg [31:0] inst_ID, inst_EX, inst_WB;
reg [31:0] PC_ID, PC_EX, PC_WB;

// IF
reg [31:0] PC_comb, PC_reg;

// ID
reg signed [31:0] r1_comb, r1_reg, r2_comb, r2_reg;

// EX
reg signed [31:0] result_comb, result_reg;

// WB
reg	signed [31:0] r_comb [0:31]; 

//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------
always @(posedge clk) begin
    PC_ID <= PC_reg;
    PC_EX <= PC_ID;
    PC_WB <= PC_EX;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin   
        in_valid_ID <= 0;
        in_valid_EX <= 0;
        in_valid_WB <= 0;
        inst_ID <= 0;
        inst_EX <= 0;
        inst_WB <= 0;
        for(integer i=0;i<32;i=i+1) r[i] <= 0;
    end
    else begin
        in_valid_ID <= in_valid;
        in_valid_EX <= in_valid_ID;
        in_valid_WB <= in_valid_EX;
        inst_ID <= inst;
        inst_EX <= inst_ID;
        inst_WB <= inst_EX;
        for(integer i=0; i<32; i=i+1) r[i] <= r_comb[i];
    end
end
//------------------------------------------------------------------------
//   IF/ID
//------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) PC_reg <= 0;
    else        PC_reg <= PC_comb;
end

always @(*) begin
    if (in_valid) begin
        PC_comb = PC_reg +4;
        case(inst[31:26])
            6'h00 : PC_comb = (inst[5:0]==6'h07) ? r[inst[25:21]] : PC_reg +4;
            6'h07 : PC_comb = (r[inst[25:21]]==r[inst[20:16]]) ? PC_reg + 4 +{{14{inst[15]}}, inst[15:0], 2'b00} : PC_reg + 4;
            6'h08 : PC_comb = (r[inst[25:21]]!=r[inst[20:16]]) ? PC_reg + 4 +{{14{inst[15]}}, inst[15:0], 2'b00} : PC_reg +4;
            6'h0a : PC_comb = {inst_addr[31:28], inst[25:0], 2'b00}; 
            6'h0b : PC_comb = {inst_addr[31:28], inst[25:0], 2'b00}; 
        endcase
    end
    else begin
        PC_comb = PC_reg;
    end
end

//------------------------------------------------------------------------
//   ID/EX
//------------------------------------------------------------------------
always @(posedge clk) begin
    r1_reg <= r1_comb;
    r2_reg <= r2_comb;
end

always @(*) begin
    r1_comb = r1_reg;
    r2_comb = r2_reg;
    if (in_valid_ID) begin
        r1_comb = r[inst_ID[25:21]];
	    r2_comb = r[inst_ID[20:16]];
    end
end

//------------------------------------------------------------------------
//   EX/MEM
//------------------------------------------------------------------------
always @(posedge clk) begin
    result_reg <= result_comb;
end

always @(*) begin
    result_comb = 0;
    mem_addr = 0;
    mem_wen = 1;
    mem_din = 0;
    if (in_valid_EX) begin
        case(inst_EX[31:26])
            // R-type
            6'h00 : begin
                case (inst_EX[5:0])
                    6'h00: result_comb = r1_reg & r2_reg;           // and
                    6'h01: result_comb = r1_reg | r2_reg;           // or
                    6'h02: result_comb = r1_reg + r2_reg;           // add
                    6'h03: result_comb = r1_reg - r2_reg;           // sub
                    6'h04: result_comb = (r1_reg < r2_reg) ? 1 : 0; // slt
                    6'h05: result_comb = r1_reg << inst_EX[10:6];   // sll
                    6'h06: result_comb = ~(r1_reg | r2_reg);        // nor
                endcase
            end
            // I-type
            6'h01: result_comb = r1_reg & {16'b0, inst_EX[15:0]};             // andi
            6'h02: result_comb = r1_reg | {16'b0, inst_EX[15:0]};             // ori
            6'h03: result_comb = r1_reg + {{16{inst_EX[15]}}, inst_EX[15:0]}; // addi
            6'h04: result_comb = r1_reg - {{16{inst_EX[15]}}, inst_EX[15:0]}; // subi
            6'h05: begin
                   result_comb = r1_reg + {{16{inst_EX[15]}}, inst_EX[15:0]}; // lw
                   mem_addr=result_comb;
                   mem_wen = 1'b1;
            end
            6'h06: begin
                   result_comb = r1_reg + {{16{inst_EX[15]}}, inst_EX[15:0]}; // sw
                   mem_addr=result_comb;
                   mem_wen = 1'b0;
                   mem_din = r2_reg;
            end
            6'h09: result_comb = {inst_EX[15:0], 16'b0};                      // lui
        endcase
    end
end

//------------------------------------------------------------------------
//   MEM/WB
//------------------------------------------------------------------------
always @(*) begin
    for(integer i=0; i<32; i=i+1) r_comb[i] = r[i];
    if (in_valid_WB) begin
        case(inst_WB[31:26])
            6'h00: r_comb[inst_WB[15:11]] = (inst_WB[5:0]!=6'h07) ? result_reg : r[inst_WB[15:11]];
            6'h01, 6'h02, 6'h03, 6'h04, 6'h09: r_comb[inst_WB[20:16]] = result_reg;
            6'h05: r_comb[inst_WB[20:16]] = mem_dout; 
            6'h0b: r_comb[31] = PC_WB + 4;
        endcase
    end
end

//------------------------------------------------------------------------
//   OUTPUT
//------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inst_addr <= 0;
		out_valid <= 0;
    end
    else begin
        inst_addr <= PC_comb; 
		out_valid <= in_valid_WB;
    end
end

endmodule