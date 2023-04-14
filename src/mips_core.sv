
module mips_core(
    inst_addr,
    inst,
    mem_addr,
    mem_data_out,
    mem_data_in,
    mem_write_en,
    halted,
    clk,
    rst_b
);
    input   [31:0] inst;
    input   [7:0]  mem_data_out[0:3];
    input          clk;
    input          rst_b;

    output reg [31:0] inst_addr;
    output reg [31:0] mem_addr;
    output reg [7:0]  mem_data_in[0:3];
    output reg        mem_write_en;
    output reg        halted;

    reg wait_sig;


    wire [31:0] cache_load_data;
    wire [31:0] cache_write_data;
    wire cache_write, cache_read;

	wire [5:0]  opcode;
    wire [5:0]  func;
	wire [4:0]  rs_num;
	wire [4:0]  rt_num;
	wire [4:0]  rd_num;
    wire [4:0]  sh_amount;
    wire [15:0] imm;
    wire [31:0] pc_branch;
    wire [27:0] pc_j;
    wire pc_branch_en;
    wire pc_j_en;
    wire [25:0] address_j_format;
    reg  [31:0] tmp_inst_addr;

    /* verilator lint_off UNOPTFLAT */
    wire signed [31:0] temp_alu_A;
    wire signed [31:0] temp_alu_B;
    wire [3:0] temp_alu_ctl;
    reg [31:0] temp_alu_out;

	assign opcode       = inst[31:26];
	assign func         = inst[5:0];
	assign rs_num       = inst[25:21];
	assign rt_num       = inst[20:16];
	assign rd_num       = inst[15:11];
    assign sh_amount    = inst[10:6];
    assign imm          = inst[15:0];
    assign address_j_format = inst[25:0];


    always @(posedge clk) begin
        // todo: if we are in mem instructions we need to use cache_ready if cahce is ready then change PC
        $display("instruction: %b", inst);
        if(!rst_b) begin
           inst_addr <= 32'b0;
           tmp_inst_addr <= 32'b0;
        end
        else begin
            if(pc_branch_en == 1'b1) begin
                inst_addr <= inst_addr + pc_branch;
                tmp_inst_addr <= inst_addr + pc_branch;
                // $display("in mips BNE pc inst=%b",inst_addr + pc_branch);
            end
            else if(pc_j_en == 1'b1) begin
                inst_addr <= {inst_addr[31:28], pc_j};
                tmp_inst_addr <= {inst_addr[31:28], pc_j};
                // $display("in mips core pc inst=%b",{inst_addr[31:28], pc_j});
            end
            else if (!wait_sig) begin
                  inst_addr <= inst_addr + 32'd4;
                  tmp_inst_addr <= inst_addr + 32'd4;
            end

            // cache
            // todo: change PC if cache is ready?
            //
            // if (cache_ready) begin

            // end
        end
        // $display("clock===== done inst=%b opcode=%b func=%b pc=%b",inst , opcode, func, inst_addr);
    end

    alu alu_ (
        .A(temp_alu_A),
        .B(temp_alu_B),
        .aluctl(temp_alu_ctl),
        .C(temp_alu_out)
    );


    // cache cache_ (
    //     .read(cache_read),
    //     .write(cache_write),
    //     .clk(clk),
    //     .rst(rst_b),
    //     .write_data(cache_write_data),
    //     .load_address(cache_load_address),
    //     .write_address(cache_write_address),
    //     .mem_data_out(mem_data_out),
    //     .load_data(cache_load_data),
    //     .hit(cache_hit),
    //     .ready(cache_ready),
    //     .mem_data_in(mem_data_in),
    //     .mem_write_en(mem_write_en)
    // );

    control_unit control_unit_ (
        .clk(clk),
        .rst_b(rst_b),
        .opcode(opcode),
        .func(func),
        .rs_num(rs_num),
        .rt_num(rt_num),
        .rd_num(rd_num),
        .sh_amount(sh_amount),
        .imm(imm),
        .address_j_format(address_j_format),
        .inst_addr(tmp_inst_addr),
        .pc_branch(pc_branch),
        .pc_j(pc_j),
        .pc_branch_en(pc_branch_en),
        .pc_j_en(pc_j_en),
        // todo: remove this and use cache_mem_data_out: we do this for use cache: ram_data_ready == 1 => this value will be valid
        .mem_data_out(mem_data_out),
        .mem_addr(mem_addr),
        // todo: remove this and use cache_mem_data_in: we do this for use cache and write data from cache to mem
        .mem_data_in(mem_data_in),
        .mem_write_en(mem_write_en),
        .halted_signal(halted),
        .alu_output(temp_alu_out),
        .alu_input_A(temp_alu_A),
        .alu_input_B(temp_alu_B),
        .alu_ctl(temp_alu_ctl),
        .wait_sig(wait_sig)
        // .cache_ready(cache_ready),
        // .cache_write(cache_write),
        // .cache_read(cache_read),
        // .cache_write_data(cache_write_data),
        // .cache_load_data(cache_load_data)
    );
endmodule : mips_core
