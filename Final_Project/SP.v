module SP(
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

//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------

reg [31:0] nPC;

reg  [31:0] IR;
wire [5:0]  op_code = IR[31:26];
wire [4:0]  rs      = IR[25:21];
wire [4:0]  rt      = IR[20:16];
wire [4:0]  rd      = IR[15:11];
wire [4:0]  shamt   = IR[10:6];
wire [5:0]  funct   = IR[5:0];
wire [15:0] imm     = IR[15:0];
wire [25:0] address = IR[25:0];

wire [31:0] zImm = {16'b0, imm};
wire [31:0] sImm = {{16{imm[15]}}, imm};

reg taken;
reg signed [31:0] alu_out;

reg [1:0] curr_state, next_state;
parameter IDLE = 0, EXE = 1, MEM = 2, WB = 3;

// branch taken or not taken
always @(*) begin
	case(op_code)
		6'h07: taken = (r[rs] == r[rt]);
		6'h08: taken = (r[rs] != r[rt]);
		default: taken = 1'b0;
	endcase
end

//------------------------------------------------------------------------
//   FSM
//------------------------------------------------------------------------
always @(*) begin
	case (op_code)
		6'h07, 6'h08: nPC = taken ? (inst_addr + 4 + (sImm << 2)) : (inst_addr + 4);
		6'h0a, 6'h0b: nPC = {inst_addr[31:28], address[25:0], 2'b00};
		6'h00:        nPC = (funct==6'h07) ? r[rs] : (inst_addr + 4);
		default:      nPC = inst_addr + 4;
	endcase
end

// FSM
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		curr_state <= IDLE;
	else
		curr_state <= next_state;
end

always @(*) begin
	case(curr_state)
		IDLE:	next_state = (in_valid) ? EXE : IDLE;
		EXE:	next_state = ((op_code==6'h5) || (op_code==6'h6)) ? MEM : WB;
		MEM:	next_state = WB;
		WB:		next_state = IDLE;
		default:next_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) IR <= 32'd0;
	else if(in_valid) IR <= inst;
	else IR <= IR;
end

always @(*) begin
	mem_wen = 1;
	case(op_code)
		// R-type
		6'h00: begin
			case(funct)
				6'h00:   alu_out = r[rs] & r[rt];           // add
				6'h01:   alu_out = r[rs] | r[rt];           // or
				6'h02:   alu_out = r[rs] + r[rt];           // add
				6'h03:   alu_out = r[rs] - r[rt];           // sub
				6'h04:   alu_out = (r[rs] < r[rt]) ? 1 : 0; // slt
				6'h05:   alu_out = r[rs] << shamt;          // sll
				6'h06:   alu_out = ~(r[rs] | r[rt]);        // nor
				default: alu_out = 0;
			endcase
		end

		// I-type
		6'h01:   alu_out = r[rs] & zImm; // andi
		6'h02:   alu_out = r[rs] | zImm; // ori
		6'h03:   alu_out = r[rs] + sImm; // addi
		6'h04:   alu_out = r[rs] - sImm; // subi
		6'h05: begin
				 alu_out = r[rs] + sImm; // lw
				 mem_wen=1'b1;
				 mem_addr=alu_out;
		end
		6'h06: begin
				 alu_out = r[rs] + sImm; // sw
				 mem_wen=1'b0;
				 mem_addr=alu_out;
				 mem_din = r[rt];
		end
		// 6'h07: alu_out = 32'd0; // beq -> other always block to exe
		// 6'h08: alu_out = 32'd0; // bne -> other always block to exe
		6'h09:   alu_out = {imm, 16'b0};
		// 6'h0b    : alu_out = inst_addr + 4;
		default: alu_out = 0;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)        IR <= 0;
	else if (in_valid) IR <= inst;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		curr_state <= IDLE;
		inst_addr  <= 0;
		out_valid  <= 0;
		for(integer i=0; i<32; i=i+1) r[i] <= 0;
	end
	else if (curr_state==WB) begin
		out_valid <= 1;
		inst_addr <= nPC;
		case(op_code)
			6'h00: r[rd] <= (funct != 6'h07) ? alu_out : r[rd];
			6'h01, 6'h02, 6'h03, 6'h04, 6'h09: r[rt] <= alu_out;
			6'h05: r[rt] <= mem_dout;
			6'h0b: r[31] <= inst_addr + 4;
		endcase
	end
	else out_valid <= 0;
end

endmodule